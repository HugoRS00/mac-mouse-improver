import AppKit

final class CursorOverlayWindow: NSWindow {
    private let cursorView: CursorView
    private let screenFrame: NSRect

    init(screen: NSScreen) {
        self.screenFrame = screen.frame
        self.cursorView = CursorView(backingScale: screen.backingScaleFactor)
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()) - 1)
        self.ignoresMouseEvents = true
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]
        self.isMovable = false
        self.isReleasedWhenClosed = false
        self.contentView = cursorView
        self.setFrame(screen.frame, display: true)
        cursorView.frame = NSRect(origin: .zero, size: screen.frame.size)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func updateCursor(globalPosition: NSPoint, eventType: NSEvent.EventType?) {
        let onThisScreen = screenFrame.contains(globalPosition)
        cursorView.setCursorVisible(onThisScreen)
        guard onThisScreen else { return }
        let local = NSPoint(
            x: globalPosition.x - screenFrame.origin.x,
            y: globalPosition.y - screenFrame.origin.y
        )
        cursorView.updateCursor(localPosition: local, eventType: eventType)
    }
}
