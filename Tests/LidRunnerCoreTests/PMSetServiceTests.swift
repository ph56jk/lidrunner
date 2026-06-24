import XCTest
@testable import LidRunnerCore

final class PMSetServiceTests: XCTestCase {
    func testParsesSleepDisabledFromCurrentPowerSettings() {
        let output = """
        System-wide power settings:
         SleepDisabled        1
        Currently in use:
         sleep                1 (sleep prevented by LidRunner)
        """

        XCTAssertEqual(PMSetService.parseClosedLidStatus(from: output), .enabled)
    }

    func testParsesDisableSleepFromCustomPowerSettings() {
        let output = """
        AC Power:
         disablesleep         0
        """

        XCTAssertEqual(PMSetService.parseClosedLidStatus(from: output), .disabled)
    }

    func testReturnsNotReportedWhenNoClosedLidKeyExists() {
        let output = """
        Currently in use:
         displaysleep         10
         sleep                1
        """

        XCTAssertEqual(PMSetService.parseClosedLidStatus(from: output), .notReported)
    }
}
