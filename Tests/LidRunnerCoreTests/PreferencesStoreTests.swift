import XCTest
@testable import LidRunnerCore

final class PreferencesStoreTests: XCTestCase {
    func testLoadsDefaultPreferencesWhenNoValuesExist() {
        let fixture = makeStoreFixture()

        XCTAssertEqual(fixture.store.load(), .defaults)
    }

    func testPersistsPreferenceUpdates() {
        let fixture = makeStoreFixture()
        let preferences = AppPreferences(
            awakeModeEnabled: false,
            onlyWhenOnACPower: true,
            showWindowOnLaunch: false
        )

        fixture.store.save(preferences)

        XCTAssertEqual(fixture.store.load(), preferences)
    }

    private func makeStoreFixture() -> (suiteName: String, store: PreferencesStore) {
        let suiteName = "com.lidrunner.tests.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return (suiteName, PreferencesStore(userDefaults: userDefaults))
    }
}
