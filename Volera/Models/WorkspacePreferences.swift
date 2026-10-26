import Foundation

struct WorkspacePreferences: Codable, Equatable {
    var background: WorkspaceBackground
    var accent: CodableColor
    var showClock: Bool
    var showDate: Bool
    var shortcuts: [AppShortcut]

    static let `default` = WorkspacePreferences(
        background: .default,
        accent: .icyBlue,
        showClock: true,
        showDate: true,
        shortcuts: []
    )

    enum CodingKeys: String, CodingKey {
        case background
        case backgroundTheme
        case accent
        case showClock
        case showDate
        case shortcuts
    }

    init(
        background: WorkspaceBackground,
        accent: CodableColor,
        showClock: Bool,
        showDate: Bool,
        shortcuts: [AppShortcut]
    ) {
        self.background = background
        self.accent = accent
        self.showClock = showClock
        self.showDate = showDate
        self.shortcuts = shortcuts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let background = try container.decodeIfPresent(WorkspaceBackground.self, forKey: .background) {
            self.background = background
        } else if let theme = try container.decodeIfPresent(BackgroundTheme.self, forKey: .backgroundTheme) {
            self.background = WorkspaceBackground(preset: theme)
        } else {
            self.background = .default
        }
        self.accent = try container.decodeIfPresent(CodableColor.self, forKey: .accent) ?? .icyBlue
        self.showClock = try container.decodeIfPresent(Bool.self, forKey: .showClock) ?? true
        self.showDate = try container.decodeIfPresent(Bool.self, forKey: .showDate) ?? true
        self.shortcuts = try container.decodeIfPresent([AppShortcut].self, forKey: .shortcuts) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(background, forKey: .background)
        try container.encode(accent, forKey: .accent)
        try container.encode(showClock, forKey: .showClock)
        try container.encode(showDate, forKey: .showDate)
        try container.encode(shortcuts, forKey: .shortcuts)
    }
}

enum AppDestination: String, Hashable, CaseIterable, Identifiable {
    case workspace
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .workspace: "Workspace"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .workspace: "square.grid.2x2"
        case .settings: "slider.horizontal.3"
        }
    }
}
