import AppKit
import SwiftUI

struct EditorCanvas: NSViewRepresentable {
    let model: EditorModel

    func makeNSView(context: Context) -> MarkupCanvasView {
        MarkupCanvasView(model: model)
    }

    func updateNSView(_ nsView: MarkupCanvasView, context: Context) {
        nsView.needsDisplay = true
    }
}

@MainActor
final class MarkupCanvasView: NSView, NSTextFieldDelegate {
    private let model: EditorModel
    private var dragStart: CGPoint?
    private var dragEnd: CGPoint?
    private var activeTextField: NSTextField?
    private var textOrigin: CGPoint?

    init(model: EditorModel) {
        self.model = model
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no disponible") }

    private var imageRect: NSRect {
        let size = model.image.size
        let scale = min(bounds.width / size.width, bounds.height / size.height)
        let width = size.width * scale
        let height = size.height * scale
        return NSRect(x: (bounds.width - width) / 2, y: (bounds.height - height) / 2, width: width, height: height)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        bounds.fill()
        let rect = imageRect
        model.image.draw(in: rect)
        let scale = rect.width / model.image.size.width
        for annotation in model.annotations {
            EditorDrawing.draw(annotation, scale: scale, offset: rect.origin)
        }
        if let dragStart, let dragEnd {
            let preview = Annotation(tool: model.tool, start: dragStart, end: dragEnd, color: model.color, text: model.text)
            EditorDrawing.draw(preview, scale: scale, offset: rect.origin)
        }
    }

    private func imagePoint(_ event: NSEvent) -> CGPoint? {
        imagePoint(from: convert(event.locationInWindow, from: nil))
    }

    private func imagePoint(from point: NSPoint) -> CGPoint? {
        let rect = imageRect
        guard rect.contains(point) else { return nil }
        return CGPoint(x: (point.x - rect.minX) / rect.width * model.image.size.width,
                       y: (point.y - rect.minY) / rect.height * model.image.size.height)
    }

    override func mouseDown(with event: NSEvent) {
        if model.tool == .text {
            guard let point = imagePoint(event) else { return }
            beginText(at: point)
            return
        }
        dragStart = imagePoint(event)
        dragEnd = dragStart
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard model.tool != .text else { return }
        dragEnd = imagePoint(event)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard model.tool != .text else { return }
        defer { dragStart = nil; dragEnd = nil; needsDisplay = true }
        guard let start = dragStart, let end = imagePoint(event) ?? dragEnd else { return }
        model.add(Annotation(tool: model.tool, start: start, end: end, color: model.color, text: model.text))
    }

    private func beginText(at imagePoint: CGPoint) {
        commitText()
        let rect = imageRect
        let scale = rect.width / model.image.size.width
        let desired = CGPoint(x: rect.minX + imagePoint.x * scale, y: rect.minY + imagePoint.y * scale)
        let width = min(300, rect.width)
        let x = min(desired.x, rect.maxX - width)
        let origin = CGPoint(x: max(rect.minX, x), y: min(desired.y, rect.maxY - 30))
        guard let actualOrigin = self.imagePoint(from: origin) else { return }
        let field = NSTextField(frame: NSRect(x: origin.x, y: origin.y, width: width, height: 30))
        field.placeholderString = "Escribe aquí…"
        field.font = .boldSystemFont(ofSize: max(12, 24 * scale))
        field.textColor = .labelColor
        field.delegate = self
        field.target = self
        field.action = #selector(commitText)
        addSubview(field)
        activeTextField = field
        textOrigin = actualOrigin
        window?.makeFirstResponder(field)
    }

    @objc private func commitText() {
        guard let field = activeTextField, let origin = textOrigin else { return }
        let value = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        activeTextField = nil
        textOrigin = nil
        field.removeFromSuperview()
        if !value.isEmpty {
            model.add(Annotation(tool: .text, start: origin, end: origin, color: model.color, text: value))
        }
        needsDisplay = true
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        commitText()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            commitText()
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            activeTextField?.removeFromSuperview()
            activeTextField = nil
            textOrigin = nil
            return true
        }
        return false
    }
}
