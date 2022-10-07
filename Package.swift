// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "TaskQueue",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "TaskQueue",
            targets: [
                "TaskQueue",
            ]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TaskQueue",
            dependencies: []
        ),
        .testTarget(
            name: "TaskQueueTests",
            dependencies: [
                "TaskQueue",
            ]
        ),
    ]
)
