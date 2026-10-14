import AppKit
import UniformTypeIdentifiers

struct ImageExporter {
    func pngData(from image: NSImage) throws -> Data {
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let data = bitmap.representation(using: .png, properties: [:]) else {
            throw CaptureFailure.cannotEncode
        }
        return data
    }

    @MainActor
    func copy(_ image: NSImage) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }

    @MainActor
    func saveWithPanel(_ image: NSImage, suggestedName: String) throws -> Bool {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = suggestedName
        guard panel.runModal() == .OK, let url = panel.url else { return false }
        try pngData(from: image).write(to: url, options: .atomic)
        return true
    }

    func saveAutomatically(_ image: NSImage, to directory: URL, prefix: String) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
        let base = "\(prefix.isEmpty ? "MonitorShot" : prefix)-\(formatter.string(from: Date()))"
        var url = directory.appendingPathComponent(base).appendingPathExtension("png")
        var suffix = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = directory.appendingPathComponent("\(base)-\(suffix)").appendingPathExtension("png")
            suffix += 1
        }
        try pngData(from: image).write(to: url, options: .atomic)
        return url
    }
}
