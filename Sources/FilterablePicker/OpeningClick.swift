import Foundation

/// The popup can cover the button before its opening mouse-up arrives.
/// A click leaves it open; dragging into the menu can select on release.
struct OpeningClick {
    private var origin: CGPoint?
    private var hasDragged = false

    var isTracking: Bool { origin != nil }

    init(origin: CGPoint?) { self.origin = origin }

    mutating func dragged(to point: CGPoint) {
        guard let origin else { return }
        if hypot(point.x - origin.x, point.y - origin.y) >= 4 { hasDragged = true }
    }

    mutating func shouldIgnoreRelease(at point: CGPoint) -> Bool {
        guard origin != nil else { return false }
        dragged(to: point)
        origin = nil
        return !hasDragged
    }
}
