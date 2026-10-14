import AppKit
import Carbon

@main
@MainActor
final class MonitorShotApp: NSObject, NSApplicationDelegate {
    private let coordinator = CaptureCoordinator()
    private var statusItem: NSStatusItem?
    private var statusSpacer: NSStatusItem?
    private var statusLayoutTimer: Timer?
    private var hotKeys: [EventHotKeyRef?] = []
    private var eventHandler: EventHandlerRef?

    static func main() {
        let app = NSApplication.shared
        let delegate = MonitorShotApp()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let spacer = NSStatusBar.system.statusItem(withLength: 1)
        spacer.button?.isEnabled = false
        statusSpacer = spacer
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let statusIcon = Bundle.main.path(forResource: "AppIcon", ofType: "icns").flatMap(NSImage.init(contentsOfFile:))
            ?? NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "MonitorShot")
        statusIcon?.size = NSSize(width: 21, height: 21)
        statusIcon?.isTemplate = false
        item.button?.image = statusIcon
        item.button?.imageScaling = .scaleProportionallyDown
        item.button?.toolTip = "MonitorShot"
        item.isVisible = true
        statusItem = item
        let menu = NSMenu()
        menu.addItem(withTitle: "Capturar área", action: #selector(captureArea), keyEquivalent: "")
        menu.addItem(withTitle: "Capturar ventana", action: #selector(captureWindow), keyEquivalent: "")
        menu.addItem(withTitle: "Capturar monitor", action: #selector(captureDisplay), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Preferencias…", action: #selector(showSettings), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Salir de MonitorShot", action: #selector(quit), keyEquivalent: "")
        for menuItem in menu.items { menuItem.target = self }
        item.menu = menu
        let timer = Timer(timeInterval: 2, target: self, selector: #selector(repositionStatusItem), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        statusLayoutTimer = timer
        if CommandLine.arguments.contains("--diagnose-status") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                let frame = item.button?.window?.frame ?? .zero
                let left = item.button?.window?.screen?.auxiliaryTopLeftArea ?? .zero
                let window = item.button?.window
                let report = "item=\(frame) left=\(left) spacer=\(spacer.length) occluded=\(window?.occlusionState.rawValue ?? 0) shown=\(window?.isVisible ?? false) image=\(item.button?.image != nil)\n"
                try? report.write(to: FileManager.default.temporaryDirectory.appendingPathComponent("MonitorShot-status.txt"), atomically: true, encoding: .utf8)
            }
        }
        registerHotKeys()
        if CommandLine.arguments.contains("--demo") {
            coordinator.showDemoEditor()
        } else if CommandLine.arguments.contains("--show-settings") {
            coordinator.showSettings()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.repositionStatusItem()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in self?.showStatusMenu() }
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showStatusMenu()
        return true
    }

    private func showStatusMenu() {
        statusItem?.button?.performClick(nil)
    }

    @objc private func repositionStatusItem() {
        guard let item = statusItem, let spacer = statusSpacer,
              let window = item.button?.window, let screen = window.screen else { return }
        let frame = window.frame
        guard frame.minY >= screen.frame.minY else { return }
        let left = screen.auxiliaryTopLeftArea
        let right = screen.auxiliaryTopRightArea
        var desired: CGFloat = 1
        let baselineX = frame.minX + spacer.length - 1
        if let left, let right, !left.isEmpty, !right.isEmpty,
           baselineX < right.minX + 8 {
            let targetX = left.maxX - frame.width - 8
            desired = max(1, min(240, spacer.length + frame.minX - targetX))
        }
        if abs(spacer.length - desired) > 2 { spacer.length = desired }
    }

    @objc private func captureArea() { coordinator.start(.area) }
    @objc private func captureWindow() { coordinator.start(.window) }
    @objc private func captureDisplay() { coordinator.start(.display) }
    @objc private func showSettings() { coordinator.showSettings() }
    @objc private func quit() { NSApp.terminate(nil) }

    private func registerHotKeys() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, event, userData in
            guard let event, let userData else { return OSStatus(eventNotHandledErr) }
            var identifier = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &identifier)
            guard status == noErr else { return status }
            let app = Unmanaged<MonitorShotApp>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async {
                switch identifier.id {
                case 1: app.captureArea()
                case 2: app.captureWindow()
                case 3: app.captureDisplay()
                default: break
                }
            }
            return noErr
        }
        InstallEventHandler(GetApplicationEventTarget(), callback, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        for (id, key) in [(UInt32(1), UInt32(kVK_ANSI_1)), (UInt32(2), UInt32(kVK_ANSI_2)), (UInt32(3), UInt32(kVK_ANSI_0))] {
            var reference: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: 0x4D534854, id: id)
            let result = RegisterEventHotKey(key, UInt32(cmdKey | shiftKey), hotKeyID, GetApplicationEventTarget(), 0, &reference)
            if result == noErr { hotKeys.append(reference) }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusLayoutTimer?.invalidate()
        for key in hotKeys { if let key { UnregisterEventHotKey(key) } }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
