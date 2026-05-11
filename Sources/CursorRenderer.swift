import AppKit
import CoreGraphics

enum CursorRenderer {
    /// Canvas size in points. Sized to match the system cursor closely
    /// (only marginally larger) so the silhouette feels native, with a
    /// small amount of padding so the soft drop shadow doesn't get
    /// clipped at the edges.
    static let size = CGSize(width: 24, height: 30)

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
        ctx.setShadow(offset: CGSize(width: 0, height: 1.5), blur: 2.5, color: shadowColor)
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

    /// The arrow silhouette with rounded corners. Coordinates are in image
    /// space (y down) with the hotspot at (5, 5) — the tip. Tracing clockwise
    /// from the tip: down the left edge, up-right to the inner kink, around
    /// the tail, back up to the top-right of the head, then diagonally back
    /// to the tip (that closing line is the angled right edge of the head).
    private static func arrowPath() -> CGPath {
        let vertices: [CGPoint] = [
            CGPoint(x: 4,  y: 4),    // 0: tip
            CGPoint(x: 4,  y: 23),   // 1: bottom-left of head
            CGPoint(x: 9,  y: 18),   // 2: inner kink (head / tail)
            CGPoint(x: 12, y: 26),   // 3: tail bottom-left
            CGPoint(x: 15, y: 25),   // 4: tail bottom-right
            CGPoint(x: 11, y: 17),   // 5: tail upper-right
            CGPoint(x: 16, y: 13),   // 6: top-right of head
        ]
        // Rounding radius per vertex (0 = sharp). The tip stays almost sharp
        // so it still reads as a precise pointer; every other corner gets a
        // generous radius for the soft, friendly silhouette in the reference.
        let radii: [CGFloat] = [
            0.7,  // tip
            2.0,  // bottom-left of head
            1.6,  // inner kink
            2.2,  // tail bottom-left
            2.2,  // tail bottom-right
            1.6,  // tail upper-right
            2.0,  // top-right of head
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
