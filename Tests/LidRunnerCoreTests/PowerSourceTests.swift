import XCTest
@testable import LidRunnerCore

final class PowerSourceTests: XCTestCase {
    func testClassifiesKnownPowerSourceTypes() {
        XCTAssertEqual(PowerSource.classify(providingPowerSourceType: "AC Power"), .acPower)
        XCTAssertEqual(PowerSource.classify(providingPowerSourceType: "Battery Power"), .batteryPower)
        XCTAssertEqual(PowerSource.classify(providingPowerSourceType: "UPS Power"), .upsPower)
    }

    func testClassifiesUnknownPowerSourceTypes() {
        XCTAssertEqual(PowerSource.classify(providingPowerSourceType: nil), .unknown)
        XCTAssertEqual(PowerSource.classify(providingPowerSourceType: "Solar Power"), .unknown)
    }
}
