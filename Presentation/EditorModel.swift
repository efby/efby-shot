import AppKit
import Combine

enum MarkupTool: String, CaseIterable, Identifiable {
    case arrow = "Flecha"
    case rectangle = "Rectángulo"
    case ellipse = "Óvalo"
    case highlight = "Resaltar"
    case pixelate = "Pixelar"
    case text = "Texto"
    case step = "Paso"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .arrow: "arrow.up.right"
        case .rectangle: "rectangle"
        case .ellipse: "circle"
        case .highlight: "highlighter"
        case .pixelate: "square.grid.3x3.fill"
        case .text: "textformat"
        case .step: "number.circle.fill"
        }
    }
}

struct Annotation {
    let tool: MarkupTool
    let start: CGPoint
    let end: CGPoint
    let color: NSColor
    let text: String
    var stepNumber: Int? = nil
    var pixelatedPatch: NSImage? = nil
}

@MainActor
final class EditorModel: ObservableObject {
    let image: NSImage
    @Published var tool: MarkupTool = .arrow
    @Published var color: NSColor = .systemRed
    @Published var text = "Nota"
    @Published var annotations: [Annotation] = []

    init(image: NSImage) { self.image = image }

    func add(_ annotation: Annotation) {
        var prepared = annotation
        if annotation.tool == .pixelate {
            prepared.pixelatedPatch = Pixelator.makePatch(from: image, between: annotation.start, and: annotation.end)
            guard prepared.pixelatedPatch != nil else { return }
        }
        annotations.append(prepared)
    }
    func undo() { if !annotations.isEmpty { annotations.removeLast() } }

    func addStep(at point: CGPoint) {
        let number = (annotations.compactMap(\.stepNumber).max() ?? 0) + 1
        let marginX = min(22, image.size.width / 2)
        let marginY = min(22, image.size.height / 2)
        let center = CGPoint(x: min(max(point.x, marginX), image.size.width - marginX),
                             y: min(max(point.y, marginY), image.size.height - marginY))
        add(Annotation(tool: .step, start: center, end: center, color: color, text: "", stepNumber: number))
    }

    func renderedImage() -> NSImage {
        let size = image.size
        let output = NSImage(size: size)
        output.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))
        for annotation in annotations {
            EditorDrawing.draw(annotation, scale: 1, offset: .zero)
        }
        output.unlockFocus()
        return output
    }
}

