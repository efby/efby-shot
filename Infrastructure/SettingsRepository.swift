import Foundation
import ServiceManagement

@MainActor
final class SettingsRepository {
    private let defaults = UserDefaults.standard

    var settings: CaptureSettings {
        get {
            let destination = defaults.url(forKey: "destination")
            return CaptureSettings(
                filenamePrefix: defaults.string(forKey: "prefix") ?? "MonitorShot",
                copyAutomatically: defaults.bool(forKey: "copyAutomatically"),
                saveAutomatically: defaults.bool(forKey: "saveAutomatically"),
                destination: destination,
                launchAtLogin: SMAppService.mainApp.status == .enabled
            )
        }
        set {
            defaults.set(newValue.filenamePrefix, forKey: "prefix")
            defaults.set(newValue.copyAutomatically, forKey: "copyAutomatically")
            defaults.set(newValue.saveAutomatically, forKey: "saveAutomatically")
            defaults.set(newValue.destination, forKey: "destination")
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
