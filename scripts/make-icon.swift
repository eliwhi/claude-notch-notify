// Draws assets/icon.png: the notch pop-up (black pill with an orange spark) on a dark tile.
// Run: swift scripts/make-icon.swift
import AppKit

let size: CGFloat = 512
let orange = NSColor(srgbRed: 0.85, green: 0.47, blue: 0.34, alpha: 1)
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Tile: warm dark gradient, rounded like a macOS app icon.
let tile = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size), xRadius: 112, yRadius: 112)
NSGradient(starting: NSColor(srgbRed: 0.20, green: 0.17, blue: 0.16, alpha: 1),
           ending: NSColor(srgbRed: 0.09, green: 0.08, blue: 0.08, alpha: 1))!.draw(in: tile, angle: -90)

// The pop-up: a black pill hanging from a "screen edge" line near the top.
let pill = NSRect(x: 72, y: 268, width: 368, height: 120)
let pillPath = NSBezierPath(roundedRect: pill, xRadius: 60, yRadius: 60)
NSColor.black.setFill()
pillPath.fill()
NSColor(white: 1, alpha: 0.08).setStroke()
pillPath.lineWidth = 3
pillPath.stroke()

// Orange spark on the left of the pill.
func spark(at c: NSPoint, radius outer: CGFloat) {
    orange.setStroke()
    for i in 0..<10 {
        let a = CGFloat(i) / 10 * .pi * 2 + 0.3
        let len = i % 2 == 0 ? outer : outer * 0.72
        let p = NSBezierPath()
        p.lineWidth = outer * 0.22
        p.lineCapStyle = .round
        p.move(to: NSPoint(x: c.x + cos(a) * outer * 0.18, y: c.y + sin(a) * outer * 0.18))
        p.line(to: NSPoint(x: c.x + cos(a) * len, y: c.y + sin(a) * len))
        p.stroke()
    }
}
spark(at: NSPoint(x: pill.minX + 66, y: pill.midY), radius: 40)

// A "text" bar on the right of the pill, suggesting the message.
NSColor(white: 1, alpha: 0.9).setFill()
NSBezierPath(roundedRect: NSRect(x: pill.minX + 132, y: pill.midY - 9, width: 190, height: 18), xRadius: 9, yRadius: 9).fill()

// Keyboard keys below, with one lit caps-lock style dot.
let keyW: CGFloat = 76, keyH: CGFloat = 60, gap: CGFloat = 16
let rowX = (size - (keyW * 4 + gap * 3)) / 2
for row in 0..<2 {
    for col in 0..<4 {
        let r = NSRect(x: rowX + CGFloat(col) * (keyW + gap), y: 160 - CGFloat(row) * (keyH + gap), width: keyW, height: keyH)
        NSColor(white: 1, alpha: 0.10).setFill()
        NSBezierPath(roundedRect: r, xRadius: 14, yRadius: 14).fill()
        if row == 1 && col == 0 {
            NSColor(srgbRed: 0.35, green: 0.9, blue: 0.45, alpha: 1).setFill()
            NSBezierPath(ovalIn: NSRect(x: r.minX + 12, y: r.maxY - 22, width: 10, height: 10)).fill()
        }
    }
}

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "assets/icon.png"))
print("wrote assets/icon.png")
