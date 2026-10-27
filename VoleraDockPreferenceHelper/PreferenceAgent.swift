import AppKit
import CoreFoundation
import Foundation

@MainActor
final class PreferenceAgent: NSObject, NSApplicationDelegate {
    private let dockDomain = "com.apple.dock"
    private let preferenceKeys = ["autohide", "autohide-delay", "autohide-time-modifier"]
    private let appliedValues: [String: Any] = [
        "autohide": NSNumber(value: true),
        "autohide-delay": NSNumber(value: 60.0)
    ]
    private let beginName = Notification.Name("dev.volera.dock.preferences.begin")
    private let endName = Notification.Name("dev.volera.dock.preferences.end")
    private let pingName = Notification.Name("dev.volera.dock.preferences.ping")
    private let responseName = Notification.Name("dev.volera.dock.preferences.response")
    private let ownerBundleIdentifier = "dev.volera.dock"
    private var notificationTokens: [NSObjectProtocol] = []
    private var terminationToken: NSObjectProtocol?
    private let journalURL: URL

    override init() {
        let supportDirectory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Volera Dock", isDirectory: true)
        journalURL = supportDirectory.appendingPathComponent("native-dock-session.plist")
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        observeCommands()
        terminationToken = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let processIdentifier = application?.processIdentifier
            let bundleIdentifier = application?.bundleIdentifier
            MainActor.assumeIsolated {
                self?.applicationTerminated(
                    processIdentifier: processIdentifier,
                    bundleIdentifier: bundleIdentifier
                )
            }
        }
        recoverOrResumeExistingSession()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func observeCommands() {
        let center = DistributedNotificationCenter.default()
        for name in [beginName, endName, pingName] {
            let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                let commandName = notification.name.rawValue
                let userInfo = notification.userInfo ?? [:]
                let requestID = userInfo["requestID"] as? String
                let ownerPID = userInfo["ownerPID"] as? Int
                MainActor.assumeIsolated {
                    self?.handleCommand(
                        name: commandName,
                        requestID: requestID,
                        ownerPID: ownerPID
                    )
                }
            }
            notificationTokens.append(token)
        }
    }

    private func handleCommand(name: String, requestID: String?, ownerPID: Int?) {
        guard let requestID else {
            return
        }

        do {
            if name == pingName.rawValue {
                postResponse(requestID: requestID, command: "ready", success: true)
                return
            } else if name == beginName.rawValue {
                guard let ownerPID,
                      isVoleraRunning(processIdentifier: pid_t(ownerPID)) else {
                    throw AgentError.ownerUnavailable
                }
                try beginSession(ownerPID: ownerPID)
                postResponse(requestID: requestID, command: "begin", success: true)
            } else {
                try endSession(ownerPID: ownerPID)
                postResponse(requestID: requestID, command: "end", success: true)
            }
        } catch {
            postResponse(
                requestID: requestID,
                command: name == beginName.rawValue ? "begin" : "end",
                success: false,
                message: error.localizedDescription
            )
        }
    }

    private func beginSession(ownerPID: Int) throws {
        if let journal = try readJournal() {
            let existingPID = journal["ownerPID"] as? Int
            if existingPID == ownerPID {
                try ensureAppliedSettings()
                return
            }
            if let existingPID, isVoleraRunning(processIdentifier: pid_t(existingPID)) {
                throw AgentError.sessionAlreadyOwned
            }
            try restoreSession()
        }

        let currentPreferences = try readCurrentDockPreferences()
        var originals: [String: Any] = [:]
        for key in preferenceKeys {
            if let value = currentPreferences[key] {
                originals[key] = ["present": true, "value": value]
            } else {
                originals[key] = ["present": false]
            }
        }

        let journal: [String: Any] = [
            "ownerPID": ownerPID,
            "originals": originals,
            "applied": appliedValues
        ]
        try writeJournal(journal)

        do {
            try ensureAppliedSettings()
        } catch {
            do {
                try restoreSession()
            } catch {
                throw AgentError.applyAndRestoreFailed(error.localizedDescription)
            }
            throw error
        }
    }

    private func ensureAppliedSettings() throws {
        guard try readJournal() != nil else {
            throw AgentError.journalMissing
        }

        var currentPreferences = try readCurrentDockPreferences()
        var changed = false
        for (key, value) in appliedValues {
            guard !preferencesEqual(currentPreferences[key], value) else { continue }
            try writePreference(key, value: value)
            currentPreferences[key] = value
            changed = true
        }
        if changed { currentPreferences = try readCurrentDockPreferences() }
        for (key, expected) in appliedValues {
            guard preferencesEqual(currentPreferences[key], expected) else {
                throw AgentError.preferenceVerificationFailed(key)
            }
        }
        if changed {
            try refreshDock()
        }
    }

    private func endSession(ownerPID: Int?) throws {
        guard let journal = try readJournal() else { return }
        guard let ownerPID,
              journal["ownerPID"] as? Int == ownerPID,
              isVoleraRunning(processIdentifier: pid_t(ownerPID)) else {
            throw AgentError.ownerUnavailable
        }
        try restoreSession()
    }

    private func restoreSession() throws {
        guard let journal = try readJournal() else { return }
        guard let originals = journal["originals"] as? [String: [String: Any]],
              let applied = journal["applied"] as? [String: Any] else {
            throw AgentError.invalidJournal
        }
        let currentPreferences = try readCurrentDockPreferences()
        var restoredKeys: [String] = []
        for (key, expected) in applied {
            guard preferencesEqual(currentPreferences[key], expected),
                  let original = originals[key],
                  let wasPresent = original["present"] as? Bool else {
                continue
            }
            let originalValue = wasPresent ? original["value"] : nil
            guard !preferencesEqual(currentPreferences[key], originalValue) else {
                continue
            }
            try writePreference(key, value: originalValue)
            restoredKeys.append(key)
        }

        if !restoredKeys.isEmpty {
            let restoredPreferences = try readCurrentDockPreferences()
            for key in restoredKeys {
                guard let original = originals[key],
                      let wasPresent = original["present"] as? Bool,
                      preferencesEqual(
                        restoredPreferences[key],
                        wasPresent ? original["value"] : nil
                      ) else {
                    throw AgentError.restorationVerificationFailed(key)
                }
            }
            try refreshDock()
        }
        try FileManager.default.removeItem(at: journalURL)
    }

    private func recoverOrResumeExistingSession() {
        do {
            guard let journal = try readJournal(),
                  let ownerPID = journal["ownerPID"] as? Int else {
                return
            }
            if isVoleraRunning(processIdentifier: pid_t(ownerPID)) {
                try ensureAppliedSettings()
            } else {
                try restoreSession()
            }
        } catch {
            writeError(error.localizedDescription)
        }
    }

    private func applicationTerminated(processIdentifier: pid_t?, bundleIdentifier: String?) {
        guard let processIdentifier, bundleIdentifier == ownerBundleIdentifier else {
            return
        }
        do {
            guard let journal = try readJournal(),
                  journal["ownerPID"] as? Int == Int(processIdentifier) else {
                return
            }
            try restoreSession()
            postResponse(requestID: "", command: "recovered", success: true)
        } catch {
            postResponse(
                requestID: "",
                command: "recovered",
                success: false,
                message: error.localizedDescription
            )
        }
    }

    private func readCurrentDockPreferences() throws -> [String: Any] {
        let data = try runDefaults(["export", dockDomain, "-"])
        guard let preferences = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw AgentError.invalidPreferences
        }
        return preferences
    }

    private func writePreference(_ key: String, value: Any?) throws {
        guard let value else {
            _ = try runDefaults(["delete", dockDomain, key])
            return
        }

        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                _ = try runDefaults([
                    "write", dockDomain, key, "-bool", number.boolValue ? "true" : "false"
                ])
            } else {
                let numberOption = CFNumberIsFloatType(number) ? "-float" : "-int"
                _ = try runDefaults(["write", dockDomain, key, numberOption, number.stringValue])
            }
        } else if let string = value as? String {
            _ = try runDefaults(["write", dockDomain, key, "-string", string])
        } else {
            throw AgentError.invalidPreferenceType(key)
        }
    }

    private func runDefaults(_ arguments: [String]) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            throw AgentError.preferenceCommandFailed(error.localizedDescription)
        }
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw AgentError.preferenceCommandFailed(
                "The defaults command exited with status \(process.terminationStatus)."
            )
        }
        return data
    }

    private func preferencesEqual(_ first: Any?, _ second: Any?) -> Bool {
        switch (first, second) {
        case (nil, nil):
            true
        case let (first?, second?):
            CFEqual(first as CFTypeRef, second as CFTypeRef)
        default:
            false
        }
    }

    private func isVoleraRunning(processIdentifier: pid_t) -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.processIdentifier == processIdentifier &&
                $0.bundleIdentifier == ownerBundleIdentifier
        }
    }

    private func readJournal() throws -> [String: Any]? {
        guard FileManager.default.fileExists(atPath: journalURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: journalURL)
        guard let journal = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw AgentError.invalidJournal
        }
        return journal
    }

    private func writeJournal(_ journal: [String: Any]) throws {
        let directory = journalURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let data = try PropertyListSerialization.data(
            fromPropertyList: journal,
            format: .binary,
            options: 0
        )
        try data.write(to: journalURL, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: journalURL.path
        )
    }

    private func refreshDock() throws {
        guard let dock = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.dock"
        ).first else {
            throw AgentError.dockNotRunning
        }
        guard dock.forceTerminate() else {
            throw AgentError.dockRefreshFailed
        }
    }

    private func postResponse(
        requestID: String,
        command: String,
        success: Bool,
        message: String? = nil
    ) {
        var userInfo: [String: Any] = [
            "requestID": requestID,
            "command": command,
            "success": success
        ]
        if let message {
            userInfo["message"] = message
        }
        DistributedNotificationCenter.default().postNotificationName(
            responseName,
            object: nil,
            userInfo: userInfo,
            deliverImmediately: true
        )
    }

    private func writeError(_ message: String) {
        FileHandle.standardError.write(Data("Volera Dock preference recovery failed: \(message)\n".utf8))
    }
}

