import Foundation
import IOKit.pwr_mgt
import os

public enum PowerError: LocalizedError {
    case assertionFailed(String, IOReturn)

    public var errorDescription: String? {
        switch self {
        case let .assertionFailed(name, code):
            return "Could not create \(name) assertion. IOKit returned \(code)."
        }
    }
}

public final class PowerManager {
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "power")
    private var idleAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
    private var activityToken: NSObjectProtocol?

    public init() {}

    public var isAwake: Bool {
        idleAssertionID != kIOPMNullAssertionID
    }

    public func start() throws {
        guard !isAwake else { return }

        do {
            idleAssertionID = try createAssertion(
                type: kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
                name: "idle sleep"
            )
            activityToken = ProcessInfo.processInfo.beginActivity(
                options: [
                    .idleSystemSleepDisabled,
                    .suddenTerminationDisabled,
                    .automaticTerminationDisabled
                ],
                reason: AppInfo.awakeReason
            )
            logger.info("Awake assertions started")
        } catch {
            stop()
            throw error
        }
    }

    public func stop() {
        releaseAssertion(&idleAssertionID)

        if let activityToken {
            ProcessInfo.processInfo.endActivity(activityToken)
            self.activityToken = nil
        }

        logger.info("Awake assertions stopped")
    }

    private func createAssertion(type: CFString, name: String) throws -> IOPMAssertionID {
        var assertionID = IOPMAssertionID(kIOPMNullAssertionID)
        let result = IOPMAssertionCreateWithName(
            type,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "\(AppInfo.name): prevent \(name)" as CFString,
            &assertionID
        )

        guard result == kIOReturnSuccess else {
            throw PowerError.assertionFailed(name, result)
        }

        return assertionID
    }

    private func releaseAssertion(_ assertionID: inout IOPMAssertionID) {
        guard assertionID != kIOPMNullAssertionID else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = IOPMAssertionID(kIOPMNullAssertionID)
    }
}
