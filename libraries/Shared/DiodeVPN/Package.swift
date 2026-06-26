// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "DiodeVPN",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "DiodeCrypto", targets: ["DiodeCrypto"]),
        .library(name: "DiodeTicket", targets: ["DiodeTicket"]),
        .library(name: "DiodeNetwork", targets: ["DiodeNetwork"]),
        .library(name: "DiodeRPC", targets: ["DiodeRPC"]),
        .library(name: "DiodeConnection", targets: ["DiodeConnection"]),
    ],
    dependencies: [
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift", from: "0.21.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.4.0"),
        .package(path: "../../Foundations/Domain"),
        .package(path: "../Connection"),
        .package(path: "../../Core/NEHelper"),
    ],
    targets: [
        .target(
            name: "DiodeCrypto",
            dependencies: [
                .product(name: "P256K", package: "secp256k1.swift"),
            ],
            path: "Sources/DiodeCrypto"
        ),
        .target(
            name: "DiodeTicket",
            dependencies: ["DiodeCrypto"],
            path: "Sources/DiodeTicket"
        ),
        .target(
            name: "DiodeNetwork",
            dependencies: [
                "DiodeCrypto",
                "DiodeTicket",
            ],
            path: "Sources/DiodeNetwork"
        ),
        .target(
            name: "DiodeRPC",
            dependencies: ["DiodeNetwork", "DiodeTicket", "DiodeCrypto"],
            path: "Sources/DiodeRPC"
        ),
        .target(
            name: "DiodeConnection",
            dependencies: [
                "DiodeCrypto",
                "DiodeTicket",
                "DiodeNetwork",
                "DiodeRPC",
                "Domain",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Connection", package: "Connection"),
                .product(name: "VPNAppCore", package: "NEHelper"),
            ],
            path: "Sources/DiodeConnection"
        ),
        .testTarget(
            name: "DiodeConnectionTests",
            dependencies: ["DiodeConnection", "DiodeNetwork", "DiodeCrypto", "DiodeTicket", "Domain"],
            path: "Tests/DiodeConnectionTests"
        ),
        .testTarget(
            name: "DiodeTicketTests",
            dependencies: ["DiodeTicket", "DiodeCrypto"],
            path: "Tests/DiodeTicketTests"
        ),
        .testTarget(
            name: "DiodeRPCTests",
            dependencies: ["DiodeRPC", "DiodeNetwork"],
            path: "Tests/DiodeRPCTests"
        ),
    ]
)
