//
//  DiodeConnectionCoordinator.swift
//  DiodeConnection
//

import Connection
import Dependencies
import DependenciesMacros
import DiodeCrypto
import DiodeNetwork
import DiodeRPC
import DiodeTicket
import Domain
import Foundation
import VPNAppCore

public enum DiodeConnectionError: Error, Sendable {
    case notImplemented
    case noExitNodes
    case notEntitled
    case rpcFailed(String)
    case tunnelFailed(String)
}

@DependencyClient
public struct DiodeConnectionCoordinator: Sendable {
    public var connect: @Sendable (
        _ spec: ConnectionSpec,
        _ trigger: UserInitiatedVPNChange.VPNTrigger?
    ) async throws -> Void
    public var disconnect: @Sendable () async throws -> Void
}

extension DiodeConnectionCoordinator: DependencyKey {
    public static let liveValue = DiodeConnectionCoordinator(
        connect: { spec, _ in
            try await DiodeConnectionLive.connect(spec: spec)
        },
        disconnect: {
            try await DiodeConnectionLive.disconnect()
        }
    )

    public static let testValue = DiodeConnectionCoordinator(
        connect: { _, _ in },
        disconnect: {}
    )
}

public extension DependencyValues {
    var diodeConnectionCoordinator: DiodeConnectionCoordinator {
        get { self[DiodeConnectionCoordinator.self] }
        set { self[DiodeConnectionCoordinator.self] = newValue }
    }
}

// MARK: - Live implementation

private enum DiodeConnectionLive {
    private static let deviceKeys = DeviceKeyStore()
    private static let networkApi = DiodeNetworkApi()

    static func connect(spec: ConnectionSpec) async throws {
        guard DiodeVpnEntitlement.hasEntitlement() else {
            await publishStatus(.disconnected, spec: spec, node: nil)
            throw DiodeConnectionError.notEntitled
        }

        let nodes = try await DiodeServerListRepository.shared.cachedOrFetchNodes()
        let node = try DiodeNodeSelector.selectNode(from: spec, nodes: nodes)

        await publishStatus(.connecting, spec: spec, node: node)

        let epoch = try await networkApi.fetchMoonbeamEpoch()
        let serverWallet = try node.serverWallet20()
        let fleetBytes = try DiodeHex.decode(NetworkConfigConstants.diodeVpnFleetContractHex)

        let privateKey = try deviceKeys.getOrCreateSecp256k1PrivateKey32()
        let localAddress = try deviceKeys.getOrCreateTicketLocalAddress()

        let ticketParams = TicketV2.Params(
            chainID: NetworkConfigConstants.moonbeamChainID,
            epoch: epoch,
            fleetContract20: fleetBytes,
            serverID20: serverWallet,
            totalConnections: 0,
            totalBytes: NetworkConfigConstants.ticketTotalBytesInitial,
            localAddress: localAddress
        )

        let rpc = await DiodeActiveSession.shared.makeRpcClient(wsURL: node.websocketURL())
        try await rpc.connectAwait()
        await DiodeActiveSession.shared.setClient(rpc, node: node)

        do {
            let ticketSubmit = try await DiodeTicketSubmitter.submitWithRetries(
                rpc: rpc,
                baseParams: ticketParams,
                initialTotalBytes: NetworkConfigConstants.ticketTotalBytesInitial,
                privateKey32: privateKey
            )
            await DiodeActiveSession.shared.storeTicketSigningContext(
                params: ticketSubmit.params,
                lastSignedTotalBytes: ticketSubmit.lastSignedTotalBytes
            )

            let wgKeys = DiodeWireGuardKeyPair.generate()
            let sessionInfo = try await rpc.dioWireguardOpenSession(publicKeyHex: wgKeys.publicKeyHex)

            let wgSession = DiodeWireGuardSession(
                serverPublicKey: sessionInfo.serverPublicKey,
                endpointHost: sessionInfo.endpointHost,
                listenPort: sessionInfo.listenPort,
                clientAddress: sessionInfo.clientAddress
            )

            let preflight = DiodeWireGuardPreflight.probe(
                session: wgSession,
                privateKeyBase64: wgKeys.privateKeyBase64,
                publicKeyHex: wgKeys.publicKeyHex
            )
            guard case .ok = preflight else {
                throw DiodeConnectionError.tunnelFailed(DiodeWireGuardPreflight.describe(preflight))
            }

            try await DiodeTunnelController.startTunnel(
                session: wgSession,
                clientPrivateKeyBase64: wgKeys.privateKeyBase64
            )

            await publishStatus(.connected, spec: spec, node: node)
        } catch {
            await DiodeActiveSession.shared.tearDown()
            await publishStatus(.disconnected, spec: spec, node: node)
            if let rpcError = error as? DiodeRpcClient.RpcException {
                throw DiodeConnectionError.rpcFailed(rpcError.message)
            }
            if let connectionError = error as? DiodeConnectionError {
                throw connectionError
            }
            throw DiodeConnectionError.tunnelFailed(error.localizedDescription)
        }
    }

    static func disconnect() async throws {
        let activeNode = await DiodeActiveSession.shared.currentNode()
        let spec = ConnectionSpec.defaultFastest

        await publishStatus(.disconnecting, spec: spec, node: activeNode)
        await DiodeActiveSession.shared.tearDown()
        try await DiodeTunnelController.stopTunnel()
        await publishStatus(.disconnected, spec: spec, node: activeNode)
    }

    @MainActor
    private static func pushStatus(_ status: VPNConnectionStatus) {
        @Dependency(\.connectionBridge) var bridge
        bridge.pushStatus(status)
    }

    private static func publishStatus(
        _ phase: DiodeConnectionStatusMapper.Phase,
        spec: ConnectionSpec,
        node: VpnNode?
    ) async {
        let status = DiodeConnectionStatusMapper.vpnConnectionStatus(
            phase: phase,
            spec: spec,
            node: node
        )
        await MainActor.run {
            pushStatus(status)
        }
    }
}
