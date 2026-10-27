# Volera Dock

Volera Dock is a native macOS floating dock with customizable app shortcuts, appearance, size, and placement. The main app remains App Sandbox–enabled.

## Native Dock auto-hide

To keep the macOS Dock hidden while other applications are active, press **Option-Command-D (⌥⌘D)** before starting a Volera session. This is macOS's own Dock auto-hide shortcut. Volera asks for confirmation, then shows its custom dock and requests AppKit's `.autoHideDock` presentation option while Volera is active. It does not write Dock preferences, install or register a helper, or change the user's setting. Press **⌥⌘D** again when you want to restore the prior Dock behavior.

The manual Dock setting is system-wide for the logged-in user and may apply on other desktops. Volera cannot scope it to a Space or control the Dock while another application is active through AppKit presentation options.

The former Dock preference helper source remains in the project for reference, but it is not embedded in or required by the VoleraDock app scheme.

## Build

Open `VoleraDock.xcodeproj` in Xcode and build the **VoleraDock** scheme, or run:

```sh
xcodebuild -project VoleraDock.xcodeproj -scheme VoleraDock -configuration Debug build
```
