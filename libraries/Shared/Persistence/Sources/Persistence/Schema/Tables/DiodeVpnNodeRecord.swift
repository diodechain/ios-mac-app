//
//  Copyright (c) 2026 Diode

import Foundation

/// Neutral persisted representation of a Diode VPN directory node (mirrors Android `ServerDatabase` row).
public struct DiodeVpnNodeRecord: Codable, Equatable, Sendable {
    public let nodeIdHex: String
    public let host: String
    public let name: String?
    public let latitude: Double?
    public let longitude: Double?
    public let city: String?
    public let country: String?
    public let wsRpcUrlOverride: String?
    public let httpRpcUrlOverride: String?
    public let updatedAt: Int64

    public init(
        nodeIdHex: String,
        host: String,
        name: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        city: String? = nil,
        country: String? = nil,
        wsRpcUrlOverride: String? = nil,
        httpRpcUrlOverride: String? = nil,
        updatedAt: Int64
    ) {
        self.nodeIdHex = nodeIdHex
        self.host = host
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.city = city
        self.country = country
        self.wsRpcUrlOverride = wsRpcUrlOverride
        self.httpRpcUrlOverride = httpRpcUrlOverride
        self.updatedAt = updatedAt
    }
}

/// Last connect failure timestamp per node (survives server list `replaceAll`).
public struct DiodeVpnConnectFailureRecord: Codable, Equatable, Sendable {
    public let nodeIdHex: String
    public let failedAt: Int64

    public init(nodeIdHex: String, failedAt: Int64) {
        self.nodeIdHex = nodeIdHex
        self.failedAt = failedAt
    }
}
