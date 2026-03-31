// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MultandoSDK",
    platforms: [
        .iOS(.v16)
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
            path: "Sources/MultandoSDK"
        ),
        .testTarget(
            name: "MultandoSDKTests",
            dependencies: ["MultandoSDK"]
        )
    ]
)
