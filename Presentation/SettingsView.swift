import AppKit
import SwiftUI

struct SettingsView: View {
    let repository: SettingsRepository
    let onCapture: (CaptureMode) -> Void
    @State private var prefix = "MonitorShot"
    @State private var copyAutomatically = false
    @State private var saveAutomatically = false
    @State private var destination: URL?
    @State private var launchAtLogin = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            Section("Capturar ahora") {
                HStack {
                    ForEach(CaptureMode.allCases) { mode in
                        Button(mode.rawValue) { onCapture(mode) }
                    }
                }
            }

            Section("Sistema") {
                Toggle("Iniciar MonitorShot al entrar en la cuenta", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        do { try repository.setLaunchAtLogin(enabled) }
                        catch { errorMessage = error.localizedDescription }
                    }
                TextField("Prefijo del nombre de archivo", text: $prefix)
            }

            Section("Atajos globales") {
                LabeledContent("Área", value: "⇧⌘1")
                LabeledContent("Ventana", value: "⇧⌘2")
                LabeledContent("Monitor", value: "⇧⌘0")
            }

            Section("Destinos al finalizar") {
                Toggle("Copiar al portapapeles al finalizar", isOn: $copyAutomatically)
                Toggle("Guardar en una carpeta al finalizar", isOn: $saveAutomatically)
                HStack {
                    Text(destination?.path ?? "Imágenes/MonitorShot")
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Elegir carpeta…") { chooseFolder() }
                }
            }

            if !errorMessage.isEmpty {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear(perform: load)
        .onChange(of: prefix) { _, _ in save() }
        .onChange(of: copyAutomatically) { _, _ in save() }
        .onChange(of: saveAutomatically) { _, _ in save() }
    }

    private func load() {
        let settings = repository.settings
        prefix = settings.filenamePrefix
        copyAutomatically = settings.copyAutomatically
        saveAutomatically = settings.saveAutomatically
        destination = settings.destination
        launchAtLogin = settings.launchAtLogin
    }

    private func save() {
        repository.settings = CaptureSettings(
            filenamePrefix: prefix.trimmingCharacters(in: .whitespacesAndNewlines),
            copyAutomatically: copyAutomatically,
            saveAutomatically: saveAutomatically,
            destination: destination,
            launchAtLogin: launchAtLogin
        )
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            destination = panel.url
            save()
        }
    }
}
