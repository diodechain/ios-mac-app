import DiodeNetwork
import Domain
import Foundation

/// Maps Diode `VpnNode` records into Proton `VPNServer` models for unchanged Countries/Home UI.
public enum DiodeVpnNodeAdapter {
    private static let logicalIDPrefix = "diode-"
    private static let mappingLock = NSLock()
    private static var logicalIDToNodeIDHex: [String: String] = [:]

    public static func toVpnServers(from nodes: [VpnNode]) -> [VPNServer] {
        nodes.map(toVpnServer(from:))
    }

    public static func logicalID(forNodeIDHex nodeIDHex: String) -> String {
        let normalized = normalizedNodeIDHex(nodeIDHex)
        return "\(logicalIDPrefix)\(normalized)"
    }

    public static func nodeIDHex(forLogicalID logicalID: String) -> String? {
        mappingLock.withLock {
            logicalIDToNodeIDHex[logicalID]
        }
    }

    private static func toVpnServer(from node: VpnNode) -> VPNServer {
        let normalizedNodeIDHex = normalizedNodeIDHex(node.nodeIdHex)
        let logicalID = logicalID(forNodeIDHex: normalizedNodeIDHex)
        storeMapping(logicalID: logicalID, nodeIDHex: normalizedNodeIDHex)

        let countryCode = (node.country?.uppercased()).flatMap { $0.isEmpty ? nil : $0 } ?? "XX"
        let displayName = node.name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let serverName = (displayName?.isEmpty == false ? displayName : nil) ?? "\(countryCode)#1"

        let logical = Logical(
            id: logicalID,
            name: serverName,
            domain: node.host,
            load: 0,
            entryCountryCode: countryCode,
            exitCountryCode: countryCode,
            tier: Int.paidTier,
            score: 1.0,
            status: 1,
            feature: [],
            city: node.city,
            state: nil,
            hostCountry: nil,
            translatedCity: node.city,
            latitude: node.latitude ?? 0,
            longitude: node.longitude ?? 0,
            gatewayName: nil
        )

        let endpoint = ServerEndpoint(
            id: "\(logicalID)-wg",
            entryIp: node.host,
            exitIp: node.host,
            domain: node.host,
            status: 1,
            label: "1",
            x25519PublicKey: nil,
            protocolEntries: [
                .wireGuard(.udp): ServerProtocolEntry(
                    ipv4: node.host,
                    ports: [node.wireguardPort]
                ),
            ]
        )

        return VPNServer(logical: logical, endpoints: [endpoint])
    }

    private static func normalizedNodeIDHex(_ nodeIDHex: String) -> String {
        nodeIDHex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "0x", with: "")
    }

    private static func storeMapping(logicalID: String, nodeIDHex: String) {
        mappingLock.withLock {
            logicalIDToNodeIDHex[logicalID] = nodeIDHex
        }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
