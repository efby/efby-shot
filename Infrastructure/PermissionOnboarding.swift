import AppKit
import ScreenCaptureKit

@MainActor
enum PermissionOnboarding {
    @discardableResult
    static func runIfNeeded() async -> Bool {
        if await isGranted() { return true }

        NSApp.activate(ignoringOtherApps: true)
        await triggerSystemRegistration()
        if await isGranted() { return true }

        while true {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Registrar \(AppMetadata.displayName) para capturas"
            alert.informativeText = """
            Puedes usar \(AppMetadata.displayName) desde cualquier carpeta; no hace falta instalarla en Aplicaciones. macOS asocia el permiso a esta copia firmada (\(ScreenCapturePermission.runningAppPath)).

            En Ajustes del Sistema > Privacidad y seguridad > Grabación de pantalla y audio del sistema:
            1. Pulsa «Registrar en el sistema».
            2. Si no aparece en la lista, pulsa + y elige esta app en Finder («Mostrar app en Finder»).
            3. Activa el interruptor y vuelve a abrir \(AppMetadata.displayName) desde la misma ubicación.
            """
            alert.addButton(withTitle: "Registrar en el sistema")
            alert.addButton(withTitle: "Mostrar app en Finder")
            alert.addButton(withTitle: "Abrir Ajustes")
            alert.addButton(withTitle: "Ahora no")

            switch alert.runModal() {
            case .alertFirstButtonReturn:
                await triggerSystemRegistration()
                if await isGranted() { return true }
            case .alertSecondButtonReturn:
                ScreenCapturePermission.revealRunningAppInFinder()
            case .alertThirdButtonReturn:
                ScreenCapturePermission.openSystemSettings()
            default:
                return false
            }
        }
    }

    private static func isGranted() async -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        return await ScreenCapturePermission.hasAccess()
    }

    static func triggerSystemRegistration() async {
        NSApp.activate(ignoringOtherApps: true)
        _ = CGRequestScreenCaptureAccess()
        try? await Task.sleep(for: .milliseconds(500))
        _ = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        try? await Task.sleep(for: .milliseconds(200))
    }
}
