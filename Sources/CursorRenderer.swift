import AppKit
import CoreGraphics

enum CursorRenderer {
    /// Canvas size in points. Sized to sit closely over the system cursor
    /// with enough padding for the thicker white border and soft shadow.
    static let size = CGSize(width: 26, height: 32)

    /// Hotspot in image coordinates (origin top-left, y down). Sits at the
    /// tip of the arrow so the click point matches what the user sees.
    static let hotspot = CGPoint(x: 4, y: 4)

    /// White border width in points. This is what makes the silhouette
    /// read as "the system cursor, but puffier."
    private static let borderWidth: CGFloat = 2.8

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
        let shadowColor = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.45)
        ctx.setShadow(offset: CGSize(width: 0, height: 1.5), blur: 3, color: shadowColor)
        ctx.addPath(path)
        ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1))
        ctx.fillPath()
        ctx.restoreGState()

        // White border. Drawn as a stroke around the same path — width is
        // doubled in effect because the stroke is centered on the path and
        // the black fill covers the inside half.
        ctx.addPath(path)
        ctx.setLineWidth(borderWidth)
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

    /// The cursor silhouette — a classic macOS arrow, slightly widened so
    /// the body feels chubbier, with every corner replaced by a quadratic
    /// Bézier so the whole shape reads as rounded.
    ///
    /// Tracing clockwise from the tip:
    ///   tip → bottom of left edge → inner kink (where head meets tail)
    ///       → tail bottom-left → tail bottom-right → tail upper-right
    ///       → top-right of head → close back to tip.
    private static func arrowPath() -> CGPath {
        let vertices: [CGPoint] = [
            CGPoint(x: 4,  y: 4),    // 0: tip
            CGPoint(x: 4,  y: 24),   // 1: bottom of left edge
            CGPoint(x: 9,  y: 20),   // 2: inner kink
            CGPoint(x: 13, y: 28),   // 3: tail bottom-left
            CGPoint(x: 17, y: 26),   // 4: tail bottom-right
            CGPoint(x: 11, y: 19),   // 5: tail upper-right
            CGPoint(x: 18, y: 13),   // 6: top-right of head
        ]
        // The tip stays nearly sharp; everything else gets a generous
        // radius so adjacent edges blend into smooth arcs.
        let radii: [CGFloat] = [
            0.7,  // tip
            2.6,  // bottom-left
            2.0,  // inner kink
            2.4,  // tail bottom-left
            2.4,  // tail bottom-right
            2.0,  // tail upper-right
            2.6,  // top-right
        ]
        return roundedPolygon(vertices: vertices, radii: radii)
    }

    /// Builds a closed CGPath that traces the given polygon, rounding each
    /// vertex with the matching radius using a quadratic Bézier curve.
    /// The radius is automatically capped to half the length of either
    /// adjacent edge so adjacent rounded corners never overlap.
    private static func roundedPolygon(vertices: [CGPoint], radii: [CGFloat]) -> CGPath {
        let path = CGMutablePath()
        let n = vertices.count
        guard n >= 3 else { return path }

        var entry = [CGPoint](repeating: .zero, count: n)
        var exitP = [CGPoint](repeating: .zero, count: n)
        for i in 0..<n {
            let prev = vertices[(i + n - 1) % n]
            let curr = vertices[i]
            let next = vertices[(i + 1) % n]
            let r = radii[i]

            let inDx = curr.x - prev.x
            let inDy = curr.y - prev.y
            let inLen = max(0.0001, (inDx * inDx + inDy * inDy).squareRoot())

            let outDx = next.x - curr.x
            let outDy = next.y - curr.y
            let outLen = max(0.0001, (outDx * outDx + outDy * outDy).squareRoot())

            let cappedR = min(r, inLen * 0.5, outLen * 0.5)

            entry[i] = CGPoint(
                x: curr.x - (inDx / inLen) * cappedR,
                y: curr.y - (inDy / inLen) * cappedR
            )
            exitP[i] = CGPoint(
                x: curr.x + (outDx / outLen) * cappedR,
                y: curr.y + (outDy / outLen) * cappedR
            )
        }

        path.move(to: exitP[0])
        for i in 1..<n {
            path.addLine(to: entry[i])
            path.addQuadCurve(to: exitP[i], control: vertices[i])
        }
        path.addLine(to: entry[0])
        path.addQuadCurve(to: exitP[0], control: vertices[0])
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
