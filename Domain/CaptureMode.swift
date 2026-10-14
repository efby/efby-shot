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
        case .permissionDenied: "Activa \(AppMetadata.displayName) en Ajustes del Sistema > Privacidad y seguridad > Grabación de pantalla y audio del sistema. Si ya está activado, desactívalo y actívalo de nuevo para esta copia de la app, luego sal de la app y ábrela otra vez."
        case .noDisplay: "No hay monitores disponibles para capturar."
        case .noWindow: "No hay ventanas disponibles para capturar."
        case .cancelled: "Captura cancelada."
        case .invalidSelection: "Selecciona un área más grande."
        case .cannotEncode: "No se pudo crear el archivo PNG."
        }
    }
}
