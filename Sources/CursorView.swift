import AppKit
import QuartzCore

final class CursorView: NSView {
    private let cursorLayer = CALayer()
    private let cursorSize: CGSize
    private let hotspot: CGPoint

    init(backingScale: CGFloat) {
        self.cursorSize = CursorRenderer.size
        self.hotspot = CursorRenderer.hotspot
        super.init(frame: .zero)
        wantsLayer = true
        layer = CALayer()

        let cgImage = CursorRenderer.makeCursorCGImage(scale: max(2, backingScale))
        cursorLayer.contents = cgImage
        cursorLayer.bounds = CGRect(origin: .zero, size: cursorSize)
        cursorLayer.contentsScale = max(2, backingScale)
        // Anchor at hotspot. The image is drawn with y-down, but the layer's
        // coordinate system in a non-flipped NSView has y up — so the
        // anchor's y component is mirrored (1 - hotspot.y / size.height).
        cursorLayer.anchorPoint = CGPoint(
            x: hotspot.x / cursorSize.width,
            y: 1.0 - hotspot.y / cursorSize.height
        )
        cursorLayer.allowsEdgeAntialiasing = true
        cursorLayer.shouldRasterize = true
        cursorLayer.rasterizationScale = max(2, backingScale)
        cursorLayer.isHidden = true
        layer?.addSublayer(cursorLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override var isFlipped: Bool { false }

    func setCursorVisible(_ visible: Bool) {
        if cursorLayer.isHidden != !visible {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            cursorLayer.isHidden = !visible
            CATransaction.commit()
        }
    }

    func updateCursor(localPosition: NSPoint, eventType: NSEvent.EventType?) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        cursorLayer.position = localPosition
        CATransaction.commit()

        guard let eventType = eventType else { return }
        switch eventType {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            playPress()
        case .leftMouseUp, .rightMouseUp, .otherMouseUp:
            playRelease()
        default:
            break
        }
    }

    private static let pressedScale: CGFloat = 0.78

    private func playPress() {
        cursorLayer.removeAnimation(forKey: "release")
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.fromValue = 1.0
        anim.toValue = Self.pressedScale
        anim.duration = 0.08
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        anim.fillMode = .forwards
        anim.isRemovedOnCompletion = false
        cursorLayer.add(anim, forKey: "press")
        cursorLayer.setValue(Self.pressedScale, forKeyPath: "transform.scale")
    }

    private func playRelease() {
        cursorLayer.removeAnimation(forKey: "press")
        let spring = CASpringAnimation(keyPath: "transform.scale")
        spring.fromValue = Self.pressedScale
        spring.toValue = 1.0
        spring.damping = 9
        spring.stiffness = 220
        spring.mass = 0.55
        spring.initialVelocity = 0
        spring.duration = spring.settlingDuration
        spring.fillMode = .forwards
        spring.isRemovedOnCompletion = false
        cursorLayer.add(spring, forKey: "release")
        cursorLayer.setValue(1.0, forKeyPath: "transform.scale")
    }
}
