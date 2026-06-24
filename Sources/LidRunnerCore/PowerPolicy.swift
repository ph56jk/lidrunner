import Foundation

public enum PowerPolicyDecision: Equatable {
    case runAssertions
    case disabledByPreference
    case blockedByPowerSource

    public var title: String {
        switch self {
        case .runAssertions:
            return "Running"
        case .disabledByPreference:
            return "Off"
        case .blockedByPowerSource:
            return "Paused"
        }
    }
}

public enum PowerPolicy {
    public static func decision(preferences: AppPreferences, powerSource: PowerSource) -> PowerPolicyDecision {
        guard preferences.awakeModeEnabled else { return .disabledByPreference }

        if preferences.onlyWhenOnACPower && powerSource != .acPower {
            return .blockedByPowerSource
        }

        return .runAssertions
    }
}
