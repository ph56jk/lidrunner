// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LidRunner",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "LidRunner", targets: ["LidRunner"]),
        .executable(name: "LidRunnerDaemon", targets: ["LidRunnerDaemon"])
    ],
    targets: [
        .target(
            name: "LidRunnerCore",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .executableTarget(
            name: "LidRunner",
            dependencies: ["LidRunnerCore"],
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        ),
        .executableTarget(
            name: "LidRunnerDaemon",
            dependencies: ["LidRunnerCore"],
            linkerSettings: [
                .linkedFramework("Security")
            ]
        ),
        .testTarget(
            name: "LidRunnerCoreTests",
            dependencies: ["LidRunnerCore"]
        )
    ]
)
