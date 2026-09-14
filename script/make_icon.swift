import AppKit
let directory = CommandLine.arguments[1]
let sizes = [16, 32, 128, 256, 512]
for size in sizes {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let transform = NSAffineTransform(); transform.scale(by: CGFloat(pixels) / 1024); transform.concat()
        NSColor(calibratedRed: 0.08, green: 0.40, blue: 0.43, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 45, y: 45, width: 934, height: 934), xRadius: 210, yRadius: 210).fill()
        NSColor(calibratedRed: 0.57, green: 0.89, blue: 0.83, alpha: 1).setFill()
        let folder = NSBezierPath()
        folder.move(to: NSPoint(x: 206, y: 330)); folder.line(to: NSPoint(x: 206, y: 682))
        folder.curve(to: NSPoint(x: 246, y: 722), controlPoint1: NSPoint(x: 206, y: 710), controlPoint2: NSPoint(x: 224, y: 722))
        folder.line(to: NSPoint(x: 425, y: 722)); folder.line(to: NSPoint(x: 493, y: 654)); folder.line(to: NSPoint(x: 778, y: 654))
        folder.curve(to: NSPoint(x: 818, y: 614), controlPoint1: NSPoint(x: 806, y: 654), controlPoint2: NSPoint(x: 818, y: 636))
        folder.line(to: NSPoint(x: 818, y: 330)); folder.close(); folder.fill()
        NSColor(calibratedRed: 0.91, green: 0.99, blue: 0.96, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 206, y: 282, width: 612, height: 310), xRadius: 42, yRadius: 42).fill()
        NSColor(calibratedRed: 0.08, green: 0.40, blue: 0.43, alpha: 1).setStroke()
        let path = NSBezierPath(); path.lineWidth = 32; path.lineCapStyle = .round; path.lineJoinStyle = .round
        path.move(to: NSPoint(x: 356, y: 502)); path.line(to: NSPoint(x: 356, y: 390)); path.line(to: NSPoint(x: 651, y: 390))
        path.move(to: NSPoint(x: 591, y: 450)); path.line(to: NSPoint(x: 651, y: 390)); path.line(to: NSPoint(x: 591, y: 330)); path.stroke()
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: directory).appendingPathComponent("icon_\(size)x\(size)\(suffix).png"))
    }
}
