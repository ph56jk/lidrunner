import Foundation

public final class PreferencesStore {
    public enum Key {
        public static let awakeModeEnabled = "app.preferences.awakeModeEnabled"
        public static let onlyWhenOnACPower = "app.preferences.onlyWhenOnACPower"
        public static let showWindowOnLaunch = "app.preferences.showWindowOnLaunch"
    }

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func load() -> AppPreferences {
        AppPreferences(
            awakeModeEnabled: bool(forKey: Key.awakeModeEnabled, default: AppPreferences.defaults.awakeModeEnabled),
            onlyWhenOnACPower: bool(forKey: Key.onlyWhenOnACPower, default: AppPreferences.defaults.onlyWhenOnACPower),
            showWindowOnLaunch: bool(forKey: Key.showWindowOnLaunch, default: AppPreferences.defaults.showWindowOnLaunch)
        )
    }

    public func save(_ preferences: AppPreferences) {
        userDefaults.set(preferences.awakeModeEnabled, forKey: Key.awakeModeEnabled)
        userDefaults.set(preferences.onlyWhenOnACPower, forKey: Key.onlyWhenOnACPower)
        userDefaults.set(preferences.showWindowOnLaunch, forKey: Key.showWindowOnLaunch)
    }

    private func bool(forKey key: String, default defaultValue: Bool) -> Bool {
        guard userDefaults.object(forKey: key) != nil else { return defaultValue }
        return userDefaults.bool(forKey: key)
    }
}
