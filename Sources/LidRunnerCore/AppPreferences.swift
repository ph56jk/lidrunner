import Foundation

public struct AppPreferences: Equatable {
    public var awakeModeEnabled: Bool
    public var onlyWhenOnACPower: Bool
    public var showWindowOnLaunch: Bool

    public init(
        awakeModeEnabled: Bool = true,
        onlyWhenOnACPower: Bool = false,
        showWindowOnLaunch: Bool = true
    ) {
        self.awakeModeEnabled = awakeModeEnabled
        self.onlyWhenOnACPower = onlyWhenOnACPower
        self.showWindowOnLaunch = showWindowOnLaunch
    }

    public static let defaults = AppPreferences()
}