private enum AgentError: LocalizedError {
    case ownerUnavailable
    case sessionAlreadyOwned
    case journalMissing
    case invalidJournal
    case invalidPreferences
    case invalidPreferenceType(String)
    case preferenceCommandFailed(String)
    case preferenceWriteFailed
    case preferenceVerificationFailed(String)
    case restorationVerificationFailed(String)
    case applyAndRestoreFailed(String)
    case dockNotRunning
    case dockRefreshFailed

    var errorDescription: String? {
        switch self {
        case .ownerUnavailable:
            "Volera Dock is no longer running, so the preference session was not started."
        case .sessionAlreadyOwned:
            "A different Volera Dock session is already managing the native Dock."
        case .journalMissing:
            "The native Dock recovery record could not be found."
        case .invalidJournal:
            "The native Dock recovery record is invalid and was retained for recovery."
        case .invalidPreferences:
            "macOS returned an invalid native Dock preference list."
        case .invalidPreferenceType(let key):
            "The original \(key) preference has an unsupported value type and was not changed."
        case .preferenceCommandFailed(let message):
            "macOS could not update the native Dock preferences: \(message)"
        case .preferenceWriteFailed:
            "macOS did not save the native Dock preferences."
        case .preferenceVerificationFailed(let key):
            "macOS did not retain the requested \(key) preference."
        case .restorationVerificationFailed(let key):
            "macOS did not restore the original \(key) preference."
        case .applyAndRestoreFailed(let message):
            "Applying Dock preferences failed, and rollback also failed: \(message)"
        case .dockNotRunning:
            "The native Dock process could not be found to apply the preference change."
        case .dockRefreshFailed:
            "macOS refused to restart the Dock to apply its preference change."
        }
    }
}

@main
@MainActor
enum PreferenceAgentMain {
    static func main() {
        let application = NSApplication.shared
        let delegate = PreferenceAgent()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}
