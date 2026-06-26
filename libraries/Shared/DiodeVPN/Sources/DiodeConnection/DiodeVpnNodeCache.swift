import Dependencies
import DependenciesMacros
import DiodeNetwork
import Foundation

/// Node list persistence boundary. GRDB implementation is wired in app targets (`AppDependencies+Live`).
@DependencyClient
public struct DiodeVpnNodeCache: Sendable {
    public var getAll: @Sendable () -> [VpnNode] = { [] }
    public var lastRefreshEpochMs: @Sendable () -> Int64? = { nil }
    public var replaceAll: @Sendable ([VpnNode]) -> Void
    public var recordConnectFailure: @Sendable (String) -> Void
    public var getConnectFailureTimestamps: @Sendable () -> [String: Int64] = { [:] }
}

public enum DiodeVpnNodeCacheKey: DependencyKey {
    public static var liveValue: DiodeVpnNodeCache { .inMemory }
}

extension DiodeVpnNodeCacheKey: TestDependencyKey {
    public static var testValue: DiodeVpnNodeCache { .inMemory }
}

public extension DependencyValues {
    var diodeVpnNodeCache: DiodeVpnNodeCache {
        get { self[DiodeVpnNodeCacheKey.self] }
        set { self[DiodeVpnNodeCacheKey.self] = newValue }
    }
}

public extension DiodeVpnNodeCache {
    /// Ephemeral store for tests and until app wires GRDB.
    static var inMemory: DiodeVpnNodeCache {
        let storage = InMemoryDiodeVpnNodeStorage()
        return DiodeVpnNodeCache(
            getAll: { storage.nodes },
            lastRefreshEpochMs: { storage.lastRefreshEpochMs },
            replaceAll: { storage.replaceAll($0) },
            recordConnectFailure: { storage.recordFailure($0) },
            getConnectFailureTimestamps: { storage.failureTimestamps }
        )
    }
}

private final class InMemoryDiodeVpnNodeStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var _nodes: [VpnNode] = []
    private var _lastRefreshEpochMs: Int64?
    private var _failures: [String: Int64] = [:]

    var nodes: [VpnNode] {
        lock.lock()
        defer { lock.unlock() }
        return _nodes
    }

    var lastRefreshEpochMs: Int64? {
        lock.lock()
        defer { lock.unlock() }
        return _lastRefreshEpochMs
    }

    var failureTimestamps: [String: Int64] {
        lock.lock()
        defer { lock.unlock() }
        return _failures
    }

    func replaceAll(_ nodes: [VpnNode]) {
        lock.lock()
        _nodes = nodes
        _lastRefreshEpochMs = Int64(Date().timeIntervalSince1970 * 1000)
        lock.unlock()
    }

    func recordFailure(_ nodeIdHex: String) {
        lock.lock()
        _failures[nodeIdHex] = Int64(Date().timeIntervalSince1970 * 1000)
        lock.unlock()
    }
}
