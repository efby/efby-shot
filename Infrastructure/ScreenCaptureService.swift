import AppKit
import ScreenCaptureKit

@MainActor
protocol ScreenCapturing {
    func captureArea(_ rect: CGRect, on display: SCDisplay, screenFrame: CGRect, scale: CGFloat) async throws -> CGImage
    func captureDisplay(_ display: SCDisplay, scale: CGFloat) async throws -> CGImage
    func captureWindow(_ window: SCWindow, scale: CGFloat) async throws -> CGImage
    func availableContent() async throws -> SCShareableContent
}

@MainActor
final class ScreenCaptureService: ScreenCapturing {
    func availableContent() async throws -> SCShareableContent {
        try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    }

    func captureArea(_ rect: CGRect, on display: SCDisplay, screenFrame: CGRect, scale: CGFloat) async throws -> CGImage {
        let sourceRect = ScreenCaptureGeometry.sourceRect(for: rect, on: screenFrame)
        guard sourceRect.width > 1, sourceRect.height > 1 else {
            throw CaptureFailure.invalidSelection
        }
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.sourceRect = sourceRect
        configuration.width = max(1, Int((sourceRect.width * scale).rounded(.up)))
        configuration.height = max(1, Int((sourceRect.height * scale).rounded(.up)))
        configuration.showsCursor = false
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
    }

    func captureDisplay(_ display: SCDisplay, scale: CGFloat) async throws -> CGImage {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.width = max(1, Int((display.frame.width * scale).rounded(.up)))
        configuration.height = max(1, Int((display.frame.height * scale).rounded(.up)))
        configuration.showsCursor = false
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
    }

    func captureWindow(_ window: SCWindow, scale: CGFloat) async throws -> CGImage {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        configuration.width = max(1, Int((window.frame.width * scale).rounded(.up)))
        configuration.height = max(1, Int((window.frame.height * scale).rounded(.up)))
        configuration.showsCursor = false
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
    }
}
