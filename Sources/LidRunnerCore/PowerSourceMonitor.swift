import Foundation
import IOKit.ps
import os

public final class PowerSourceMonitor {
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "power-source")
    private var runLoopSource: CFRunLoopSource?

    public var onChange: ((PowerSource) -> Void)?

    public init() {}

    deinit {
        stop()
    }

    public func start() {
        guard runLoopSource == nil else {
            onChange?(currentPowerSource())
            return
        }

        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let monitor = Unmanaged<PowerSourceMonitor>.fromOpaque(context).takeUnretainedValue()
            monitor.notifyChange()
        }, context)?.takeRetainedValue() else {
            logger.error("Could not create IOPS notification run loop source")
            onChange?(currentPowerSource())
            return
        }

        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        onChange?(currentPowerSource())
    }

    public func stop() {
        guard let source = runLoopSource else { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        runLoopSource = nil
    }

    public func currentPowerSource() -> PowerSource {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sourceType = IOPSGetProvidingPowerSourceType(snapshot)?.takeUnretainedValue() as String?
        else {
            return .unknown
        }

        return PowerSource.classify(providingPowerSourceType: sourceType)
    }

    private func notifyChange() {
        onChange?(currentPowerSource())
    }
}
