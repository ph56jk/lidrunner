import Foundation

public enum ClosedLidStatus: Equatable {
    case enabled
    case disabled
    case notReported

    public var title: String {
        switch self {
        case .enabled:
            return "Enabled"
        case .disabled:
            return "Disabled"
        case .notReported:
            return "Not reported"
        }
    }
}
