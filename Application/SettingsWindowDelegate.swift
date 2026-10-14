import AppKit

@MainActor
final class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    private let onHide: () -> Void

    init(onHide: @escaping () -> Void) {
        self.onHide = onHide
    }

    func hide(_ window: NSWindow) {
        window.orderOut(nil)
        onHide()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hide(sender)
        return false
    }
}
