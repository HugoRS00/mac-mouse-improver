import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menuController: MenuController!
    private let cursor = CursorController()

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
    }

    func applicationWillTerminate(_ notification: Notification) {
        cursor.disable()
    }
}
