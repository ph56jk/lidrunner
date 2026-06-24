// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LidRunner",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "LidRunner", targets: ["LidRunner"])
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
        .testTarget(
            name: "LidRunnerCoreTests",
            dependencies: ["LidRunnerCore"]
        )
    ]
)
