import Foundation
import ServiceManagement

public enum LoginItemStatus: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case notFound
    case unavailable

    public var title: String {
        switch self {
        case .enabled:
            return "Enabled"
        case .disabled:
            return "Disabled"
        case .requiresApproval:
            return "Requires approval"
        case .notFound:
            return "Not found"
        case .unavailable:
            return "Unavailable"
        }
    }
}

public enum LoginItemError: LocalizedError {
    case unavailable

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Launch at login requires macOS 13 or newer."
        }
    }
}

public struct LoginItemService {
    public init() {}

    public var status: LoginItemStatus {
        guard #available(macOS 13.0, *) else { return .unavailable }

        switch SMAppService.mainApp.status {
        case .enabled:
            return .enabled
        case .notRegistered:
            return .disabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .notFound
        @unknown default:
            return .unavailable
        }
    }

    public func setEnabled(_ enabled: Bool) throws {
        guard #available(macOS 13.0, *) else { throw LoginItemError.unavailable }

        if enabled {
            guard SMAppService.mainApp.status != .enabled else { return }
            try SMAppService.mainApp.register()
        } else {
            guard SMAppService.mainApp.status != .notRegistered else { return }
            try SMAppService.mainApp.unregister()
        }
    }
}
