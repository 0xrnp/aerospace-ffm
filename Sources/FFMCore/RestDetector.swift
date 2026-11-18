import CoreGraphics
import Foundation

/// Reports when the cursor has stopped moving for `delay` seconds, once per stop.
public struct RestDetector {
    public let delay: TimeInterval
    private var lastPoint: CGPoint?
    private var lastMoveTime: TimeInterval = 0
    private var reported = false

    public init(delay: TimeInterval) {
        self.delay = delay
    }

    /// Feed the current cursor state on every poll. Returns true once per stop, when the cursor
    /// has been still for `delay` and no mouse button is held. A button held through the stop
    /// (a drag) delays the report until the button is released.
    public mutating func update(point: CGPoint, now: TimeInterval, buttonDown: Bool) -> Bool {
        if point != lastPoint {
            lastPoint = point
            lastMoveTime = now
            reported = false
            return false
        }
        guard !reported, now - lastMoveTime >= delay, !buttonDown else { return false }
        reported = true
        return true
    }
}
