// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ProtonShims",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
    ],
    products: [
        .library(name: "ProtonCoreFeatureFlags", targets: ["ProtonCoreFeatureFlags"]),
        .library(name: "ProtonCoreUIFoundations", targets: ["ProtonCoreUIFoundations"]),
        .library(name: "ProtonCoreNetworking", targets: ["ProtonCoreNetworking"]),
        .library(name: "ProtonCoreServices", targets: ["ProtonCoreServices"]),
        .library(name: "ProtonCoreUtilities", targets: ["ProtonCoreUtilities"]),
        .library(name: "ProtonCoreAuthentication", targets: ["ProtonCoreAuthentication"]),
        .library(name: "GoLibsCryptoVPNPatchedGo", targets: ["GoLibs"]),
        .library(name: "ProtonCoreCryptoVPNPatchedGoImplementation", targets: ["ProtonCoreCryptoVPNPatchedGoImplementation"]),
        .library(name: "ProtonCoreAPIClient", targets: ["ProtonCoreAPIClient"]),
        .library(name: "ProtonCoreDataModel", targets: ["ProtonCoreDataModel"]),
        .library(name: "ProtonCoreDoh", targets: ["ProtonCoreDoh"]),
        .library(name: "ProtonCoreEnvironment", targets: ["ProtonCoreEnvironment"]),
        .library(name: "ProtonCoreFoundations", targets: ["ProtonCoreFoundations"]),
        .library(name: "ProtonCoreLogin", targets: ["ProtonCoreLogin"]),
        .library(name: "ProtonCoreLoginUI", targets: ["ProtonCoreLoginUI"]),
        .library(name: "ProtonCorePayments", targets: ["ProtonCorePayments"]),
        .library(name: "ProtonCorePaymentsV2", targets: ["ProtonCorePaymentsV2"]),
        .library(name: "ProtonCorePaymentsUIV2", targets: ["ProtonCorePaymentsUIV2"]),
        .library(name: "ProtonCoreTelemetry", targets: ["ProtonCoreTelemetry"]),
        .library(name: "ProtonCorePushNotifications", targets: ["ProtonCorePushNotifications"]),
        .library(name: "ProtonCoreHumanVerification", targets: ["ProtonCoreHumanVerification"]),
        .library(name: "ProtonCoreLog", targets: ["ProtonCoreLog"]),
        .library(name: "ProtonCoreObservability", targets: ["ProtonCoreObservability"]),
        .library(name: "ProtonCoreForceUpgrade", targets: ["ProtonCoreForceUpgrade"]),
        .library(name: "ProtonCoreAccountDeletion", targets: ["ProtonCoreAccountDeletion"]),
        .library(name: "ProtonCoreAccountRecovery", targets: ["ProtonCoreAccountRecovery"]),
        .library(name: "ProtonCorePasswordChange", targets: ["ProtonCorePasswordChange"]),
        .library(name: "ProtonCoreTestingToolkitUnitTestsCore", targets: ["ProtonCoreTestingToolkitUnitTestsCore"]),
        .library(name: "ProtonCoreTestingToolkitUnitTestsFeatureFlag", targets: ["ProtonCoreTestingToolkitUnitTestsFeatureFlag"]),
        .library(name: "ProtonCoreTestingToolkitPerformance", targets: ["ProtonCoreTestingToolkitPerformance"]),
        .library(name: "ProtonCoreChallenge", targets: ["ProtonCoreChallenge"]),
    ],
    targets: [
        .target(name: "ProtonCoreUtilities"),
        .target(
            name: "ProtonCoreServices",
            dependencies: ["ProtonCoreDoh"]
        ),
        .target(
            name: "ProtonCoreFeatureFlags",
            dependencies: ["ProtonCoreServices", "ProtonCoreUtilities"]
        ),
        .target(
            name: "ProtonCoreUIFoundations"
        ),
        .target(
            name: "ProtonCoreAuthentication",
            dependencies: ["ProtonCoreServices", "ProtonCoreNetworking", "ProtonCoreDataModel"]
        ),
        .target(
            name: "ProtonCoreNetworking",
            dependencies: [
                "ProtonCoreAPIClient",
                "ProtonCoreServices",
                "ProtonCoreUtilities",
                "ProtonCoreDoh",
                "ProtonCoreFoundations",
            ]
        ),
        .target(name: "GoLibs"),
        .target(
            name: "ProtonCoreCryptoVPNPatchedGoImplementation",
            dependencies: ["GoLibs"]
        ),
        .target(name: "ProtonCoreAPIClient"),
        .target(name: "ProtonCoreDataModel"),
        .target(name: "ProtonCoreDoh"),
        .target(
            name: "ProtonCoreEnvironment",
            dependencies: ["ProtonCoreDoh"]
        ),
        .target(
            name: "ProtonCoreFoundations",
            dependencies: ["ProtonCoreChallenge", "ProtonCoreServices"]
        ),
        .target(name: "ProtonCorePayments"),
        .target(
            name: "ProtonCoreLogin",
            dependencies: [
                "ProtonCoreNetworking",
                "ProtonCoreServices",
                "ProtonCoreDataModel",
            ]
        ),
        .target(
            name: "ProtonCoreLoginUI",
            dependencies: [
                "ProtonCoreLogin",
                "ProtonCoreNetworking",
                "ProtonCorePayments",
                "ProtonCoreServices",
                "ProtonCoreUIFoundations",
            ]
        ),
        .target(
            name: "ProtonCorePaymentsV2",
            dependencies: [
                "ProtonCoreNetworking",
                "ProtonCoreServices",
            ]
        ),
        .target(
            name: "ProtonCorePaymentsUIV2",
            dependencies: [
                "ProtonCorePaymentsV2",
                "ProtonCoreUIFoundations",
            ]
        ),
        .target(
            name: "ProtonCoreTelemetry",
            dependencies: ["ProtonCoreServices"]
        ),
        .target(
            name: "ProtonCorePushNotifications",
            dependencies: ["ProtonCoreServices"]
        ),
        .target(
            name: "ProtonCoreHumanVerification",
            dependencies: [
                "ProtonCoreNetworking",
                "ProtonCoreServices",
                "ProtonCoreLogin",
            ]
        ),
        .target(name: "ProtonCoreLog"),
        .target(
            name: "ProtonCoreObservability",
            dependencies: ["ProtonCoreNetworking"]
        ),
        .target(
            name: "ProtonCoreForceUpgrade",
            dependencies: ["ProtonCoreNetworking"]
        ),
        .target(
            name: "ProtonCoreAccountDeletion",
            dependencies: [
                "ProtonCoreNetworking",
                "ProtonCoreServices",
            ]
        ),
        .target(
            name: "ProtonCoreAccountRecovery",
            dependencies: [
                "ProtonCoreFeatureFlags",
                "ProtonCoreNetworking",
                "ProtonCoreDataModel",
                "ProtonCoreUIFoundations",
            ]
        ),
        .target(
            name: "ProtonCorePasswordChange",
            dependencies: [
                "ProtonCoreFeatureFlags",
                "ProtonCoreNetworking",
                "ProtonCoreDataModel",
            ]
        ),
        .target(name: "ProtonCoreTestingToolkitUnitTestsCore"),
        .target(
            name: "ProtonCoreTestingToolkitUnitTestsFeatureFlag",
            dependencies: ["ProtonCoreFeatureFlags"]
        ),
        .target(name: "ProtonCoreTestingToolkitPerformance"),
        .target(name: "ProtonCoreChallenge"),
    ]
)
