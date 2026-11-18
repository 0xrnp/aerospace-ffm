import CoreGraphics
import FFMCore
import XCTest

final class RestDetectorTests: XCTestCase {
    private let a = CGPoint(x: 10, y: 10)
    private let b = CGPoint(x: 20, y: 20)

    func testReportsOnceAfterCursorRestsForDelay() {
        var detector = RestDetector(delay: 0.1)
        XCTAssertFalse(detector.update(point: a, now: 0, buttonDown: false))
        XCTAssertFalse(detector.update(point: a, now: 0.05, buttonDown: false))
        XCTAssertTrue(detector.update(point: a, now: 0.1, buttonDown: false))
        XCTAssertFalse(detector.update(point: a, now: 0.15, buttonDown: false))
        XCTAssertFalse(detector.update(point: a, now: 5, buttonDown: false))
    }

    func testMovementRestartsTheWait() {
        var detector = RestDetector(delay: 0.1)
        _ = detector.update(point: a, now: 0, buttonDown: false)
        XCTAssertFalse(detector.update(point: b, now: 0.08, buttonDown: false))
        XCTAssertFalse(detector.update(point: b, now: 0.15, buttonDown: false))
        XCTAssertTrue(detector.update(point: b, now: 0.2, buttonDown: false))
    }

    func testReportsAgainAfterTheNextStop() {
        var detector = RestDetector(delay: 0.1)
        _ = detector.update(point: a, now: 0, buttonDown: false)
        XCTAssertTrue(detector.update(point: a, now: 0.1, buttonDown: false))
        _ = detector.update(point: b, now: 0.2, buttonDown: false)
        XCTAssertTrue(detector.update(point: b, now: 0.35, buttonDown: false))
    }

    func testHeldButtonDelaysReportUntilRelease() {
        var detector = RestDetector(delay: 0.1)
        _ = detector.update(point: a, now: 0, buttonDown: true)
        XCTAssertFalse(detector.update(point: a, now: 0.2, buttonDown: true))
        XCTAssertTrue(detector.update(point: a, now: 0.25, buttonDown: false))
    }

    func testZeroDelayReportsOnFirstStillPoll() {
        var detector = RestDetector(delay: 0)
        XCTAssertFalse(detector.update(point: a, now: 0, buttonDown: false))
        XCTAssertTrue(detector.update(point: a, now: 0.05, buttonDown: false))
    }
}
