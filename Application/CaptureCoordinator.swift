import AppKit
import ScreenCaptureKit
import SwiftUI

@MainActor
final class CaptureCoordinator {
    private let capture: ScreenCapturing = ScreenCaptureService()
    private let exporter = ImageExporter()
    private let settings = SettingsRepository()
    private let areaSelector = AreaSelector()
    private var editorWindows: [NSWindow] = []
    private var settingsWindow: NSWindow?

    func start(_ mode: CaptureMode) {
        Task {
            do {
                let image: CGImage
                switch mode {
                case .area:
                    guard let rect = await areaSelector.select() else { return }
                    try await Task.sleep(for: .milliseconds(180))
                    image = try await capture.captureArea(rect)
                case .display:
                    let content = try await capture.availableContent()
                    guard !content.displays.isEmpty else { throw CaptureFailure.noDisplay }
                    let selected = chooseDisplay(content.displays)
                    guard let selected else { return }
                    image = try await capture.captureDisplay(selected)
                case .window:
                    let content = try await capture.availableContent()
                    let windows = content.windows.filter { $0.title?.isEmpty == false && $0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier }
                    guard !windows.isEmpty else { throw CaptureFailure.noWindow }
                    guard let selected = chooseWindow(windows) else { return }
                    image = try await capture.captureWindow(selected)
                }
                deliver(image)
            } catch {
                let detail = error.localizedDescription.lowercased()
                if detail.contains("tcc") || detail.contains("permission") || detail.contains("declined") {
                    showError(CaptureFailure.permissionDenied)
                } else {
                    showError(error)
                }
            }
        }
    }

    private func deliver(_ cgImage: CGImage) {
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        showEditor(image)
    }

    private func chooseDisplay(_ displays: [SCDisplay]) -> SCDisplay? {
        if displays.count == 1 { return displays[0] }
        let alert = NSAlert()
        alert.messageText = "Elegir monitor"
        alert.addButton(withTitle: "Capturar")
        alert.addButton(withTitle: "Cancelar")
        let picker = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 280, height: 28))
        for (index, display) in displays.enumerated() {
            picker.addItem(withTitle: "Monitor \(index + 1) · \(display.width) × \(display.height)")
        }
        alert.accessoryView = picker
        return alert.runModal() == .alertFirstButtonReturn ? displays[picker.indexOfSelectedItem] : nil
    }

    private func chooseWindow(_ windows: [SCWindow]) -> SCWindow? {
        let alert = NSAlert()
        alert.messageText = "Elegir ventana"
        alert.addButton(withTitle: "Capturar")
        alert.addButton(withTitle: "Cancelar")
        let picker = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 360, height: 28))
        for window in windows {
            picker.addItem(withTitle: "\(window.owningApplication?.applicationName ?? "Aplicación") — \(window.title ?? "Ventana")")
        }
        alert.accessoryView = picker
        return alert.runModal() == .alertFirstButtonReturn ? windows[picker.indexOfSelectedItem] : nil
    }

    private func showEditor(_ image: NSImage, preferences: CaptureSettings? = nil) {
        let model = EditorModel(image: image)
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        let view = EditorView(model: model, exporter: exporter, settings: preferences ?? settings.settings, onClose: { [weak window] in window?.close() })
        window.title = "MonitorShot · Editor"
        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        editorWindows.append(window)
        editorWindows.removeAll { !$0.isVisible }
    }

    func showDemoEditor() {
        let image = NSImage(size: NSSize(width: 800, height: 500))
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: 800, height: 500).fill()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 38),
            .foregroundColor: NSColor.black
        ]
        ("Dato de prueba: 1234" as NSString).draw(at: NSPoint(x: 70, y: 280), withAttributes: attributes)
        image.unlockFocus()
        var demoSettings = settings.settings
        demoSettings.copyAutomatically = true
        demoSettings.saveAutomatically = true
        demoSettings.destination = FileManager.default.temporaryDirectory.appendingPathComponent("MonitorShot-descartar-prueba")
        showEditor(image, preferences: demoSettings)
    }

    func showSettings() {
        if let settingsWindow { settingsWindow.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 620, height: 490), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Preferencias de MonitorShot"
        window.contentView = NSHostingView(rootView: SettingsView(repository: settings, onCapture: { [weak self] mode in self?.start(mode) }))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    private func showError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }
}
