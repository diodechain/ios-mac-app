//
//  DiodeConnectionStatusMapper.swift
//  DiodeConnection
//

import DiodeNetwork
import Domain
import Foundation
import VPNAppCore

/// Maps Diode connect phases and nodes to [VPNConnectionStatus] for `connectionBridge.pushStatus`.
public enum DiodeConnectionStatusMapper {
    public enum Phase: Equatable, Sendable {
        case connecting
        case connected
        case disconnecting
        case disconnected
    }

    public static func server(from node: VpnNode) -> Server {
        let country = (node.country ?? "XX").uppercased()
        let displayName = node.name ?? node.host
        let logical = Logical(
            id: node.nodeIdHex,
            name: displayName,
            domain: node.host,
            load: 0,
            entryCountryCode: country,
            exitCountryCode: country,
            tier: 2,
            score: 1,
            status: 1,
            feature: .zero,
            city: node.city,
            state: nil,
            hostCountry: nil,
            translatedCity: node.city,
            latitude: node.latitude ?? 0,
            longitude: node.longitude ?? 0,
            gatewayName: nil
        )
        let endpoint = ServerEndpoint(
            id: "\(node.nodeIdHex)#\(node.host)",
            entryIp: nil,
            exitIp: node.host,
            domain: node.host,
            status: 1,
            label: nil,
            x25519PublicKey: nil,
            protocolEntries: nil
        )
        return Server(logical: logical, endpoint: endpoint)
    }

    public static func vpnConnectionStatus(
        phase: Phase,
        spec: ConnectionSpec,
        node: VpnNode?,
        connectedDate: Date = Date()
    ) -> VPNConnectionStatus {
        switch phase {
        case .connecting:
            let server = node.map(server(from:))
            return .connecting(spec, server)

        case .connected:
            guard let node else {
                return .disconnected
            }
            let actual = VPNConnectionActual(
                connectedDate: connectedDate,
                vpnProtocol: .wireGuard(.udp),
                natType: .moderateNAT,
                safeMode: nil,
                server: server(from: node)
            )
            return .connected(spec, actual)

        case .disconnecting:
            let actual = node.map {
                VPNConnectionActual(
                    connectedDate: connectedDate,
                    vpnProtocol: .wireGuard(.udp),
                    natType: .moderateNAT,
                    safeMode: nil,
                    server: server(from: $0)
                )
            }
            return .disconnecting(spec, actual)

        case .disconnected:
            return .disconnected
        }
    }
}
