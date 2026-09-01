import DiodeNetwork
import Domain
import Foundation

public enum DiodeNodeSelector {
    /// Failures older than this are treated as never-failed for reconnect ordering (Android parity).
    public static let staleFailureSeconds: TimeInterval = 180

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

    /// Same-country reconnect order: seed first, then never-failed / oldest failure.
    /// Failures older than [staleFailureSeconds] sort like never-failed.
    public static func sameCountryReconnectCandidates(
        seedNode: VpnNode,
        cachedServers: [VpnNode],
        failureTimestamps: [String: Int64],
        nowMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) -> [VpnNode] {
        let country = normalizedCountry(seedNode.country)
        let staleCutoffMs = nowMs - Int64(staleFailureSeconds * 1000)

        let inCountry = cachedServers.filter {
            normalizedCountry($0.country) == country &&
                $0.nodeIdHex.lowercased() != seedNode.nodeIdHex.lowercased()
        }

        let sorted = inCountry.sorted { lhs, rhs in
            let lhsFail = effectiveFailure(failureTimestamps[lhs.nodeIdHex], staleCutoffMs: staleCutoffMs)
            let rhsFail = effectiveFailure(failureTimestamps[rhs.nodeIdHex], staleCutoffMs: staleCutoffMs)
            if lhsFail != rhsFail {
                return lhsFail < rhsFail
            }
            return lhs.primaryDisplayName.lowercased() < rhs.primaryDisplayName.lowercased()
        }
        return [seedNode] + sorted
    }

    private static func normalizedCountry(_ country: String?) -> String {
        let trimmed = country?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Unknown" : trimmed
    }

    /// Never-failed and stale failures sort as `Int64.min` (tried first among peers).
    private static func effectiveFailure(_ timestamp: Int64?, staleCutoffMs: Int64) -> Int64 {
        guard let timestamp else { return Int64.min }
        if timestamp < staleCutoffMs { return Int64.min }
        return timestamp
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
