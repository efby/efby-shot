import AppKit
import Foundation

@main
struct EditorBehavior {
    @MainActor
    static func main() throws {
        let image = NSImage(size: NSSize(width: 800, height: 500))
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: 800, height: 500).fill()
        ("Dato de prueba: 1234" as NSString).draw(
            at: NSPoint(x: 70, y: 280),
            withAttributes: [.font: NSFont.systemFont(ofSize: 38), .foregroundColor: NSColor.black]
        )
        image.unlockFocus()

        let model = EditorModel(image: image)
        model.add(Annotation(tool: .pixelate, start: CGPoint(x: 60, y: 265),
                             end: CGPoint(x: 500, y: 340), color: .black, text: ""))
        model.add(Annotation(tool: .text, start: CGPoint(x: 70, y: 150),
                             end: CGPoint(x: 70, y: 150), color: .systemRed, text: "Nota aquí"))
        model.color = .systemGreen
        model.addStep(at: CGPoint(x: 120, y: 90))
        model.addStep(at: CGPoint(x: 260, y: 90))
        model.color = .systemBlue
        model.addStep(at: CGPoint(x: 400, y: 90))
        model.undo()
        model.addStep(at: CGPoint(x: 400, y: 90))
        guard model.annotations.count == 5,
              model.annotations.filter({ $0.tool == .step }).compactMap(\.stepNumber) == [1, 2, 3],
              model.annotations[2].color == .systemGreen,
              model.annotations[4].color == .systemBlue,
              model.annotations[0].pixelatedPatch != nil else {
            fatalError("El pixelado, el color o la numeración no se generaron")
        }

        let rendered = model.renderedImage()
        guard let data = NSBitmapImageRep(data: rendered.tiffRepresentation ?? Data())?
            .representation(using: .png, properties: [:]) else {
            fatalError("El PNG final no se generó")
        }
        let destination = URL(fileURLWithPath: CommandLine.arguments[1])
        try data.write(to: destination, options: .atomic)
        print("Editor verificado: \(destination.path)")
    }
}
