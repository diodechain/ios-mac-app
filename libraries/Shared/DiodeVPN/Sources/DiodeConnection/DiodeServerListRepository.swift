import CoreLocation
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
    /// Bounded parallel geo HTTP lookups (Android uses a semaphore).
    private let geoConcurrency = 8

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
        let parsed = parseVpnNodes(fromNetworkResult: result)
        let seeded = seedGeoFromCache(parsed)
        let withGeo = await enrichWithGeo(seeded)
        let withCountries = await fillMissingCountries(withGeo)
        nodeCache.replaceAll(withCountries)
        cachedNodes = withCountries
        lastRefresh = Date()
        return Self.prependDebugIfNeeded(withCountries)
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

    // MARK: - Geo enrich

    private func seedGeoFromCache(_ nodes: [VpnNode]) -> [VpnNode] {
        let byID = Dictionary(uniqueKeysWithValues: cachedNodes.map { ($0.nodeIdHex.lowercased(), $0) })
        return nodes.map { node in
            guard let cached = byID[node.nodeIdHex.lowercased()] else { return node }
            return node.withGeo(
                latitude: node.latitude ?? cached.latitude,
                longitude: node.longitude ?? cached.longitude,
                city: node.city ?? cached.city,
                country: node.country ?? cached.country
            )
        }
    }

    private func enrichWithGeo(_ nodes: [VpnNode]) async -> [VpnNode] {
        var enriched = nodes
        var index = 0
        while index < nodes.count {
            await withTaskGroup(of: (Int, VpnNode).self) { group in
                var scheduled = 0
                while scheduled < geoConcurrency, index < nodes.count {
                    let i = index
                    let node = nodes[i]
                    index += 1
                    if node.latitude != nil {
                        continue
                    }
                    scheduled += 1
                    group.addTask {
                        (i, await self.enrichOne(node))
                    }
                }
                for await (i, updated) in group {
                    enriched[i] = updated
                }
            }
        }
        return enriched
    }

    private func enrichOne(_ node: VpnNode) async -> VpnNode {
        do {
            let geo = try await api.fetchGeo(host: node.host)
            return node.withGeo(
                latitude: geo.latitude,
                longitude: geo.longitude,
                city: geo.city ?? node.city,
                country: node.country
            )
        } catch {
            return node
        }
    }

    private func fillMissingCountries(_ nodes: [VpnNode]) async -> [VpnNode] {
        var result: [VpnNode] = []
        result.reserveCapacity(nodes.count)
        for node in nodes {
            if let country = node.country, !country.isEmpty {
                result.append(node)
                continue
            }
            guard let lat = node.latitude, let lon = node.longitude else {
                result.append(node)
                continue
            }
            if let country = await Self.reverseGeocodeCountry(latitude: lat, longitude: lon) {
                result.append(node.withGeo(country: country))
            } else {
                result.append(node)
            }
        }
        return result
    }

    private static func reverseGeocodeCountry(latitude: Double, longitude: Double) async -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let iso = placemarks.first?.isoCountryCode, !iso.isEmpty {
                return iso.uppercased()
            }
            return placemarks.first?.country
        } catch {
            return nil
        }
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
