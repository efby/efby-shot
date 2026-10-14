import AppKit
import SwiftUI

struct EditorView: View {
    @ObservedObject var model: EditorModel
    let exporter: ImageExporter
    let settings: CaptureSettings
    let onClose: () -> Void
    @State private var message = ""
    @State private var hasExported = false

    private let colors: [(String, NSColor)] = [
        ("Rojo", .systemRed), ("Verde", .systemGreen), ("Amarillo", .systemYellow),
        ("Azul", .systemBlue), ("Negro", .black), ("Blanco", .white)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ForEach(MarkupTool.allCases) { tool in
                    Button(tool.rawValue, systemImage: tool.symbol) { model.tool = tool }
                        .buttonStyle(.bordered)
                        .tint(model.tool == tool ? .accentColor : nil)
                }
                Divider().frame(height: 24)
                ForEach(colors, id: \.0) { name, color in
                    Button {
                        model.color = color
                    } label: {
                        Circle()
                            .fill(Color(nsColor: color))
                            .frame(width: 19, height: 19)
                            .overlay(Circle().stroke(model.color == color ? Color.primary : .clear, lineWidth: 2))
                    }
                        .buttonStyle(.plain)
                        .accessibilityLabel(name)
                }
                Spacer()
                Button("Deshacer", systemImage: "arrow.uturn.backward") { model.undo() }
                    .disabled(model.annotations.isEmpty)
            }
            .padding(12)

            if model.tool == .text {
                Text("Haz clic en la imagen, escribe la nota y pulsa Intro")
                    .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

            EditorCanvas(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 18) {
                Button("Guardar PNG", systemImage: "square.and.arrow.down") { save() }
                Button("Copiar imagen", systemImage: "doc.on.doc") {
                    exporter.copy(model.renderedImage())
                    onClose()
                }
                Spacer()
                Text(message).foregroundStyle(.secondary)
                if settings.copyAutomatically || settings.saveAutomatically {
                    Button("Finalizar", systemImage: "checkmark") { finish() }
                        .buttonStyle(.borderedProminent)
                }
                Button(hasExported ? "Cerrar" : "Descartar", systemImage: hasExported ? "xmark" : "trash") {
                    onClose()
                }
            }
            .padding(12)
        }
        .frame(minWidth: 720, minHeight: 500)
    }

    private func save() {
        do {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            if try exporter.saveWithPanel(model.renderedImage(), suggestedName: "\(settings.filenamePrefix)-\(formatter.string(from: Date())).png") {
                onClose()
            }
        } catch {
            message = error.localizedDescription
        }
    }

    private func finish() {
        let image = model.renderedImage()
        do {
            if settings.saveAutomatically {
                let directory = settings.destination ?? FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent(AppMetadata.defaultPicturesFolderName)
                _ = try exporter.saveAutomatically(image, to: directory, prefix: settings.filenamePrefix)
                hasExported = true
            }
            if settings.copyAutomatically {
                exporter.copy(image)
                hasExported = true
            }
            onClose()
        } catch {
            message = error.localizedDescription
        }
    }
}
