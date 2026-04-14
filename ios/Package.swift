// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MultandoSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MultandoSDK",
            targets: ["MultandoSDK"]
        )
    ],
    targets: [
        .target(
            name: "MultandoSDK",
            path: "Sources/MultandoSDK",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MultandoSDKTests",
            dependencies: ["MultandoSDK"]
        )
    ]
)
