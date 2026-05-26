// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DisturbBlocker",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "DisturbBlockerCore", targets: ["DisturbBlockerCore"]),
        .executable(name: "DisturbBlocker", targets: ["DisturbBlocker"]),
        .executable(name: "DisturbBlockerCoreCheck", targets: ["DisturbBlockerCoreCheck"])
    ],
    targets: [
        .target(
            name: "DisturbBlockerCore",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .executableTarget(
            name: "DisturbBlocker",
            dependencies: ["DisturbBlockerCore"],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .executableTarget(
            name: "DisturbBlockerCoreCheck",
            dependencies: ["DisturbBlockerCore"]
        )
    ]
)
