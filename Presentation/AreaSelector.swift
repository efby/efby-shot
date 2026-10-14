import AppKit

@MainActor
final class AreaSelector {
    private var panels: [NSPanel] = []
    private var completion: ((CGRect?) -> Void)?

    func select() async -> CGRect? {
        await withCheckedContinuation { continuation in
            var didResume = false
            completion = { rect in
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: rect)
            }
            for screen in NSScreen.screens {
                let panel = NSPanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
                panel.level = .screenSaver
                panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                panel.backgroundColor = .clear
                panel.isOpaque = false
                panel.hasShadow = false
                let view = SelectionView(frame: NSRect(origin: .zero, size: screen.frame.size))
                view.onFinish = { [weak self] rect in
                    guard let self else { return }
                    let screenRect = rect.map { panel.convertToScreen($0) }
                    self.finish(screenRect)
                }
                panel.contentView = view
                panel.makeKeyAndOrderFront(nil)
                panels.append(panel)
            }
            NSApp.activate(ignoringOtherApps: true)
            panels.first?.makeKey()
        }
    }

    private func finish(_ rect: CGRect?) {
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
        let callback = completion
        completion = nil
        callback?(rect)
    }
}

private final class SelectionView: NSView {
    var onFinish: ((CGRect?) -> Void)?
    private var start: NSPoint?
    private var end: NSPoint?

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.34).setFill()
        bounds.fill()
        guard let start, let end else { return }
        let rect = NSRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
        NSColor.clear.setFill()
        rect.fill(using: .clear)
        NSColor.white.setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = 2
        path.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        start = convert(event.locationInWindow, from: nil)
        end = start
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        end = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let start else { onFinish?(nil); return }
        let end = convert(event.locationInWindow, from: nil)
        let rect = NSRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(end.x - start.x), height: abs(end.y - start.y))
        onFinish?(rect.width > 4 && rect.height > 4 ? rect : nil)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onFinish?(nil) }
    }
}
