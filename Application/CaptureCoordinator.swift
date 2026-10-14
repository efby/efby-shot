import AppKit
import ScreenCaptureKit
import SwiftUI

@MainActor
final class CaptureCoordinator {
    private let capture: ScreenCapturing = ScreenCaptureService()
    private let exporter = ImageExporter()
    private let settings = SettingsRepository()
    private let areaSelector = AreaSelector()
    private struct EditorSession {
        let window: NSWindow
        let controller: NSHostingController<EditorView>
        let delegate: EditorWindowDelegate
    }

    private var editorSessions: [EditorSession] = []
    private var settingsWindow: NSWindow?
    private var settingsController: NSHostingController<SettingsView>?
    private var settingsDelegate: SettingsWindowDelegate?

    func start(_ mode: CaptureMode) {
        let exportSettings = settings.editorSettings
        Task { @MainActor in
            guard await ScreenCapturePermission.ensureAccessBeforeCapture() else { return }
            do {
                let image: CGImage
                let pixelScale: CGFloat
                switch mode {
                case .area:
                    let content = try await capture.availableContent()
                    guard !content.displays.isEmpty else { throw CaptureFailure.noDisplay }
                    guard let display = chooseDisplay(content.displays, for: mode) else { return }
                    guard let screen = ScreenCaptureGeometry.screen(for: display.displayID) else {
                        throw CaptureFailure.noDisplay
                    }
                    guard let rect = await areaSelector.select(on: screen) else { return }
                    image = try await capture.captureArea(
                        rect, on: display, screenFrame: screen.frame, scale: screen.backingScaleFactor
                    )
                    pixelScale = CGFloat(image.width) / rect.width
                case .display:
                    let content = try await capture.availableContent()
                    guard !content.displays.isEmpty else { throw CaptureFailure.noDisplay }
                    let selected = chooseDisplay(content.displays, for: mode)
                    guard let selected else { return }
                    let scale = ScreenCaptureGeometry.screen(for: selected.displayID)?.backingScaleFactor ?? 1
                    image = try await capture.captureDisplay(selected, scale: scale)
                    pixelScale = CGFloat(image.width) / selected.frame.width
                case .window:
                    let content = try await capture.availableContent()
                    guard !content.displays.isEmpty else { throw CaptureFailure.noDisplay }
                    guard let display = chooseDisplay(content.displays, for: mode) else { return }
                    let windows = content.windows.filter {
                        $0.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier
                            && $0.frame.width >= 40 && $0.frame.height >= 40
                            && $0.frame.intersects(display.frame)
                    }
                    guard !windows.isEmpty else { throw CaptureFailure.noWindow }
                    guard let selected = chooseWindow(windows) else { return }
                    let scale = ScreenCaptureGeometry.screen(for: display.displayID)?.backingScaleFactor ?? 1
                    image = try await capture.captureWindow(selected, scale: scale)
                    pixelScale = CGFloat(image.width) / selected.frame.width
                }
                deliver(image, preferences: exportSettings, pixelScale: pixelScale)
            } catch {
                if ScreenCapturePermission.isPermissionError(error) {
                    let allowed = await ScreenCapturePermission.hasAccess()
                    if allowed {
                        showError(error)
                    } else {
                        showPermissionDenied()
                    }
                } else {
                    showError(error)
                }
            }
        }
    }

    private func deliver(_ cgImage: CGImage, preferences: CaptureSettings, pixelScale: CGFloat) {
        let scale = max(pixelScale, 1)
        let size = NSSize(
            width: CGFloat(cgImage.width) / scale,
            height: CGFloat(cgImage.height) / scale
        )
        let image = NSImage(cgImage: cgImage, size: size)
        showEditor(image, preferences: preferences)
    }

    private func chooseDisplay(_ displays: [SCDisplay], for mode: CaptureMode) -> SCDisplay? {
        if displays.count == 1 { return displays[0] }
        let alert = NSAlert()
        alert.messageText = "Elegir monitor"
        alert.informativeText = "Selecciona el monitor para capturar \(mode.rawValue.lowercased())."
        alert.addButton(withTitle: "Capturar")
        alert.addButton(withTitle: "Cancelar")
        let picker = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 480, height: 28))
        for (index, display) in displays.enumerated() {
            picker.addItem(withTitle: displayTitle(display, number: index + 1))
        }
        alert.accessoryView = picker
        return alert.runModal() == .alertFirstButtonReturn ? displays[picker.indexOfSelectedItem] : nil
    }

    private func displayTitle(_ display: SCDisplay, number: Int) -> String {
        guard let screen = ScreenCaptureGeometry.screen(for: display.displayID) else {
            return "Monitor \(number) · \(display.width) × \(display.height) · ID \(display.displayID)"
        }
        let position: String
        if let main = NSScreen.screens.first, screen.cgDirectDisplayID == main.cgDirectDisplayID {
            position = "Principal"
        } else if let main = NSScreen.screens.first {
            let dx = screen.frame.midX - main.frame.midX
            let dy = screen.frame.midY - main.frame.midY
            position = abs(dx) >= abs(dy) ? (dx < 0 ? "Izquierda" : "Derecha")
                : (dy < 0 ? "Abajo" : "Arriba")
        } else {
            position = "Externo"
        }
        return "Monitor \(number) · \(screen.localizedName) · \(position) · \(display.width) × \(display.height)"
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
        let exportSettings = preferences ?? settings.editorSettings
        let model = EditorModel(image: image)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: true
        )
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none
        window.title = "\(AppMetadata.displayName) · Editor"
        let delegate = EditorWindowDelegate { [weak self, weak window] in
            guard let self, let window else { return }
            self.editorSessions.removeAll { $0.window === window }
        }
        window.delegate = delegate
        let view = EditorView(model: model, exporter: exporter, settings: exportSettings, onClose: { [weak delegate, weak window] in
            guard let window, let delegate else { return }
            delegate.hide(window)
        })
        let controller = NSHostingController(rootView: view)
        window.contentViewController = controller
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        editorSessions.append(EditorSession(window: window, controller: controller, delegate: delegate))
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
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 520),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferencias de \(AppMetadata.displayName)"
        window.minSize = NSSize(width: 560, height: 480)
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none
        let delegate = SettingsWindowDelegate { [weak window] in
            window?.orderOut(nil)
        }
        window.delegate = delegate
        settingsDelegate = delegate

        let view = SettingsView(repository: settings, onCapture: { [weak self, weak delegate, weak window] mode in
            guard let window, let delegate else { return }
            delegate.hide(window)
            DispatchQueue.main.async { self?.start(mode) }
        })
        let controller = NSHostingController(rootView: view)
        controller.sizingOptions = [.intrinsicContentSize, .preferredContentSize]
        window.contentViewController = controller
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
        settingsController = controller
    }

    private func showPermissionDenied() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Permiso de captura requerido"
        let base = CaptureFailure.permissionDenied.errorDescription ?? ""
        alert.informativeText = base + "\n\n" + ScreenCapturePermission.staleGrantHint
        alert.addButton(withTitle: "Abrir Ajustes del Sistema")
        alert.addButton(withTitle: "Cerrar")
        if alert.runModal() == .alertFirstButtonReturn {
            ScreenCapturePermission.openSystemSettings()
        }
    }

    private func showError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.runModal()
    }
}
