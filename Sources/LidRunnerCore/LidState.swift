import Foundation

public enum LidState: Equatable {
    case open
    case closed
    case unknown

    public var title: String {
        switch self {
        case .open:
            return "Open"
        case .closed:
            return "Closed"
        case .unknown:
            return "Unknown"
        }
    }

    public static func classify(appleClamshellState: Any?) -> LidState {
        guard let appleClamshellState else { return .unknown }

        if let isClosed = appleClamshellState as? Bool {
            return isClosed ? .closed : .open
        }

        if let number = appleClamshellState as? NSNumber {
            return number.boolValue ? .closed : .open
        }

        return .unknown
    }
}
