// swift-tools-version: 5.10
// Lean manifest: crypto + ticket + RPC unit tests without protoncore-heavy DiodeConnection.
// Used by scripts/test-diode-lean.sh

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
    ],
    dependencies: [
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift", from: "0.21.0"),
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
