import DiodeCrypto
import Foundation

/// Parsed VPN-capable node with optional geo data.
///
/// `dio_network` entry: `node_id` (hex), `node` (server object array).
/// Server object: index 1 = host/IP, index 5 = extra (list of [key, value]); `name` and `features` keys.
public struct VpnNode: Equatable, Sendable {
    public let nodeIdHex: String
    public let host: String
    public let name: String?
    public let latitude: Double?
    public let longitude: Double?
    public let city: String?
    public let country: String?
    public let wsRpcURLOverride: String?
    public let httpRpcURLOverride: String?

    public init(
        nodeIdHex: String,
        host: String,
        name: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        city: String? = nil,
        country: String? = nil,
        wsRpcURLOverride: String? = nil,
        httpRpcURLOverride: String? = nil
    ) {
        self.nodeIdHex = nodeIdHex
        self.host = host
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.city = city
        self.country = country
        self.wsRpcURLOverride = wsRpcURLOverride
        self.httpRpcURLOverride = httpRpcURLOverride
    }

    public var wireguardPort: Int { NetworkConfig.defaultWireguardPort }

    public func websocketURL() -> String {
        wsRpcURLOverride ?? "wss://\(host):8443/ws"
    }

    public func httpRpcURL() -> String {
        httpRpcURLOverride ?? "https://\(host):8443/"
    }

    public func serverWallet20() throws -> Data {
        try DiodeHex.decode(nodeIdHex)
    }
}

private let directoryNameMarkers = [
    "diode-eu1", "diode-eu2", "diode-us1", "diode-us2", "diode-as1", "diode-as2",
]

private func isDirectoryEligible(name: String?, features: String?) -> Bool {
    let loweredName = name?.lowercased() ?? ""
    if directoryNameMarkers.contains(where: { loweredName.contains($0) }) {
        return true
    }
    if features?.contains("wg_exit") == true {
        return true
    }
    return false
}

/// Parses a single `dio_network` entry; returns nil when the node is not VPN-eligible.
public func parseNodeFromNetworkEntry(_ entry: [String: Any]) -> VpnNode? {
    guard let rawID = entry["node_id"] as? String,
          let nodeIdHex = DiodeHex.normalizeAddressHex(rawID),
          let nodeArray = entry["node"] as? [Any],
          nodeArray.count > 1,
          let host = nodeArray[1] as? String
    else {
        return nil
    }

    var name: String?
    var features: String?
    if nodeArray.count > 5, let extra = nodeArray[5] as? [Any] {
        for item in extra {
            guard let pair = item as? [Any], pair.count >= 2,
                  let key = pair[0] as? String,
                  let value = pair[1] as? String
            else {
                continue
            }
            switch key {
            case "name": name = value
            case "features": features = value
            default: break
            }
        }
    }

    guard isDirectoryEligible(name: name, features: features) else {
        return nil
    }

    return VpnNode(nodeIdHex: nodeIdHex, host: host, name: name)
}

/// Parses all VPN-eligible nodes from a `dio_network` result array.
public func parseVpnNodes(fromNetworkResult result: [[String: Any]]) -> [VpnNode] {
    result.compactMap(parseNodeFromNetworkEntry)
}
