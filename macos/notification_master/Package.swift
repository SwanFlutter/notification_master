// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "notification_master",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "notification-master", targets: ["notification_master"]),
        .executable(name: "notification_master_poller", targets: ["notification_master_poller"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "notification_master",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        ),
        // Standalone background polling daemon.
        // Built as a separate CLI binary placed next to the app bundle.
        // Uses UNUserNotificationCenter + URLSession — no Flutter dependency.
        .executableTarget(
            name: "notification_master_poller",
            path: "Sources/notification_master_poller"
        )
    ]
)
