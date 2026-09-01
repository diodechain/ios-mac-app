// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CommonNetworking",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
    ],
    products: [
        .library(name: "CommonNetworking", targets: ["CommonNetworking"]),
        .library(name: "CommonNetworkingTestSupport", targets: ["CommonNetworkingTestSupport"]),
    ],
    dependencies: [
        .package(path: "../../External/ProtonShims"),

        .package(path: "../Localization"),
        .package(path: "../Persistence"),
        .package(path: "../ExtensionIPC"),

        .package(path: "../../Foundations/PMLogger"),
        .package(path: "../../Foundations/Domain"),
        .package(path: "../../Foundations/Ergonomics"),
        .package(path: "../../Foundations/Strings"),

        .package(path: "../../Core/NEHelper"),

        .package(url: "https://github.com/ProtonMail/TrustKit", revision: "d107d7cc825f38ae2d6dc7c54af71d58145c3506"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", .upToNextMajor(from: "1.4.1")),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", .upToNextMajor(from: "1.7.0")),
    ],
    targets: [
        .target(
            name: "CommonNetworking",
            dependencies: [
                "PMLogger",
                "Domain",
                "Ergonomics",
                "Localization",
                "Persistence",
                "Strings",
                "ExtensionIPC",
                .product(name: "NEHelper", package: "NEHelper"),
                .product(name: "VPNAppCore", package: "NEHelper"), // UnauthKeychain
                .product(name: "VPNShared", package: "NEHelper"), // AuthKeychain

                // Core/Accounts
                .product(name: "ProtonCoreAPIClient", package: "ProtonShims"),
                .product(name: "ProtonCoreAuthentication", package: "ProtonShims"),
                .product(name: "ProtonCoreDataModel", package: "ProtonShims"),
                .product(name: "ProtonCoreDoh", package: "ProtonShims"),
                .product(name: "ProtonCoreEnvironment", package: "ProtonShims"),
                .product(name: "ProtonCoreFeatureFlags", package: "ProtonShims"),
                .product(name: "ProtonCoreFoundations", package: "ProtonShims"),
                .product(name: "ProtonCoreNetworking", package: "ProtonShims"),
                .product(name: "ProtonCoreServices", package: "ProtonShims"),
                .product(name: "ProtonCoreUtilities", package: "ProtonShims"),

                // External
                .product(name: "TrustKit", package: "TrustKit"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
            ]
        ),
        .target(
            name: "CommonNetworkingTestSupport",
            dependencies: [
                "CommonNetworking",
            ]
        ),
        .testTarget(
            name: "CommonNetworkingTests",
            dependencies: ["CommonNetworking"],
            resources: [
                .copy("Resources/test_log_1.log"),
                .copy("Resources/test_log_2.log"),
            ]
        ),
    ]
)
