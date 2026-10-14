import AppKit
import SwiftUI

struct SettingsView: View {
    let repository: SettingsRepository
    let onCapture: (CaptureMode) -> Void
    @State private var prefix = AppMetadata.defaultFilenamePrefix
    @State private var copyAutomatically = false
    @State private var saveAutomatically = false
    @State private var destination: URL?
    @State private var launchAtLogin = false
    @State private var errorMessage = ""
    @State private var isApplyingLoad = false

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
                Toggle("Iniciar \(AppMetadata.displayName) al entrar en la cuenta", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { oldValue, enabled in
                        do { try repository.setLaunchAtLogin(enabled) }
                        catch {
                            launchAtLogin = oldValue
                            errorMessage = error.localizedDescription
                        }
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
                    Text(destination?.path ?? "Imágenes/\(AppMetadata.defaultPicturesFolderName)")
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
        .onChange(of: prefix) { _, _ in saveIfApplyingLoad() }
        .onChange(of: copyAutomatically) { _, _ in saveIfApplyingLoad() }
        .onChange(of: saveAutomatically) { _, _ in saveIfApplyingLoad() }
        .frame(minWidth: 600, minHeight: 480)
    }

    private func load() {
        isApplyingLoad = true
        let settings = repository.settings
        prefix = settings.filenamePrefix
        copyAutomatically = settings.copyAutomatically
        saveAutomatically = settings.saveAutomatically
        destination = settings.destination
        launchAtLogin = settings.launchAtLogin
        isApplyingLoad = false
    }

    private func saveIfApplyingLoad() {
        guard !isApplyingLoad else { return }
        save()
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
        panel.canCreateDirectories = true
        if let window = NSApp.keyWindow {
            panel.beginSheetModal(for: window) { response in
                guard response == .OK, let url = panel.url else { return }
                destination = url
                save()
            }
        } else if panel.runModal() == .OK, let url = panel.url {
            destination = url
            save()
        }
    }
}
