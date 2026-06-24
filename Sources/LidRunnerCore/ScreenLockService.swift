import Foundation
import os

public enum ScreenLockError: LocalizedError {
    case launchFailed(Error)
    case commandFailed(String, Int32, String)

    public var errorDescription: String? {
        switch self {
        case let .launchFailed(error):
            return error.localizedDescription
        case let .commandFailed(action, status, output):
            if output.isEmpty {
                return "\(action) failed with exit code \(status)."
            }
            return output
        }
    }
}

public struct ScreenLockService {
    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "screen-lock")

    public init() {}

    public func lockScreen() throws {
        let result = runProcess(
            "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession",
            arguments: ["-suspend"]
        )

        guard result.status == 0 else {
            throw ScreenLockError.commandFailed("Screen lock", result.status, result.output)
        }

        logger.info("Screen locked")
    }

    public func sleepDisplays() throws {
        let result = runProcess("/usr/bin/pmset", arguments: ["displaysleepnow"])

        guard result.status == 0 else {
            throw ScreenLockError.commandFailed("Display sleep", result.status, result.output)
        }

        logger.info("Displays sent to sleep")
    }

    public func lockScreenAndSleepDisplays() throws {
        try lockScreen()
        Thread.sleep(forTimeInterval: 0.35)
        try sleepDisplays()
    }

    private func runProcess(_ executable: String, arguments: [String]) -> (status: Int32, output: String) {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()

        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return (1, ScreenLockError.launchFailed(error).localizedDescription)
        }

        let output = read(stdout) + read(stderr)
        return (process.terminationStatus, output.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func read(_ pipe: Pipe) -> String {
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
