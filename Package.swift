// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MasonryGrid",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "MasonryGrid", targets: ["MasonryGrid"]),
    ],
    targets: [
        .target(name: "MasonryGrid"),
        .testTarget(
            name: "MasonryGridTests",
            dependencies: ["MasonryGrid"]
        ),
    ]
)
