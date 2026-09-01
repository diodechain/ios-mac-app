import Domain
import Foundation

/// Live fetch helpers for swapping `LogicalsClient` on Diode backend builds.
public enum DiodeLogicalsLive {
    public static func fetchLogicals(countryCode: String?) async throws -> [VPNServer] {
        let nodes = try await DiodeServerListRepository.shared.nodesMatching(countryCode: countryCode)
        return DiodeVpnNodeAdapter.toVpnServers(from: nodes)
    }

    public static func fetchLoads() async throws -> [ContinuousServerProperties] {
        let servers = try await fetchLogicals(countryCode: nil)
        return servers.map {
            ContinuousServerProperties(
                serverId: $0.id,
                load: 5,
                score: 1.0,
                status: 1
            )
        }
    }
}
