import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menuController: MenuController!
    private let cursor = CursorController()
    private let updateChecker = UpdateChecker()
    private var updateTimer: Timer?

    private static let enabledKey = "MacMouseImprover.enabled"

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "cursorarrow", accessibilityDescription: "Mac Mouse Improver")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
        }

        menuController = MenuController(cursor: cursor, statusItem: statusItem)
        statusItem.menu = menuController.menu

        if UserDefaults.standard.object(forKey: Self.enabledKey) == nil {
            UserDefaults.standard.set(true, forKey: Self.enabledKey)
        }
        menuController.setEnabled(UserDefaults.standard.bool(forKey: Self.enabledKey))

        updateChecker.menuController = menuController
        updateChecker.checkIfDue()
        // Re-check every six hours while the app is running, which is plenty
        // for an app the user keeps around for weeks.
        updateTimer = Timer.scheduledTimer(withTimeInterval: 6 * 60 * 60, repeats: true) { [weak self] _ in
            self?.updateChecker.checkIfDue()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        updateTimer?.invalidate()
        cursor.disable()
    }
}
