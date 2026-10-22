import AppKit

let output = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
func rounded(_ rect: NSRect, _ radius: CGFloat, _ color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}
for size in [16, 32, 64, 128, 256, 512, 1024] {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                 isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let transform = NSAffineTransform()
    transform.scale(by: CGFloat(size) / 512)
    transform.concat()
    rounded(NSRect(x: 16, y: 16, width: 480, height: 480), 112, NSColor(srgbRed: 0.045, green: 0.12, blue: 0.105, alpha: 1))
    rounded(NSRect(x: 202, y: 445, width: 108, height: 65), 22, NSColor(srgbRed: 0.012, green: 0.043, blue: 0.035, alpha: 1))
    let green = NSColor(srgbRed: 0.40, green: 0.91, blue: 0.61, alpha: 1)
    for x in stride(from: 136, through: 360, by: 56) {
        for y in [147, 325] { rounded(NSRect(x: x, y: y, width: 16, height: 40), 8, green) }
    }
    NSColor(srgbRed: 0.85, green: 0.96, blue: 0.90, alpha: 1).setStroke()
    let chip = NSBezierPath(roundedRect: NSRect(x: 103, y: 183, width: 306, height: 146), xRadius: 30, yRadius: 30)
    chip.lineWidth = 16
    chip.stroke()
    for (index, height) in [68, 86, 96, 96].enumerated() {
        rounded(NSRect(x: 132 + index * 68, y: 212, width: 44, height: height), 8,
                index == 3 ? NSColor(srgbRed: 0.16, green: 0.28, blue: 0.24, alpha: 1) : green)
    }
    rounded(NSRect(x: 188, y: 88, width: 136, height: 10), 5, green)
    NSGraphicsContext.restoreGraphicsState()
    let data = bitmap.representation(using: .png, properties: [:])!
    if size == 512 { try data.write(to: URL(fileURLWithPath: "assets/icon.png")) }
    if size <= 512 { try data.write(to: URL(fileURLWithPath: output + "/icon_\(size)x\(size).png")) }
    if size >= 32 { try data.write(to: URL(fileURLWithPath: output + "/icon_\(size/2)x\(size/2)@2x.png")) }
}
