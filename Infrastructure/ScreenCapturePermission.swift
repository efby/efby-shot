import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit

@MainActor
enum ScreenCapturePermission {
    /// Evita repetir el probe lento de ScreenCaptureKit en cada captura de la sesión.
    private static var sessionAccessGranted = false

    static var legacyPreflightAccess: Bool { CGPreflightScreenCaptureAccess() }

    static func hasAccess() async -> Bool {
        if sessionAccessGranted { return true }
        if CGPreflightScreenCaptureAccess() {
            sessionAccessGranted = true
            return true
        }
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            sessionAccessGranted = true
            return true
        } catch {
            if isPermissionError(error) { return false }
            sessionAccessGranted = true
            return true
        }
    }

    /// Registra la app en la base TCC y muestra el diálogo del sistema si hace falta.
    @discardableResult
    static func ensureAccessBeforeCapture() async -> Bool {
        if sessionAccessGranted || CGPreflightScreenCaptureAccess() {
            sessionAccessGranted = true
            return true
        }
        if await hasAccess() { return true }
        return await PermissionOnboarding.runIfNeeded()
    }

    static func presentPermissionGuide() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Activa la captura de pantalla"
        alert.informativeText = """
        \(AppMetadata.displayName) debe aparecer en Ajustes del Sistema > Privacidad y seguridad > Grabación de pantalla y audio del sistema.

        Si no lo ves en la lista, pulsa «Solicitar permiso» y vuelve a abrir esta ventana. Después de activarlo, sal de \(AppMetadata.displayName) y abre la app otra vez.
        """
        alert.addButton(withTitle: "Abrir Ajustes del Sistema")
        alert.addButton(withTitle: "Solicitar permiso")
        alert.addButton(withTitle: "Cerrar")
        switch alert.runModal() {
        case .alertFirstButtonReturn:
            openSystemSettings()
        case .alertSecondButtonReturn:
            Task { await PermissionOnboarding.runIfNeeded() }
        default:
            break
        }
    }

    static func isPermissionError(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == "com.apple.screencapturekit", ns.code == -3801 || ns.code == -3803 {
            return true
        }
        let detail = error.localizedDescription.lowercased()
        let keywords = [
            "tcc", "permission", "permiso", "declined", "deneg", "rechaz",
            "not authorized", "no autoriz", "user denied", "usuario deneg"
        ]
        return keywords.contains { detail.contains($0) }
    }

    static func openSystemSettings() {
        if #available(macOS 13.0, *) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture")!)
            return
        }
        let legacy = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(legacy)
    }

    static var staleGrantHint: String {
        """
        Si \(AppMetadata.displayName) ya aparece activado en Ajustes, desactívalo y actívalo de nuevo para la copia que estás ejecutando, luego sal de la app y ábrela otra vez desde la misma carpeta.
        """
    }

    static var runningAppPath: String { Bundle.main.bundleURL.path }

    static func revealRunningAppInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }
}
