// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "notification_master",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "notification-master", targets: ["notification_master"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "notification_master",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
