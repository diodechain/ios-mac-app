//
//  DiodeWireGuardSession.swift
//  ProtonVPN
//
//  Copyright (c) 2026 Proton Technologies AG
//

import Foundation

public struct DiodeWireGuardSession: Sendable, Equatable {
    public let serverPublicKey: String
    public let endpointHost: String
    public let listenPort: Int
    public let clientAddress: String

    public init(
        serverPublicKey: String,
        endpointHost: String,
        listenPort: Int,
        clientAddress: String
    ) {
        self.serverPublicKey = serverPublicKey
        self.endpointHost = endpointHost
        self.listenPort = listenPort
        self.clientAddress = clientAddress
    }
}
