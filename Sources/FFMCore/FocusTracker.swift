/// Decides when the window under a resting cursor should take focus.
///
/// Focus moves only when the cursor rests over a different window than at the previous rest.
/// Resting again over the same window does nothing, so focus changed from the keyboard sticks
/// until the mouse goes to another window. The first rest after launch only records the window,
/// so starting the tool doesn't change focus.
public struct FocusTracker {
    private var lastWindow: UInt32?
    private var started = false

    public init() {}

    /// Pass the window under the cursor at a rest, or nil when there is none.
    /// Returns the window to focus, or nil to leave focus alone.
    public mutating func enteredWindow(_ window: UInt32?) -> UInt32? {
        defer {
            lastWindow = window
            started = true
        }
        guard started, let window, window != lastWindow else { return nil }
        return window
    }

    /// Call when focusing the window did not happen (AeroSpace failed or timed out), so the
    /// next rest over the same window tries again instead of treating it as already handled.
    public mutating func forget() {
        lastWindow = nil
    }
}
