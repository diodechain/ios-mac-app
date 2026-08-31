import DiodeCrypto
import DiodeNetwork
import DiodeRPC
import DiodeTicket
import Domain
import Foundation

/// Holds the live WebSocket RPC session for the current VPN connection (app process).
public actor DiodeActiveSession {
    public static let shared = DiodeActiveSession()

    private var rpcClient: DiodeRpcClient?
    private var selectedNode: VpnNode?
    private var ticketSigningContext: TicketSigningContext?
    private var activeSpec: ConnectionSpec?
    private var reconnectTask: Task<Void, Never>?
    private let lifecycleBridge = RpcLifecycleBridge()
    private let maxReconnectAttempts = 5

    private struct TicketSigningContext: Sendable {
        var params: TicketV2.Params
        var lastSignedTotalBytes: UInt64
    }

    public func makeRpcClient(wsURL: String) -> DiodeRpcClient {
        DiodeRpcClient(wsURL: wsURL, lifecycleListener: lifecycleBridge)
    }

    public func setClient(_ client: DiodeRpcClient?, node: VpnNode?, spec: ConnectionSpec? = nil) {
        rpcClient = client
        selectedNode = node
        if let spec {
            activeSpec = spec
        }
    }

    public func storeTicketSigningContext(params: TicketV2.Params, lastSignedTotalBytes: UInt64) {
        ticketSigningContext = TicketSigningContext(params: params, lastSignedTotalBytes: lastSignedTotalBytes)
    }

    public func currentClient() -> DiodeRpcClient? {
        rpcClient
    }

    public func currentNode() -> VpnNode? {
        selectedNode
    }

    public func currentSpec() -> ConnectionSpec? {
        activeSpec
    }

    func handleTicketRequest(usage: UInt64, fleetHex: String?) async {
        guard let rpcClient, let context = ticketSigningContext else { return }
        let deviceKeys = DeviceKeyStore()
        do {
            let privateKey = try deviceKeys.getOrCreateSecp256k1PrivateKey32()
            let submitted = try await DiodeTicketSubmitter.submitWithRetries(
                rpc: rpcClient,
                baseParams: context.params,
                initialTotalBytes: context.lastSignedTotalBytes,
                privateKey32: privateKey,
                usageHint: usage,
                fleetHintHex: fleetHex
            )
            ticketSigningContext = TicketSigningContext(
                params: submitted.params,
                lastSignedTotalBytes: submitted.lastSignedTotalBytes
            )
        } catch {
            await handleSessionFailure(reason: "ticket refresh failed: \(error.localizedDescription)")
        }
    }

    func handleRpcClosed(reason: String) async {
        await handleSessionFailure(reason: reason)
    }

    /// Stops RPC and WireGuard tunnel. Clears session state.
    public func tearDown() async {
        reconnectTask?.cancel()
        reconnectTask = nil
        if let rpcClient {
            try? await rpcClient.dioWireguardClose()
            rpcClient.disconnect()
        }
        rpcClient = nil
        selectedNode = nil
        ticketSigningContext = nil
        try? await DiodeTunnelController.stopTunnel()
    }

    /// Tear down without clearing [activeSpec] so reconnect can reuse it.
    private func tearDownForReconnect() async {
        if let rpcClient {
            try? await rpcClient.dioWireguardClose()
            rpcClient.disconnect()
        }
        rpcClient = nil
        ticketSigningContext = nil
        try? await DiodeTunnelController.stopTunnel()
    }

    private func handleSessionFailure(reason: String) async {
        _ = reason
        guard let failedNode = selectedNode, let spec = activeSpec else {
            await tearDown()
            return
        }

        await DiodeServerListRepository.shared.recordConnectFailure(nodeIdHex: failedNode.nodeIdHex)
        await tearDownForReconnect()

        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            guard let self else { return }
            await self.attemptReconnect(seed: failedNode, spec: spec)
        }
    }

    private func attemptReconnect(seed: VpnNode, spec: ConnectionSpec) async {
        let nodes = (try? await DiodeServerListRepository.shared.cachedOrFetchNodes()) ?? []
        let failures = await DiodeServerListRepository.shared.getConnectFailureTimestamps()
        let candidates = DiodeNodeSelector.sameCountryReconnectCandidates(
            seedNode: seed,
            cachedServers: nodes,
            failureTimestamps: failures
        )

        // Skip the failed seed; try remaining same-country peers first, then seed again last.
        let ordered = Array(candidates.dropFirst()) + [seed]
        var attempts = 0
        for candidate in ordered {
            if Task.isCancelled { return }
            attempts += 1
            if attempts > maxReconnectAttempts { break }
            do {
                try await DiodeConnectionLiveReconnect.connect(spec: spec, preferredNode: candidate)
                return
            } catch {
                await DiodeServerListRepository.shared.recordConnectFailure(nodeIdHex: candidate.nodeIdHex)
                await tearDownForReconnect()
            }
        }
        activeSpec = nil
        selectedNode = nil
    }

    init() {
        lifecycleBridge.owner = self
    }

    private final class RpcLifecycleBridge: DiodeRpcClient.RpcLifecycleListener {
        weak var owner: DiodeActiveSession?

        func onTicketRequest(usage: UInt64, fleetHex: String?) {
            guard let owner else { return }
            Task { await owner.handleTicketRequest(usage: usage, fleetHex: fleetHex) }
        }

        func onRpcClosed(reason: String) {
            guard let owner else { return }
            Task { await owner.handleRpcClosed(reason: reason) }
        }
    }
}

/// Internal reconnect entry that pins a preferred node (avoids circular visibility issues).
enum DiodeConnectionLiveReconnect {
    static func connect(spec: ConnectionSpec, preferredNode: VpnNode) async throws {
        try await DiodeConnectionLiveInternal.connect(spec: spec, preferredNode: preferredNode)
    }
}
