import AppKit

@MainActor
enum PermissionOnboarding {
    @discardableResult
    static func runIfNeeded() async -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }

        NSApp.activate(ignoringOtherApps: true)
        // El diálogo nativo solicita el permiso para esta app y este usuario.
        // No abre Ajustes ni intenta modificar una preferencia protegida.
        if CGRequestScreenCaptureAccess() { return true }
        if await ScreenCapturePermission.hasAccess() { return true }

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Permiso de captura pendiente"
        alert.informativeText = """
        macOS no concedió el permiso a \(AppMetadata.displayName). Si lo rechazaste antes, puedes revisarlo en Ajustes del Sistema > Privacidad y seguridad > Grabación de pantalla y audio del sistema.

        Si Ajustes solicita un administrador, esa restricción la establece macOS para este equipo. \(AppMetadata.displayName) no puede omitirla ni necesita recibir la contraseña.
        """
        alert.addButton(withTitle: "Cerrar")
        alert.addButton(withTitle: "Abrir Ajustes")
        if alert.runModal() == .alertSecondButtonReturn {
            ScreenCapturePermission.openSystemSettings()
        }
        return false
    }
}
