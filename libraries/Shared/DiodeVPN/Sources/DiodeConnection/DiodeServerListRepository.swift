import DiodeNetwork
import Dependencies
import Foundation

/// GRDB-backed node cache with background refresh (mirrors Android `ServerListRepository`).
public actor DiodeServerListRepository {
    public static let shared = DiodeServerListRepository()

    private let api: DiodeNetworkApi
    private let nodeCache: DiodeVpnNodeCache
    private var cachedNodes: [VpnNode] = []
    private var lastRefresh: Date?
    private let refreshInterval: TimeInterval = 3600

    public init(
        api: DiodeNetworkApi = DiodeNetworkApi(),
        nodeCache: DiodeVpnNodeCache? = nil
    ) {
        self.api = api
        let cache = nodeCache ?? DiodeVpnNodeCacheKey.liveValue
        self.nodeCache = cache
        let nodes = cache.getAll()
        self.cachedNodes = nodes
        if let maxUpdatedAt = cache.lastRefreshEpochMs(), maxUpdatedAt > 0 {
            self.lastRefresh = Date(timeIntervalSince1970: TimeInterval(maxUpdatedAt) / 1000)
        }
    }

    public func cachedOrFetchNodes() async throws -> [VpnNode] {
        if !cachedNodes.isEmpty,
           let lastRefresh,
           Date().timeIntervalSince(lastRefresh) < refreshInterval
        {
            return Self.prependDebugIfNeeded(cachedNodes)
        }
        return try await refreshNodes()
    }

    @discardableResult
    public func refreshNodes() async throws -> [VpnNode] {
        let result = try await api.fetchNetwork()
        let nodes = parseVpnNodes(fromNetworkResult: result)
        nodeCache.replaceAll(nodes)
        cachedNodes = nodes
        lastRefresh = Date()
        return Self.prependDebugIfNeeded(nodes)
    }

    public func nodesMatching(countryCode: String?) async throws -> [VpnNode] {
        let nodes = try await cachedOrFetchNodes()
        guard let countryCode else { return nodes }
        let upper = countryCode.uppercased()
        return nodes.filter { ($0.country?.uppercased() ?? "") == upper }
    }

    public func recordConnectFailure(nodeIdHex: String) {
        nodeCache.recordConnectFailure(nodeIdHex)
    }

    public func getConnectFailureTimestamps() -> [String: Int64] {
        nodeCache.getConnectFailureTimestamps()
    }

    // MARK: - DEBUG synthetic nodes (read-time only, never persisted)

    private static func prependDebugIfNeeded(_ nodes: [VpnNode]) -> [VpnNode] {
        #if DEBUG
        debugVpnNodes() + nodes
        #else
        nodes
        #endif
    }

    #if DEBUG
    private static let debugCountry = "Debug"

    private static func debugVpnNodes() -> [VpnNode] {
        let host = NetworkConfig.debugLocalNodeHost
        let port = NetworkConfig.debugLocalRPCPort
        return [
            VpnNode(
                nodeIdHex: "0000000000000000000000000000000000000001",
                host: host,
                name: "Local (debug)",
                city: "localhost",
                country: debugCountry,
                wsRpcURLOverride: "ws://\(host):\(port)/ws",
                httpRpcURLOverride: "http://\(host):\(port)/"
            ),
            VpnNode(
                nodeIdHex: "0000000000000000000000000000000000000002",
                host: "139.162.191.153",
                name: "lite-node",
                country: debugCountry
            ),
        ]
    }
    #endif
}
