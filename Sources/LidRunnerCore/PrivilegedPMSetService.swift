import Foundation
import ServiceManagement

public enum PrivilegedHelperStatus: Equatable {
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

public enum PrivilegedPMSetError: LocalizedError {
    case unavailable
    case notEnabled(PrivilegedHelperStatus)
    case noProxy
    case timedOut
    case daemonRejected(String)

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return "The privileged helper requires macOS 13 or newer."
        case let .notEnabled(status):
            return "The privileged helper is \(status.title.lowercased())."
        case .noProxy:
            return "Could not connect to the privileged helper."
        case .timedOut:
            return "The privileged helper did not respond in time."
        case let .daemonRejected(message):
            return message
        }
    }
}

public struct PrivilegedPMSetService {
    public init() {}

    public var status: PrivilegedHelperStatus {
        guard #available(macOS 13.0, *) else { return .unavailable }

        switch service.status {
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

    public func register() throws {
        guard #available(macOS 13.0, *) else { throw PrivilegedPMSetError.unavailable }
        guard service.status != .enabled else { return }
        try service.register()
    }

    public func unregister() throws {
        guard #available(macOS 13.0, *) else { throw PrivilegedPMSetError.unavailable }
        guard service.status != .notRegistered else { return }
        try service.unregister()
    }

    public func setClosedLidMode(enabled: Bool) throws {
        guard status == .enabled else { throw PrivilegedPMSetError.notEnabled(status) }

        try withDaemonProxy { proxy, finish in
            proxy.setClosedLidMode(enabled) { success, message in
                if success {
                    finish(.success(()))
                } else {
                    finish(.failure(PrivilegedPMSetError.daemonRejected(message ?? "The privileged helper rejected the command.")))
                }
            }
        }
    }

    public func readClosedLidStatus() throws -> ClosedLidStatus {
        guard status == .enabled else { throw PrivilegedPMSetError.notEnabled(status) }

        return try withDaemonProxy { proxy, finish in
            proxy.readClosedLidStatus { rawStatus in
                finish(.success(ClosedLidStatus(rawValue: rawStatus) ?? .notReported))
            }
        }
    }

    @available(macOS 13.0, *)
    private var service: SMAppService {
        .daemon(plistName: AppInfo.daemonPlistName)
    }

    private func withDaemonProxy<T>(
        _ body: (LidRunnerDaemonProtocol, @escaping (Result<T, Error>) -> Void) -> Void
    ) throws -> T {
        let connection = NSXPCConnection(
            machServiceName: AppInfo.daemonBundleIdentifier,
            options: .privileged
        )
        connection.remoteObjectInterface = NSXPCInterface(with: LidRunnerDaemonProtocol.self)

        let semaphore = DispatchSemaphore(value: 0)
        let lock = NSLock()
        var result: Result<T, Error>?

        func finish(_ newResult: Result<T, Error>) {
            lock.lock()
            if result == nil {
                result = newResult
                semaphore.signal()
            }
            lock.unlock()
        }

        let proxy = connection.remoteObjectProxyWithErrorHandler { error in
            finish(.failure(error))
        } as? LidRunnerDaemonProtocol

        guard let proxy else {
            connection.invalidate()
            throw PrivilegedPMSetError.noProxy
        }

        connection.resume()
        body(proxy, finish)

        guard semaphore.wait(timeout: .now() + 5) == .success else {
            connection.invalidate()
            throw PrivilegedPMSetError.timedOut
        }

        connection.invalidate()
        return try result!.get()
    }
}