enum EditorDrawing {
    static func draw(_ annotation: Annotation, scale: CGFloat, offset: CGPoint) {
        let a = CGPoint(x: annotation.start.x * scale + offset.x, y: annotation.start.y * scale + offset.y)
        let b = CGPoint(x: annotation.end.x * scale + offset.x, y: annotation.end.y * scale + offset.y)
        let rect = NSRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
        let path = NSBezierPath()
        path.lineWidth = max(2, 4 * scale)
        path.lineCapStyle = .round
        annotation.color.setStroke()
        switch annotation.tool {
        case .rectangle:
            path.appendRect(rect)
            path.stroke()
        case .ellipse:
            path.appendOval(in: rect)
            path.stroke()
        case .highlight:
            annotation.color.withAlphaComponent(0.28).setFill()
            rect.fill()
        case .pixelate:
            if let patch = annotation.pixelatedPatch {
                let previous = NSGraphicsContext.current?.imageInterpolation
                NSGraphicsContext.current?.imageInterpolation = .none
                patch.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
                if let previous { NSGraphicsContext.current?.imageInterpolation = previous }
            } else {
                NSColor.gray.withAlphaComponent(0.35).setFill()
                rect.fill()
                NSColor.white.setStroke()
                NSBezierPath(rect: rect).stroke()
            }
        case .arrow:
            path.move(to: a)
            path.line(to: b)
            path.stroke()
            let angle = atan2(b.y - a.y, b.x - a.x)
            let head = max(10, 16 * scale)
            let arrow = NSBezierPath()
            arrow.lineWidth = path.lineWidth
            arrow.lineCapStyle = .round
            arrow.move(to: CGPoint(x: b.x - head * cos(angle - .pi / 5), y: b.y - head * sin(angle - .pi / 5)))
            arrow.line(to: b)
            arrow.line(to: CGPoint(x: b.x - head * cos(angle + .pi / 5), y: b.y - head * sin(angle + .pi / 5)))
            arrow.stroke()
        case .text:
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: annotation.color,
                .font: NSFont.boldSystemFont(ofSize: max(12, 24 * scale))
            ]
            (annotation.text.isEmpty ? "Nota" : annotation.text).draw(at: a, withAttributes: attributes)
        case .step:
            guard let number = annotation.stepNumber else { return }
            let diameter: CGFloat = 44 * scale
            let circle = NSBezierPath(ovalIn: NSRect(x: a.x - diameter / 2, y: a.y - diameter / 2,
                                                     width: diameter, height: diameter))
            NSGraphicsContext.saveGraphicsState()
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
            shadow.shadowBlurRadius = 4 * scale
            shadow.shadowOffset = NSSize(width: 1 * scale, height: -2 * scale)
            shadow.set()
            annotation.color.setFill()
            circle.fill()
            NSGraphicsContext.restoreGraphicsState()
            NSColor.black.withAlphaComponent(0.3).setStroke()
            circle.lineWidth = max(1, scale)
            circle.stroke()

            let rgb = annotation.color.usingColorSpace(.deviceRGB) ?? annotation.color
            let brightness = 0.2126 * rgb.redComponent + 0.7152 * rgb.greenComponent + 0.0722 * rgb.blueComponent
            let foreground: NSColor = brightness > 0.65 ? .black : .white
            let label = String(number) as NSString
            let baseFont = NSFont.boldSystemFont(ofSize: 23 * scale)
            let baseWidth = label.size(withAttributes: [.font: baseFont]).width
            let font = NSFont.boldSystemFont(ofSize: 23 * scale * min(1, diameter * 0.78 / max(1, baseWidth)))
            let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: foreground, .font: font]
            let textSize = label.size(withAttributes: attributes)
            label.draw(at: CGPoint(x: a.x - textSize.width / 2, y: a.y - textSize.height / 2),
                       withAttributes: attributes)
        }
    }
}

private enum Pixelator {
    static func makePatch(from image: NSImage, between start: CGPoint, and end: CGPoint) -> NSImage? {
        let bounds = CGRect(origin: .zero, size: image.size)
        let selection = CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                               width: abs(end.x - start.x), height: abs(end.y - start.y))
            .intersection(bounds).integral
        guard selection.width >= 4, selection.height >= 4 else { return nil }

        let tileSize: CGFloat = 24
        let columns = max(1, Int(ceil(selection.width / tileSize)))
        let rows = max(1, Int(ceil(selection.height / tileSize)))
        guard let samples = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: columns, pixelsHigh: rows,
                                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                             isPlanar: false, colorSpaceName: .deviceRGB,
                                             bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: samples) else { return nil }
        samples.size = NSSize(width: columns, height: rows)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        image.draw(in: NSRect(x: 0, y: 0, width: columns, height: rows),
                   from: selection, operation: .copy, fraction: 1)
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()

        let patch = NSImage(size: selection.size)
        patch.lockFocus()
        for row in 0..<rows {
            for column in 0..<columns {
                (samples.colorAt(x: column, y: row) ?? .black).setFill()
                NSRect(x: CGFloat(column) * selection.width / CGFloat(columns),
                       y: CGFloat(row) * selection.height / CGFloat(rows),
                       width: selection.width / CGFloat(columns) + 0.5,
                       height: selection.height / CGFloat(rows) + 0.5).fill()
            }
        }
        patch.unlockFocus()
        return patch
    }
}
