// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "aerospace-ffm",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "FFMCore"),
        .executableTarget(name: "aerospace-ffm", dependencies: ["FFMCore"]),
        .testTarget(name: "FFMCoreTests", dependencies: ["FFMCore"]),
    ]
)
