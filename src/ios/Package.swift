// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "MintReplicaLite",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MintReplicaLite",
            targets: ["MintReplicaLite"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MintReplicaLite",
            dependencies: []
        )
    ]
)