import AppKit

@main
struct MultiMonitorGeometry {
    @MainActor
    static func main() {
        let left = CGRect(x: -1280, y: 0, width: 1280, height: 1024)
        let leftSelection = CGRect(x: -1170, y: 110, width: 300, height: 180)
        let leftSource = ScreenCaptureGeometry.sourceRect(for: leftSelection, on: left)
        precondition(leftSource == CGRect(x: 110, y: 734, width: 300, height: 180))

        let above = CGRect(x: 0, y: 900, width: 1920, height: 1080)
        let aboveSelection = CGRect(x: 50, y: 950, width: 250, height: 100)
        let aboveSource = ScreenCaptureGeometry.sourceRect(for: aboveSelection, on: above)
        precondition(aboveSource == CGRect(x: 50, y: 930, width: 250, height: 100))

        let crossingSelection = CGRect(x: -100, y: 100, width: 300, height: 200)
        let clipped = ScreenCaptureGeometry.clippedSelection(crossingSelection, to: left, scale: 2)
        precondition(clipped == CGRect(x: -100, y: 100, width: 100, height: 200))
        precondition(ScreenCaptureGeometry.sourceRect(for: clipped, on: left)
            == CGRect(x: 1180, y: 724, width: 100, height: 200))

        let draggedIntoAnotherScreen = ScreenCaptureGeometry.clamp(CGPoint(x: 200, y: 300), to: left)
        precondition(draggedIntoAnotherScreen == CGPoint(x: 0, y: 300))
        let draggedBelowScreen = ScreenCaptureGeometry.clamp(CGPoint(x: 250, y: 100), to: above)
        precondition(draggedBelowScreen == CGPoint(x: 250, y: 900))

        print("Geometría de varios monitores verificada")
    }
}
