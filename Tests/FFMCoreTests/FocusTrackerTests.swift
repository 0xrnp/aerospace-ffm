import FFMCore
import XCTest

final class FocusTrackerTests: XCTestCase {
    func testFirstRestOnlyRecordsTheWindow() {
        var tracker = FocusTracker()
        XCTAssertNil(tracker.enteredWindow(1))
    }

    func testRestingOverAnotherWindowFocusesIt() {
        var tracker = FocusTracker()
        _ = tracker.enteredWindow(1)
        XCTAssertEqual(tracker.enteredWindow(2), 2)
    }

    func testRestingAgainOverTheSameWindowLeavesFocusAlone() {
        var tracker = FocusTracker()
        _ = tracker.enteredWindow(1)
        XCTAssertEqual(tracker.enteredWindow(2), 2)
        XCTAssertNil(tracker.enteredWindow(2))
    }

    func testReturningFromNoWindowFocusesAgain() {
        var tracker = FocusTracker()
        _ = tracker.enteredWindow(1)
        XCTAssertNil(tracker.enteredWindow(nil))
        XCTAssertEqual(tracker.enteredWindow(1), 1)
    }

    func testForgetLetsTheSameWindowBeTriedAgain() {
        var tracker = FocusTracker()
        _ = tracker.enteredWindow(1)
        XCTAssertEqual(tracker.enteredWindow(2), 2)
        tracker.forget()
        XCTAssertEqual(tracker.enteredWindow(2), 2)
    }

    func testFirstRestOverNoWindowThenAWindow() {
        var tracker = FocusTracker()
        XCTAssertNil(tracker.enteredWindow(nil))
        XCTAssertEqual(tracker.enteredWindow(1), 1)
    }
}
