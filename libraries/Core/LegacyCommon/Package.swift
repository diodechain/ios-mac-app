// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LegacyCommon",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "LegacyCommon",
            targets: ["LegacyCommon"]
        ),
        /*
             Future: When SPM decides to be a mature software product, move the Mocks here.
             macOS unit tests refused to link this target, even though every other target
             was fine with it:
            .library(
                name: "LegacyCommonTestSupport",
                targets: ["LegacyCommonTestSupport"]
            ),
             Notes:
              - You may encounter additional problems linking TrustKit (Undefined symbols
                ___llvm_profile_runtime)
              - Moving @Dependency based mocks to a separate module means each of these dependencies
                will have to be overridden in every test where its used (you cannot provide testValue
                in a separate module)
            */
    ],
    dependencies: [
        // External packages regularly upstreamed by our project (imported as submodules)
        .package(path: "../../External/ProtonShims"),

        // Local packages
        .package(path: "../NEHelper"),

        .package(path: "../../Foundations/Domain"),
        .package(path: "../../Foundations/Ergonomics"),
        .package(path: "../../Foundations/PMLogger"),
        .package(path: "../../Foundations/Strings"),
        .package(path: "../../Foundations/Theme"),
        .package(path: "../../Foundations/Timer"),

        .package(path: "../../Shared/DiodeVPN"),
        .package(path: "../../Shared/CommonNetworking"),
        .package(path: "../../Shared/Connection"),
        .package(path: "../../Shared/ExtensionIPC"),
        .package(path: "../../Shared/Localization"),
        .package(path: "../../Shared/Persistence"),
        .package(path: "../../Shared/NATPortMapping"),
        .package(path: "../../Shared/ConnectionInventory"),
        .package(path: "../../Shared/Telemetry"),
        .package(path: "../../Shared/VPNNetworking"),

        .package(path: "../../Features/Modals"),
        .package(path: "../../Features/NetShield"),
        .package(path: "../../Features/Settings"),

        // External dependencies

        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", .upToNextMajor(from: "1.7.0")),
        .package(url: "https://github.com/apple/swift-async-algorithms", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", exact: "4.2.2"),
        .package(url: "https://github.com/pointfreeco/swift-clocks", .upToNextMajor(from: "1.0.5")),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMajor(from: "1.24.1")),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", .upToNextMajor(from: "1.4.1")),
        .package(url: "https://github.com/mxcl/Version", exact: "2.1.0"),
    ],
    targets: [
        .target(
            name: "LegacyCommon",
            dependencies: [
                // Local
                "Domain",
                "Connection",
                .product(name: "DiodeConnection", package: "DiodeVPN"),
                "Ergonomics",
                "PMLogger",
                "Strings",
                "Theme",
                "Timer",
                "Telemetry",
                "VPNNetworking",
                .product(name: "Persistence", package: "Persistence"),
                "Localization",

                .product(name: "Hermes", package: "Connection"),

                "ExtensionIPC",
                "CommonNetworking",
                .product(name: "VPNShared", package: "NEHelper"),
                .product(name: "VPNAppCore", package: "NEHelper"),
                .product(name: "VPNCrypto", package: "NEHelper"),
                .product(name: "NATPMPUI", package: "NATPortMapping", condition: .when(platforms: [.macOS])),

                "NetShield",
                "Modals",
                "Settings",
                "ConnectionInventory",

                // TODO: move these to LegacyCommonTestSupport, if we ever can
                .product(name: "CommonNetworkingTestSupport", package: "CommonNetworking"),
                .product(name: "VPNSharedTesting", package: "NEHelper"),
                .product(name: "TimerMock", package: "Timer"),

                // Core code
                .product(name: "ProtonCoreAuthentication", package: "ProtonShims"),
                .product(name: "ProtonCoreDataModel", package: "ProtonShims"),
                .product(name: "ProtonCoreEnvironment", package: "ProtonShims"),
                .product(name: "ProtonCoreFeatureFlags", package: "ProtonShims"),
                .product(name: "ProtonCoreLogin", package: "ProtonShims"),
                .product(name: "ProtonCoreNetworking", package: "ProtonShims"),
                .product(name: "ProtonCorePushNotifications", package: "ProtonShims"),
                .product(name: "ProtonCoreServices", package: "ProtonShims"),
                .product(name: "ProtonCoreTelemetry", package: "ProtonShims"),
                .product(name: "ProtonCoreUIFoundations", package: "ProtonShims"),
                .product(name: "ProtonCoreUtilities", package: "ProtonShims"),
                .product(name: "GoLibsCryptoVPNPatchedGo", package: "ProtonShims"),

                // External
                "Version",
                .product(name: "Clocks", package: "swift-clocks"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
            ],
        ),
        /*
            .target(
                name: "LegacyCommonTestSupport",
                dependencies: [
                    "LegacyCommon",
                    "Strings",
                    "Home",
                    .product(name: "CommonNetworkingTestSupport", package: "CommonNetworking"),
                    .product(name: "TimerMock", package: "Timer"),
                    .product(name: "VPNAppCore", package: "NEHelper"),
                    .product(name: "VPNShared", package: "NEHelper"),
                    .product(name: "VPNSharedTesting", package: "NEHelper"),

                    .product(name: "GoLibsCryptoVPNPatchedGo", package: "ProtonShims"),
                    .product(name: "ProtonCoreAuthentication", package: "ProtonShims"),
                    .product(name: "ProtonCoreDataModel", package: "ProtonShims"),
                    .product(name: "ProtonCoreFoundations", package: "ProtonShims"),
                    .product(name: "ProtonCoreNetworking", package: "ProtonShims"),
                    .product(name: "ProtonCoreServices", package: "ProtonShims"),
                ]
            ),
            */
        .testTarget(
            name: "LegacyCommonTests",
            dependencies: [
                "LegacyCommon",
                .product(name: "DomainTestSupport", package: "Domain"),
                .product(name: "PersistenceTestSupport", package: "Persistence"),
                .product(name: "ProtonCoreTestingToolkitUnitTestsCore", package: "ProtonShims"),
                .product(name: "ProtonCoreTestingToolkitUnitTestsFeatureFlag", package: "ProtonShims"),
            ]
        ),
    ]
)
