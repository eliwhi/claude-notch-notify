// notchpop: a small pop-up that grows out of the MacBook notch with an orange spark
// and a message, pulses for a moment, then tucks back in.
// Click it to jump back to the app that launched it (Claude, your terminal, VS Code...).
// Hovering keeps it open.
//
// Build:
//   swiftc -O notchpop.swift -o notchpop
//
// Usage:
//   ./notchpop [message="Done"] [seconds=3]
//   NOTCHPOP_DEBUG=1 ./notchpop   (prints which app a click will open)

import AppKit
import Darwin

let args = CommandLine.arguments
let message = args.count > 1 ? args[1] : "Done"
let holdSeconds = args.count > 2 ? (Double(args[2]) ?? 3) : 3
let verbose = ProcessInfo.processInfo.environment["NOTCHPOP_DEBUG"] != nil

let orange = NSColor(srgbRed: 0.85, green: 0.47, blue: 0.34, alpha: 1)

func parentPID(of pid: pid_t) -> pid_t {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
    guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return 0 }
    return info.kp_eproc.e_ppid
}

// Walk up the process tree to the first real app (one with a Dock icon). Helper processes,
// shells and the claude CLI itself are skipped. This must run at launch: once the hook's
// shell exits we get re-parented and the chain is lost.
func launchingApp() -> NSRunningApplication? {
    var pid = getppid()
    for _ in 0..<32 where pid > 1 {
        if let app = NSRunningApplication(processIdentifier: pid), app.activationPolicy == .regular {
            return app
        }
        pid = parentPID(of: pid)
    }
    return nil
}

// Black shape that hangs from the top of the screen: flat top, rounded bottom corners.
final class NotchShapeView: NSView {
    var onClick: (() -> Void)?
    var onHover: ((Bool) -> Void)?

    override func draw(_ dirtyRect: NSRect) {
        let r = min(bounds.height / 2, 12)
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

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) { onClick?() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .cursorUpdate, .activeAlways, .inVisibleRect], owner: self))
    }
    override func mouseEntered(with event: NSEvent) { onHover?(true) }
    override func mouseExited(with event: NSEvent) { onHover?(false) }
    override func cursorUpdate(with event: NSEvent) {
        (onClick != nil ? NSCursor.pointingHand : NSCursor.arrow).set()
    }
}

// Orange spark (a burst of rounded rays) that gently pulses and turns.
final class SparkView: NSView {
    var phase: CGFloat = 0
    override func draw(_ dirtyRect: NSRect) {
        let c = NSPoint(x: bounds.midX, y: bounds.midY)
        let pulse = 0.82 + 0.18 * sin(phase * 2)
        let outer = min(bounds.width, bounds.height) / 2 * pulse
        let rays = 10
        orange.setStroke()
        for i in 0..<rays {
            let a = CGFloat(i) / CGFloat(rays) * .pi * 2 + phase * 0.4
            // Alternate long and short rays so it reads as a spark, not a sun.
            let len = i % 2 == 0 ? outer : outer * 0.72
            let p = NSBezierPath()
            p.lineWidth = max(1.6, outer * 0.22)
            p.lineCapStyle = .round
            p.move(to: NSPoint(x: c.x + cos(a) * outer * 0.18, y: c.y + sin(a) * outer * 0.18))
            p.line(to: NSPoint(x: c.x + cos(a) * len, y: c.y + sin(a) * len))
            p.stroke()
        }
    }
}

final class Popup: NSObject, NSApplicationDelegate {
    var window: NSPanel!
    var spark: SparkView!
    var label: NSTextField!
    var timer: Timer?
    var closedFrame = NSRect.zero
    var hovering = false
    var closing = false
    let target = launchingApp()

    func applicationDidFinishLaunching(_ note: Notification) {
        if verbose {
            let name = target?.localizedName ?? "nothing (click disabled)"
            fputs("notchpop: click opens \(name)\n", stderr)
        }

        // Prefer the screen with a notch (the built-in display); fall back to the main screen.
        let screen = NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main!
        let sf = screen.frame
        let hasNotch = screen.safeAreaInsets.top > 0

        let notchHeight: CGFloat = hasNotch ? screen.safeAreaInsets.top : 32
        var notchWidth: CGFloat = 180
        if hasNotch, let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            notchWidth = sf.width - left.width - right.width
        }

        // Closed = exactly the notch. Open = wider "ears" on each side, same height.
        let ear: CGFloat = 46
        let textWidth = max(ear, (message as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 13, weight: .semibold)]).width + 18)
        let closed = NSRect(x: sf.midX - notchWidth / 2, y: sf.maxY - notchHeight, width: notchWidth, height: notchHeight)
        let openWidth = notchWidth + ear + textWidth
        let openHeight = notchHeight // grow sideways only, never below the notch
        // Keep the notch itself centred: the left ear holds the spark, the right ear the text.
        let open = NSRect(x: sf.midX - notchWidth / 2 - ear, y: sf.maxY - openHeight, width: openWidth, height: openHeight)
        closedFrame = closed

        window = NSPanel(contentRect: closed, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]

        let shape = NotchShapeView(frame: NSRect(origin: .zero, size: closed.size))
        shape.autoresizingMask = [.width, .height]
        if target != nil {
            shape.onClick = { [weak self] in self?.jumpBack() }
        }
        shape.onHover = { [weak self] inside in
            guard let s = self else { return }
            s.hovering = inside
            // Leaving the pop-up gives a short grace period before it tucks away.
            if !inside { DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { s.closeIfIdle() } }
        }
        window.contentView = shape

        let sparkSize = min(notchHeight - 8, 24)
        spark = SparkView(frame: NSRect(x: (ear - sparkSize) / 2 + 4, y: (openHeight - sparkSize) / 2, width: sparkSize, height: sparkSize))
        spark.autoresizingMask = [.maxXMargin, .minYMargin]
        spark.alphaValue = 0
        shape.addSubview(spark)

        label = NSTextField(labelWithString: message)
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .white
        label.alignment = .center
        label.sizeToFit()
        label.frame = NSRect(x: openWidth - textWidth, y: (openHeight - label.frame.height) / 2, width: textWidth - 6, height: label.frame.height)
        label.autoresizingMask = [.minXMargin, .minYMargin]
        label.alphaValue = 0
        shape.addSubview(label)

        // Lay the subviews out for the open size, then shrink: autoresizing keeps them pinned.
        shape.setFrameSize(open.size)
        shape.setFrameSize(closed.size)

        window.orderFrontRegardless()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            guard let s = self else { return }
            s.spark.phase += 0.08
            s.spark.needsDisplay = true
        }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 1.3, 0.4, 1)
            window.animator().setFrame(open, display: true)
            spark.animator().alphaValue = 1
            label.animator().alphaValue = 1
        }, completionHandler: {
            DispatchQueue.main.asyncAfter(deadline: .now() + holdSeconds) { self.closeIfIdle() }
        })
    }

    // Stay open while the pointer is over the pop-up; check again shortly.
    func closeIfIdle() {
        if hovering {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.closeIfIdle() }
        } else {
            close()
        }
    }

    func jumpBack() {
        if let url = target?.bundleURL {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config)
        } else {
            target?.activate()
        }
        hovering = false
        close()
    }

    func close() {
        guard !closing else { return }
        closing = true
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().setFrame(closedFrame, display: true)
            spark.animator().alphaValue = 0
            label.animator().alphaValue = 0
        }, completionHandler: {
            NSApp.terminate(nil)
        })
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory) // no Dock icon, never steals focus
let delegate = Popup()
app.delegate = delegate
app.run()
