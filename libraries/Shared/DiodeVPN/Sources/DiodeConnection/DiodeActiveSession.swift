import DiodeCrypto
import DiodeNetwork
import DiodeRPC
import DiodeTicket
import Foundation

/// Holds the live WebSocket RPC session for the current VPN connection (app process).
public actor DiodeActiveSession {
    public static let shared = DiodeActiveSession()

    private var rpcClient: DiodeRpcClient?
    private var selectedNode: VpnNode?
    private var ticketSigningContext: TicketSigningContext?
    private let lifecycleBridge = RpcLifecycleBridge()

    private struct TicketSigningContext: Sendable {
        var params: TicketV2.Params
        var lastSignedTotalBytes: UInt64
    }

    public func makeRpcClient(wsURL: String) -> DiodeRpcClient {
        DiodeRpcClient(wsURL: wsURL, lifecycleListener: lifecycleBridge)
    }

    public func setClient(_ client: DiodeRpcClient?, node: VpnNode?) {
        rpcClient = client
        selectedNode = node
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
            await tearDown()
        }
    }

    func handleRpcClosed(reason: String) async {
        _ = reason
        await tearDown()
    }

    public func tearDown() async {
        if let rpcClient {
            try? await rpcClient.dioWireguardClose()
            rpcClient.disconnect()
        }
        rpcClient = nil
        selectedNode = nil
        ticketSigningContext = nil
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
