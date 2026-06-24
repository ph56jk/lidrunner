import Foundation
import IOKit
import os

public final class LidStateMonitor {
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "lid-state")
    private var timer: Timer?
    private var lastState: LidState?

    public var onChange: ((LidState) -> Void)?

    public init() {}

    deinit {
        stop()
    }

    public func start(interval: TimeInterval = 1.0) {
        guard timer == nil else {
            onChange?(currentLidState())
            return
        }

        lastState = currentLidState()
        onChange?(lastState ?? .unknown)

        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        lastState = nil
    }

    public func currentLidState() -> LidState {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceNameMatching("IOPMrootDomain")
        )

        guard service != IO_OBJECT_NULL else {
            logger.error("Could not find IOPMrootDomain for lid-state detection")
            return .unknown
        }

        defer { IOObjectRelease(service) }

        let value = IORegistryEntryCreateCFProperty(
            service,
            "AppleClamshellState" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue()

        return LidState.classify(appleClamshellState: value)
    }

    private func poll() {
        let state = currentLidState()
        guard state != lastState else { return }
        lastState = state
        onChange?(state)
    }
}
