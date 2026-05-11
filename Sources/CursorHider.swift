import AppKit
import Foundation

/// Hides the system cursor system-wide from this background/menu-bar app.
///
/// `NSCursor.hide()` and `CGDisplayHideCursor()` only take effect for the
/// process that owns the WindowServer cursor connection — i.e. the
/// foreground app. Menu-bar apps run with `LSUIElement = true` and never
/// become foreground, so a plain `NSCursor.hide()` is a no-op for us.
///
/// The CGS connection property `SetsCursorInBackground` opts our
/// connection out of that restriction. It's a private CoreGraphics API
/// but has been stable since macOS 10.6 and is used by basically every
/// menu-bar app that has to touch the cursor (Dropzone, Bartender,
/// Cursor Pro, Mos, etc).
///
/// We resolve the two needed symbols dynamically via `dlsym` so the app
/// degrades gracefully (system cursor remains visible) rather than
/// failing to launch if Apple ever removes them.
enum CursorHider {
    private static var hidden = false
    private static var didEnableBackgroundControl = false

    static func hide() {
        guard !hidden else { return }
        ensureBackgroundControlEnabled()
        NSCursor.hide()
        hidden = true
    }

    static func show() {
        guard hidden else { return }
        NSCursor.unhide()
        hidden = false
    }

    private static func ensureBackgroundControlEnabled() {
        guard !didEnableBackgroundControl else { return }
        didEnableBackgroundControl = true

        guard
            let mainConnFn = CGS.mainConnectionID,
            let setPropFn = CGS.setConnectionProperty
        else { return }

        let cid = mainConnFn()
        _ = setPropFn(cid, cid, "SetsCursorInBackground" as CFString, kCFBooleanTrue)
    }
}

// MARK: - Dynamic lookup of CoreGraphics private symbols

private enum CGS {
    typealias MainConnFn = @convention(c) () -> Int32
    typealias SetPropFn = @convention(c) (Int32, Int32, CFString, CFTypeRef) -> Int32

    private static let rtldDefault = UnsafeMutableRawPointer(bitPattern: -2)

    static let mainConnectionID: MainConnFn? = {
        guard let sym = dlsym(rtldDefault, "CGSMainConnectionID") else { return nil }
        return unsafeBitCast(sym, to: MainConnFn.self)
    }()

    static let setConnectionProperty: SetPropFn? = {
        guard let sym = dlsym(rtldDefault, "CGSSetConnectionProperty") else { return nil }
        return unsafeBitCast(sym, to: SetPropFn.self)
    }()
}
