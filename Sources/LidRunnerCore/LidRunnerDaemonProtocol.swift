import Foundation

@objc public protocol LidRunnerDaemonProtocol {
    func setClosedLidMode(_ enabled: Bool, withReply reply: @escaping (Bool, String?) -> Void)
    func readClosedLidStatus(withReply reply: @escaping (String) -> Void)
}
