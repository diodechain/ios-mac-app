import DiodeNetwork
import Domain
import Foundation

public enum DiodeNodeSelector {
    /// Maps Proton [ConnectionSpec] intent to a Diode exit node without UI changes.
    public static func selectNode(from spec: ConnectionSpec, nodes: [VpnNode]) throws -> VpnNode {
        guard !nodes.isEmpty else {
            throw DiodeConnectionError.noExitNodes
        }

        let candidates = candidates(for: spec, nodes: nodes)
        guard let selected = candidates.first else {
            throw DiodeConnectionError.noExitNodes
        }
        return selected
    }

    private static func candidates(for spec: ConnectionSpec, nodes: [VpnNode]) -> [VpnNode] {
        switch spec.location {
        case let .country(code, _):
            let filtered = nodes.filter { ($0.country?.uppercased() ?? "") == code.uppercased() }
            return filtered.isEmpty ? nodes : filtered
        case let .city(_, code, _):
            let filtered = nodes.filter { ($0.country?.uppercased() ?? "") == code.uppercased() }
            return filtered.isEmpty ? nodes : filtered
        case let .exact(_, logicalID, number, _, regionCode):
            if let logicalID, logicalID.hasPrefix("diode-"),
               let nodeIDHex = DiodeVpnNodeAdapter.nodeIDHex(forLogicalID: logicalID),
               let matched = nodes.first(where: { normalizedNodeIDHex($0.nodeIdHex) == nodeIDHex }) {
                return [matched]
            }
            let filtered = nodes.filter { ($0.country?.uppercased() ?? "") == regionCode.uppercased() }
            let pool = filtered.isEmpty ? nodes : filtered
            if let number, number > 0, number <= pool.count {
                return [pool[number - 1]]
            }
            return pool.isEmpty ? [] : [pool[0]]
        case .any, .state, .secureCore, .gateway:
            return nodes
        }
    }

    private static func normalizedNodeIDHex(_ nodeIDHex: String) -> String {
        nodeIDHex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "0x", with: "")
    }
}
