import AppKit
import CoreGraphics

enum CursorRenderer {
    /// Canvas size in points. Sized to sit closely over the system cursor
    /// with a couple of pixels of padding around the silhouette so the
    /// soft drop shadow has room to fade out.
    static let size = CGSize(width: 22, height: 28)

    /// Hotspot in image coordinates (origin top-left, y down). Sits at the
    /// tip of the arrow so the click point matches what the user sees.
    static let hotspot = CGPoint(x: 4, y: 4)

    /// Renders the cursor into a CGImage at the given screen scale.
    static func makeCursorCGImage(scale: CGFloat) -> CGImage {
        let pixelWidth = Int(size.width * scale)
        let pixelHeight = Int(size.height * scale)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let ctx = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return blankImage(width: pixelWidth, height: pixelHeight)
        }

        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.interpolationQuality = .high
        ctx.scaleBy(x: scale, y: scale)
        // Flip to image coordinates (origin top-left, y down) so the geometry
        // below reads naturally.
        ctx.translateBy(x: 0, y: size.height)
        ctx.scaleBy(x: 1, y: -1)

        let path = arrowPath()

        // Soft drop shadow.
        ctx.saveGState()
        let shadowColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.42)
        ctx.setShadow(offset: CGSize(width: 0, height: 1.5), blur: 2.6, color: shadowColor)
        ctx.addPath(path)
        ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))
        ctx.fillPath()
        ctx.restoreGState()

        // White outline.
        ctx.addPath(path)
        ctx.setLineWidth(1.8)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
        ctx.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
        ctx.strokePath()

        // Black fill on top.
        ctx.addPath(path)
        ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))
        ctx.fillPath()

        return ctx.makeImage() ?? blankImage(width: pixelWidth, height: pixelHeight)
    }

    /// The cursor silhouette: a heavily curved teardrop with a soft tail
    /// indentation. Built from four cubic Bézier segments so every part of
    /// the boundary is smoothly curved — no sharp corners anywhere except
    /// the very tip.
    ///
    /// Coordinates are in image space (y down) with the hotspot at (4, 4) —
    /// the tip. Tracing clockwise from the tip:
    ///   tip → left flank → tail belly → right flank → back to tip.
    private static func arrowPath() -> CGPath {
        let path = CGMutablePath()

        let tip          = CGPoint(x: 4,  y: 4)
        let leftBottom   = CGPoint(x: 7,  y: 22)   // where the left flank meets the tail belly
        let tailEnd      = CGPoint(x: 14, y: 24)   // the soft tip of the tail
        let rightTop     = CGPoint(x: 16, y: 14)   // top of the right flank

        // Tip → left bottom. Left flank bows slightly outward (smaller x)
        // before sweeping in to the bottom of the body.
        path.move(to: tip)
        path.addCurve(
            to: leftBottom,
            control1: CGPoint(x: 2.4, y: 12),
            control2: CGPoint(x: 4,   y: 21)
        )

        // Left bottom → tail end. A short, rounded "belly" that gives the
        // cursor its tail. Control points sit below the belly so the curve
        // bulges downward instead of crossing through it.
        path.addCurve(
            to: tailEnd,
            control1: CGPoint(x: 9.5, y: 25),
            control2: CGPoint(x: 12,  y: 26)
        )

        // Tail end → right top. The outer-right of the body sweeps up.
        // Control points pulled outward so the right flank bows.
        path.addCurve(
            to: rightTop,
            control1: CGPoint(x: 16.5, y: 22),
            control2: CGPoint(x: 17.5, y: 18)
        )

        // Right top → tip. The closing diagonal, lightly curved so the head
        // looks bowed rather than flat.
        path.addCurve(
            to: tip,
            control1: CGPoint(x: 13, y: 10),
            control2: CGPoint(x: 8.5, y: 5.5)
        )

        path.closeSubpath()
        return path
    }

    private static func blankImage(width: Int, height: Int) -> CGImage {
        let ctx = CGContext(
            data: nil,
            width: max(1, width),
            height: max(1, height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        return ctx.makeImage()!
    }
}
