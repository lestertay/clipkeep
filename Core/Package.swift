// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClipKeepCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "ClipKeepCore", targets: ["ClipKeepCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "ClipKeepCore",
            dependencies: [.product(name: "GRDB", package: "GRDB.swift")]
        ),
        .testTarget(
            name: "ClipKeepCoreTests",
            dependencies: ["ClipKeepCore"]
        ),
    ]
)
