import Foundation
import IOKit.ps

public enum PowerSource: Equatable {
    case acPower
    case batteryPower
    case upsPower
    case unknown

    public var title: String {
        switch self {
        case .acPower:
            return "Charger"
        case .batteryPower:
            return "Battery"
        case .upsPower:
            return "UPS"
        case .unknown:
            return "Unknown"
        }
    }

    public static func classify(providingPowerSourceType value: String?) -> PowerSource {
        switch value {
        case kIOPMACPowerKey:
            return .acPower
        case kIOPMBatteryPowerKey:
            return .batteryPower
        case kIOPMUPSPowerKey:
            return .upsPower
        default:
            return .unknown
        }
    }
}
