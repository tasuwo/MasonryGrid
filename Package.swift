// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MasonryGrid",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(name: "MasonryGrid", targets: ["MasonryGrid"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "MasonryGrid",
            dependencies: [
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ]
        ),
        .testTarget(
            name: "MasonryGridTests",
            dependencies: ["MasonryGrid"]
        ),
    ]
)
