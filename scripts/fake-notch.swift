// Draws a black stand-in for the MacBook notch, so screen recordings show it.
// macOS records the pixels behind the physical notch, so without this the pop-up
// seems to grow out of nothing. The stand-in sits below the pop-up and above the menu bar.
//
// Run: swift scripts/fake-notch.swift [seconds=60]
// Quit early with Ctrl+C.

import AppKit

let seconds = CommandLine.arguments.count > 1 ? (Double(CommandLine.arguments[1]) ?? 60) : 60

final class NotchView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        // Flat top, rounded bottom corners, like the real notch.
        let r: CGFloat = 9
        let b = bounds
        let path = NSBezierPath()
        path.move(to: NSPoint(x: b.minX, y: b.maxY))
        path.line(to: NSPoint(x: b.maxX, y: b.maxY))
        path.line(to: NSPoint(x: b.maxX, y: b.minY + r))
        path.appendArc(withCenter: NSPoint(x: b.maxX - r, y: b.minY + r), radius: r, startAngle: 0, endAngle: 270, clockwise: true)
        path.line(to: NSPoint(x: b.minX + r, y: b.minY))
        path.appendArc(withCenter: NSPoint(x: b.minX + r, y: b.minY + r), radius: r, startAngle: 270, endAngle: 180, clockwise: true)
        path.close()
        NSColor.black.setFill()
        path.fill()
    }
}

guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }),
      let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea else {
    print("No notch found on this Mac's screens.")
    exit(1)
}
let sf = screen.frame
let height = screen.safeAreaInsets.top
let frame = NSRect(x: sf.minX + left.width, y: sf.maxY - height, width: sf.width - left.width - right.width, height: height)

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let window = NSPanel(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
window.isOpaque = false
window.backgroundColor = .clear
window.hasShadow = false
window.ignoresMouseEvents = true
window.level = .popUpMenu // above the menu bar, below the pop-up
window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
window.contentView = NotchView(frame: NSRect(origin: .zero, size: frame.size))
window.orderFrontRegardless()

print("Stand-in notch showing for \(Int(seconds)) seconds (Ctrl+C to stop).")
DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { NSApp.terminate(nil) }
app.run()
