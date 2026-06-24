import Foundation
import LidRunnerCore
import os
import Security

private let logger = Logger(subsystem: AppInfo.daemonBundleIdentifier, category: "daemon")

private final class DaemonService: NSObject, LidRunnerDaemonProtocol {
    private let pmset = PMSetService()

    func setClosedLidMode(_ enabled: Bool, withReply reply: @escaping (Bool, String?) -> Void) {
        do {
            try pmset.setClosedLidModeDirect(enabled: enabled)
            reply(true, nil)
        } catch {
            logger.error("Failed to set closed-lid mode: \(error.localizedDescription, privacy: .public)")
            reply(false, error.localizedDescription)
        }
    }

    func readClosedLidStatus(withReply reply: @escaping (String) -> Void) {
        reply(pmset.readClosedLidStatus().rawValue)
    }
}

private final class ListenerDelegate: NSObject, NSXPCListenerDelegate {
    private let service = DaemonService()

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        guard ClientValidator.isAllowed(connection) else {
            logger.error("Rejected XPC client with pid \(connection.processIdentifier)")
            return false
        }

        connection.exportedInterface = NSXPCInterface(with: LidRunnerDaemonProtocol.self)
        connection.exportedObject = service
        connection.resume()
        return true
    }
}

private enum ClientValidator {
    static func isAllowed(_ connection: NSXPCConnection) -> Bool {
        var code: SecCode?
        let attributes = [
            kSecGuestAttributePid as String: NSNumber(value: connection.processIdentifier)
        ]

        guard SecCodeCopyGuestWithAttributes(nil, attributes as CFDictionary, SecCSFlags(), &code) == errSecSuccess,
              let code else {
            return false
        }

        var requirement: SecRequirement?
        let requirementText = "identifier \"\(AppInfo.bundleIdentifier)\""
        guard SecRequirementCreateWithString(requirementText as CFString, SecCSFlags(), &requirement) == errSecSuccess,
              let requirement else {
            return false
        }

        return SecCodeCheckValidity(code, SecCSFlags(), requirement) == errSecSuccess
    }
}

private let delegate = ListenerDelegate()
private let listener = NSXPCListener(machServiceName: AppInfo.daemonBundleIdentifier)
listener.delegate = delegate
listener.resume()
logger.info("LidRunner daemon started")
RunLoop.main.run()
