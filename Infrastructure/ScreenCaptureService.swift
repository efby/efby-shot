import AppKit
import ScreenCaptureKit

@MainActor
protocol ScreenCapturing {
    func captureArea(_ rect: CGRect) async throws -> CGImage
    func captureDisplay(_ display: SCDisplay) async throws -> CGImage
    func captureWindow(_ window: SCWindow) async throws -> CGImage
    func availableContent() async throws -> SCShareableContent
}

@MainActor
final class ScreenCaptureService: ScreenCapturing {
    func availableContent() async throws -> SCShareableContent {
        try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    }

    func captureArea(_ rect: CGRect) async throws -> CGImage {
        let captureRect = rect.standardized
        guard captureRect.width > 1, captureRect.height > 1 else {
            throw CaptureFailure.invalidSelection
        }
        let screenshotRect = ScreenCaptureGeometry.rectForScreenshotCapture(captureRect)
        return try await SCScreenshotManager.captureImage(in: screenshotRect)
    }

    func captureDisplay(_ display: SCDisplay) async throws -> CGImage {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.width = display.width
        configuration.height = display.height
        configuration.showsCursor = false
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
    }

    func captureWindow(_ window: SCWindow) async throws -> CGImage {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        configuration.width = max(1, Int(window.frame.width))
        configuration.height = max(1, Int(window.frame.height))
        configuration.showsCursor = false
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
    }
}
