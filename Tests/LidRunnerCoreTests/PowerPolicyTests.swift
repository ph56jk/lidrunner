import XCTest
@testable import LidRunnerCore

final class PowerPolicyTests: XCTestCase {
    func testDisabledAwakeModeNeverRunsAssertions() {
        for source in allPowerSources {
            let preferences = AppPreferences(
                awakeModeEnabled: false,
                onlyWhenOnACPower: false,
                showWindowOnLaunch: true
            )

            XCTAssertEqual(
                PowerPolicy.decision(preferences: preferences, powerSource: source),
                .disabledByPreference
            )
        }
    }

    func testAwakeModeRunsOnAllPowerSourcesWhenChargerOnlyIsOff() {
        for source in allPowerSources {
            let preferences = AppPreferences(
                awakeModeEnabled: true,
                onlyWhenOnACPower: false,
                showWindowOnLaunch: true
            )

            XCTAssertEqual(
                PowerPolicy.decision(preferences: preferences, powerSource: source),
                .runAssertions
            )
        }
    }

    func testChargerOnlyRunsOnlyOnACPower() {
        let preferences = AppPreferences(
            awakeModeEnabled: true,
            onlyWhenOnACPower: true,
            showWindowOnLaunch: true
        )

        XCTAssertEqual(
            PowerPolicy.decision(preferences: preferences, powerSource: .acPower),
            .runAssertions
        )
        XCTAssertEqual(
            PowerPolicy.decision(preferences: preferences, powerSource: .batteryPower),
            .blockedByPowerSource
        )
        XCTAssertEqual(
            PowerPolicy.decision(preferences: preferences, powerSource: .upsPower),
            .blockedByPowerSource
        )
        XCTAssertEqual(
            PowerPolicy.decision(preferences: preferences, powerSource: .unknown),
            .blockedByPowerSource
        )
    }

    private var allPowerSources: [PowerSource] {
        [.acPower, .batteryPower, .upsPower, .unknown]
    }
}
