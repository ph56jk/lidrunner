import XCTest
@testable import LidRunnerCore

final class LidStateTests: XCTestCase {
    func testClassifiesBooleanClamshellState() {
        XCTAssertEqual(LidState.classify(appleClamshellState: true), .closed)
        XCTAssertEqual(LidState.classify(appleClamshellState: false), .open)
    }

    func testClassifiesNumericClamshellState() {
        XCTAssertEqual(LidState.classify(appleClamshellState: NSNumber(value: 1)), .closed)
        XCTAssertEqual(LidState.classify(appleClamshellState: NSNumber(value: 0)), .open)
    }

    func testClassifiesUnknownClamshellState() {
        XCTAssertEqual(LidState.classify(appleClamshellState: nil), .unknown)
        XCTAssertEqual(LidState.classify(appleClamshellState: "closed"), .unknown)
    }
}
