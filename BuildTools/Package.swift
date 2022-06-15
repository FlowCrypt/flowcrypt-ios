// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "BuildTools",
    platforms: [.macOS(.v10_11)],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.49.9"),
    ],
    targets: [.target(name: "BuildTools", path: "")]
)
