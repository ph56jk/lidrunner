import Foundation

public enum AppInfo {
    public static let name = "LidRunner"
    public static let bundleIdentifier = "com.lidrunner.app"
    public static let daemonBundleIdentifier = "com.lidrunner.daemon"
    public static let daemonPlistName = "\(daemonBundleIdentifier).plist"
    public static let daemonExecutableName = "LidRunnerDaemon"
    public static let version = "0.2.4"
    public static let build = "10"

    public static let awakeReason = "\(name) keeps local jobs running"
}
