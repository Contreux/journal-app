// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "journal-app",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "journal-app",
            targets: ["journal-app"]),
    ],
    dependencies: [
        // No external dependencies needed - using native SwiftData, Speech framework
    ],
    targets: [
        .target(
            name: "journal-app",
            dependencies: []),
    ]
)
