import AppKit

final class MenuController: NSObject {
    let menu = NSMenu()

    private let toggleItem = NSMenuItem(title: "Enabled", action: nil, keyEquivalent: "")
    private let cursor: CursorController
    private weak var statusItem: NSStatusItem?

    private static let enabledKey = "MacMouseImprover.enabled"

    init(cursor: CursorController, statusItem: NSStatusItem) {
        self.cursor = cursor
        self.statusItem = statusItem
        super.init()

        toggleItem.target = self
        toggleItem.action = #selector(toggle(_:))
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(title: "About Mac Mouse Improver", action: #selector(about(_:)), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let githubItem = NSMenuItem(title: "View on GitHub", action: #selector(openGitHub(_:)), keyEquivalent: "")
        githubItem.target = self
        menu.addItem(githubItem)

        menu.addItem(NSMenuItem.separator())

        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        launchAtLoginItem.target = self
        if #available(macOS 13.0, *) {
            launchAtLoginItem.state = LaunchAtLogin.isEnabled ? .on : .off
        } else {
            launchAtLoginItem.isEnabled = false
            launchAtLoginItem.toolTip = "Requires macOS 13 or later"
        }
        menu.addItem(launchAtLoginItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
    }

    func setEnabled(_ enabled: Bool) {
        toggleItem.state = enabled ? .on : .off
        statusItem?.button?.alphaValue = enabled ? 1.0 : 0.4
        if enabled {
            cursor.enable()
        } else {
            cursor.disable()
        }
        UserDefaults.standard.set(enabled, forKey: Self.enabledKey)
    }

    @objc private func toggle(_ sender: NSMenuItem) {
        setEnabled(sender.state != .on)
    }

    @objc private func about(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.messageText = "Mac Mouse Improver"
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        alert.informativeText = """
        Version \(version)

        A clean, minimal cursor for macOS.
        Open source — MIT licensed.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func openGitHub(_ sender: NSMenuItem) {
        if let url = URL(string: "https://github.com/HugoRS00/mac-mouse-improver") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        guard #available(macOS 13.0, *) else { return }
        let newState = !LaunchAtLogin.isEnabled
        LaunchAtLogin.isEnabled = newState
        sender.state = LaunchAtLogin.isEnabled ? .on : .off
    }
}
