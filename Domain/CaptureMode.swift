import Foundation

enum CaptureMode: String, CaseIterable, Identifiable {
    case area = "Área"
    case window = "Ventana"
    case display = "Monitor"

    var id: String { rawValue }
}

struct CaptureSettings {
    var filenamePrefix: String
    var copyAutomatically: Bool
    var saveAutomatically: Bool
    var destination: URL?
    var launchAtLogin: Bool
}

enum CaptureFailure: LocalizedError {
    case permissionDenied
    case noDisplay
    case noWindow
    case cancelled
    case invalidSelection
    case cannotEncode

    var errorDescription: String? {
        switch self {
        case .permissionDenied: "Para capturar, activa MonitorShot en Ajustes del Sistema > Privacidad y seguridad > Grabación de pantalla y audio del sistema. Después, cierra y vuelve a abrir la app."
        case .noDisplay: "No hay monitores disponibles para capturar."
        case .noWindow: "No hay ventanas disponibles para capturar."
        case .cancelled: "Captura cancelada."
        case .invalidSelection: "Selecciona un área más grande."
        case .cannotEncode: "No se pudo crear el archivo PNG."
        }
    }
}
