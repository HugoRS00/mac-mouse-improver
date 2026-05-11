import AppKit
import CoreGraphics

enum CursorRenderer {
    /// Canvas size in points. The cursor is roughly the size of the system
    /// arrow, with extra padding so the soft shadow doesn't get clipped.
    static let size = CGSize(width: 30, height: 36)

    /// Hotspot in image coordinates (origin top-left, y down).
    /// Sits at the tip of the arrow.
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

        ctx.scaleBy(x: scale, y: scale)
        // Flip to image coordinates (origin top-left, y down) so the geometry
        // below reads naturally.
        ctx.translateBy(x: 0, y: size.height)
        ctx.scaleBy(x: 1, y: -1)

        let path = arrowPath()

        // Soft drop shadow.
        ctx.saveGState()
        let shadowColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.45)
        ctx.setShadow(offset: CGSize(width: 0, height: 1.5), blur: 2.5, color: shadowColor)
        ctx.addPath(path)
        ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))
        ctx.fillPath()
        ctx.restoreGState()

        // White outline, drawn slightly fat under the black fill so it reads
        // as a clean stroke around the silhouette.
        ctx.addPath(path)
        ctx.setLineWidth(2.0)
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

    /// The arrow silhouette. Coordinates are in image space (y down) with
    /// the hotspot at (4, 4) — the tip. Tracing clockwise from the tip:
    /// down the left edge, up-right to the inner kink, around the tail,
    /// back up to the top-right of the head, then diagonally back to the
    /// tip (that closing line is the angled right edge of the arrow head).
    private static func arrowPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 4, y: 4))         // tip
        path.addLine(to: CGPoint(x: 4, y: 28))     // bottom of left edge
        path.addLine(to: CGPoint(x: 10, y: 22))    // inner kink (body / tail)
        path.addLine(to: CGPoint(x: 15, y: 33))    // tail bottom-left
        path.addLine(to: CGPoint(x: 18, y: 32))    // tail bottom-right
        path.addLine(to: CGPoint(x: 13, y: 21))    // tail upper-right
        path.addLine(to: CGPoint(x: 19, y: 15))    // top-right of head
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
