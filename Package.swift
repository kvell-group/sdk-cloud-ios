// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "KvellSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "KvellSDK",
            targets: ["Kvell"]
        ),
        .library(
            name: "KvellNetworking",
            targets: ["KvellNetworking"]
        )
    ],
    targets: [
        .target(
            name: "Kvell",
            dependencies: [
                "KvellNetworking"
            ],
            path: "sdk",
            exclude: [
                "Pods",
                "sdk-Bridging-Header.h"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "KvellNetworking",
            path: "networking",
            sources: ["source"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
