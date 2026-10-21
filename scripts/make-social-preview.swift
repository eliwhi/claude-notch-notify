// Draws assets/social-preview.png (1280x640) for the GitHub repo's social preview.
// Run: swift scripts/make-social-preview.swift
import AppKit

let W: CGFloat = 1280, H: CGFloat = 640
let orange = NSColor(srgbRed: 0.85, green: 0.47, blue: 0.34, alpha: 1)
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H), bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

NSGradient(starting: NSColor(srgbRed: 0.20, green: 0.17, blue: 0.16, alpha: 1),
           ending: NSColor(srgbRed: 0.08, green: 0.07, blue: 0.07, alpha: 1))!.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)

// A MacBook screen edge with the notch pop-up open, across the top.
NSColor.black.setFill()
NSRect(x: 0, y: H - 14, width: W, height: 14).fill()
let notchW: CGFloat = 260, notchH: CGFloat = 64, ear: CGFloat = 92, textW: CGFloat = 250
let popup = NSRect(x: W / 2 - notchW / 2 - ear, y: H - 14 - notchH, width: notchW + ear + textW, height: notchH + 14)
let pp = NSBezierPath()
let r: CGFloat = 26
pp.move(to: NSPoint(x: popup.minX, y: popup.maxY))
pp.line(to: NSPoint(x: popup.maxX, y: popup.maxY))
pp.line(to: NSPoint(x: popup.maxX, y: popup.minY + r))
pp.appendArc(withCenter: NSPoint(x: popup.maxX - r, y: popup.minY + r), radius: r, startAngle: 0, endAngle: 270, clockwise: true)
pp.line(to: NSPoint(x: popup.minX + r, y: popup.minY))
pp.appendArc(withCenter: NSPoint(x: popup.minX + r, y: popup.minY + r), radius: r, startAngle: 270, endAngle: 180, clockwise: true)
pp.close()
pp.fill()

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
spark(at: NSPoint(x: popup.minX + ear / 2 + 6, y: popup.minY + notchH / 2), radius: 22)

func text(_ s: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, at p: NSPoint, mono: Bool = false, center: Bool = false) {
    let font = mono ? NSFont.monospacedSystemFont(ofSize: size, weight: weight) : NSFont.systemFont(ofSize: size, weight: weight)
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let str = NSAttributedString(string: s, attributes: attrs)
    let x = center ? p.x - str.size().width / 2 : p.x
    str.draw(at: NSPoint(x: x, y: p.y))
}
text("Claude is done", size: 26, weight: .semibold, color: .white,
     at: NSPoint(x: popup.maxX - textW / 2, y: popup.minY + notchH / 2 - 16), center: true)

// Title, tagline, install hint.
text("claude-notch-notify", size: 76, weight: .bold, color: .white, at: NSPoint(x: W / 2, y: 318), center: true)
text("Your MacBook notch and keyboard light up when Claude Code finishes.", size: 30, weight: .regular,
     color: NSColor(white: 1, alpha: 0.72), at: NSPoint(x: W / 2, y: 262), center: true)

// Keyboard strip with a lit caps lock light.
let keyW: CGFloat = 70, keyH: CGFloat = 52, gap: CGFloat = 14, keys = 12
let rowX = (W - (keyW * CGFloat(keys) + gap * CGFloat(keys - 1))) / 2
for i in 0..<keys {
    let k = NSRect(x: rowX + CGFloat(i) * (keyW + gap), y: 150, width: keyW, height: keyH)
    NSColor(white: 1, alpha: i == 0 ? 0.16 : 0.09).setFill()
    NSBezierPath(roundedRect: k, xRadius: 12, yRadius: 12).fill()
    if i == 0 {
        NSColor(srgbRed: 0.35, green: 0.9, blue: 0.45, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: k.minX + 10, y: k.maxY - 19, width: 9, height: 9)).fill()
    }
}

text("Claude Code plugin  ·  one-line installer  ·  macOS", size: 24, weight: .medium,
     color: orange, at: NSPoint(x: W / 2, y: 74), center: true)

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "assets/social-preview.png"))
print("wrote assets/social-preview.png")
