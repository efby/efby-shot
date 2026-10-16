import AppKit

@MainActor
final class AreaSelector {
    private var panels: [CaptureOverlayPanel] = []
    private var completion: (((rect: CGRect, displayID: CGDirectDisplayID)?) -> Void)?

    func select() async -> (rect: CGRect, displayID: CGDirectDisplayID)? {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return nil }
        return await withCheckedContinuation { (continuation: CheckedContinuation<(rect: CGRect, displayID: CGDirectDisplayID)?, Never>) in
            var didResume = false
            completion = { selection in
                guard !didResume else { return }
                didResume = true
                continuation.resume(returning: selection)
            }

            panels = screens.map { screen in
                let overlay = CaptureOverlayPanel(
                    contentRect: screen.frame,
                    styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
                    backing: .buffered,
                    defer: false
                )
                overlay.level = .screenSaver
                overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                overlay.backgroundColor = .clear
                overlay.isOpaque = false
                overlay.hasShadow = false

                let view = SelectionView()
                view.autoresizingMask = [.width, .height]
                view.selectionScreen = screen
                view.onFinish = { [weak self] screenRect in
                    guard let self else { return }
                    guard let screenRect, let displayID = screen.cgDirectDisplayID else {
                        self.finish(nil)
                        return
                    }
                    let aligned = ScreenCaptureGeometry.clippedSelection(
                        screenRect, to: screen.frame, scale: screen.backingScaleFactor
                    )
                    guard aligned.width > 4, aligned.height > 4 else {
                        self.finish(nil)
                        return
                    }
                    self.finish((aligned, displayID))
                }

                overlay.contentView = view
                overlay.setFrame(screen.frame, display: true)
                view.frame = NSRect(origin: .zero, size: overlay.frame.size)
                overlay.orderFrontRegardless()
                return overlay
            }

            NSApp.activate(ignoringOtherApps: true)
            let pointer = NSEvent.mouseLocation
            panels.first { $0.frame.contains(pointer) }?.makeKey()
        }
    }

    private func finish(_ selection: (rect: CGRect, displayID: CGDirectDisplayID)?) {
        panels.forEach { $0.orderOut(nil) }
        panels.removeAll()
        let callback = completion
        completion = nil
        callback?(selection)
    }
}

private final class CaptureOverlayPanel: NSPanel {
    override var contentLayoutRect: NSRect {
        NSRect(origin: .zero, size: frame.size)
    }
}

@MainActor
enum ScreenCaptureGeometry {
    static func screen(for displayID: CGDirectDisplayID) -> NSScreen? {
        NSScreen.screens.first { $0.cgDirectDisplayID == displayID }
    }

    static func alignToPixelGrid(_ rect: CGRect, scale: CGFloat) -> CGRect {
        guard scale > 0 else { return rect.integral }
        let minX = floor(rect.minX * scale) / scale
        let minY = floor(rect.minY * scale) / scale
        let maxX = ceil(rect.maxX * scale) / scale
        let maxY = ceil(rect.maxY * scale) / scale
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    static func clippedSelection(_ rect: CGRect, to screenFrame: CGRect, scale: CGFloat) -> CGRect {
        alignToPixelGrid(rect.standardized, scale: scale).intersection(screenFrame)
    }

    static func clamp(_ point: CGPoint, to screenFrame: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(point.x, screenFrame.minX), screenFrame.maxX),
            y: min(max(point.y, screenFrame.minY), screenFrame.maxY)
        )
    }

    /// Cocoa usa origen abajo-izquierda; ScreenCaptureKit espera un rect local al monitor
    /// con origen arriba-izquierda cuando se captura con un filtro de display.
    static func sourceRect(for cocoaRect: CGRect, on screenFrame: CGRect) -> CGRect {
        let rect = cocoaRect.standardized.intersection(screenFrame)
        return CGRect(
            x: rect.minX - screenFrame.minX,
            y: screenFrame.maxY - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }
}

private final class SelectionView: NSView {
    var onFinish: ((CGRect?) -> Void)?
    var selectionScreen: NSScreen?
    private var startScreen: CGPoint?
    private var endScreen: CGPoint?

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.34).setFill()
        bounds.fill()
        guard let startScreen, let endScreen, let window else { return }
        let startView = window.convertPoint(fromScreen: startScreen)
        let endView = window.convertPoint(fromScreen: endScreen)
        let rect = normalizedRect(from: startView, to: endView)
        NSColor.clear.setFill()
        rect.fill(using: .clear)
        NSColor.white.setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = 2
        path.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        guard selectionScreen != nil else { onFinish?(nil); return }
        let point = NSEvent.mouseLocation
        startScreen = point
        endScreen = startScreen
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let selectionScreen else { return }
        endScreen = ScreenCaptureGeometry.clamp(NSEvent.mouseLocation, to: selectionScreen.frame)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let startScreen, let selectionScreen else { onFinish?(nil); return }
        let endScreen = ScreenCaptureGeometry.clamp(NSEvent.mouseLocation, to: selectionScreen.frame)
        let rect = normalizedRect(from: startScreen, to: endScreen)
        onFinish?(rect.width > 4 && rect.height > 4 ? rect : nil)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onFinish?(nil) }
    }

    private func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }
}
