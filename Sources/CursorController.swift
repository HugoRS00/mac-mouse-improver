import AppKit

final class CursorController {
    private var overlayWindows: [CursorOverlayWindow] = []
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isEnabled = false

    func enable() {
        guard !isEnabled else { return }
        isEnabled = true

        rebuildOverlays()
        startMonitoring()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func disable() {
        guard isEnabled else { return }
        isEnabled = false

        stopMonitoring()
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()

        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenChanged() {
        guard isEnabled else { return }
        rebuildOverlays()
    }

    private func rebuildOverlays() {
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
        for screen in NSScreen.screens {
            let window = CursorOverlayWindow(screen: screen)
            window.orderFrontRegardless()
            overlayWindows.append(window)
        }
        broadcast(position: NSEvent.mouseLocation, eventType: nil)
    }

    private func startMonitoring() {
        let mask: NSEvent.EventTypeMask = [
            .mouseMoved, .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp,
            .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
            .otherMouseDown, .otherMouseUp
        ]

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    private func stopMonitoring() {
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
    }

    private func handle(_ event: NSEvent) {
        broadcast(position: NSEvent.mouseLocation, eventType: event.type)
    }

    private func broadcast(position: NSPoint, eventType: NSEvent.EventType?) {
        for window in overlayWindows {
            window.updateCursor(globalPosition: position, eventType: eventType)
        }
    }
}
