import ConnectionShared
import Domain
import Foundation
import NetworkExtension

/// Starts/stops WireGuard tunnel via `NETunnelProviderManager` with Diode v2 stored config.
public enum DiodeTunnelController {
    private static let keychain = TunnelKeychainImplementation()

    public static func startTunnel(
        session: DiodeWireGuardSession,
        clientPrivateKeyBase64: String
    ) async throws {
        let configData = try encodeStoredConfig(session: session, clientPrivateKey: clientPrivateKeyBase64)
        let passwordReference = try keychain.store(configData)

        let managers = try await loadTunnelManagers()
        let manager = managers.first ?? NETunnelProviderManager()

        let protocolConfiguration = NETunnelProviderProtocol()
        protocolConfiguration.providerBundleIdentifier = DiodeWireGuardExtensionBundleId.provider
        protocolConfiguration.serverAddress = session.endpointHost
        protocolConfiguration.passwordReference = passwordReference
        protocolConfiguration.disconnectOnSleep = false
        #if os(iOS)
        protocolConfiguration.includeAllNetworks = true
        protocolConfiguration.excludeLocalNetworks = false
        #endif

        manager.protocolConfiguration = protocolConfiguration
        manager.localizedDescription = "Diode VPN"
        manager.isEnabled = true
        manager.isOnDemandEnabled = false

        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()
        try manager.connection.startVPNTunnel()
    }

    public static func stopTunnel() async throws {
        let managers = try await loadTunnelManagers()
        for manager in managers {
            manager.connection.stopVPNTunnel()
            manager.isOnDemandEnabled = false
            try await manager.saveToPreferences()
        }
    }

    private static func loadTunnelManagers() async throws -> [NETunnelProviderManager] {
        try await withCheckedThrowingContinuation { continuation in
            NETunnelProviderManager.loadAllFromPreferences { managers, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: managers ?? [])
                }
            }
        }
    }

    private static func encodeStoredConfig(
        session: DiodeWireGuardSession,
        clientPrivateKey: String
    ) throws -> Data {
        let encoder = JSONEncoder()
        let version = StoredWireguardConfig.Version.v2
        let storedConfig = StoredWireguardConfig(
            wireguardConfig: WireguardConfig(dns: ["1.1.1.1"]),
            clientPrivateKey: clientPrivateKey,
            serverPublicKey: session.serverPublicKey,
            entryServerAddress: session.endpointHost,
            ports: [session.listenPort],
            timestamp: Date(),
            clientAddressCidr: session.clientAddress,
            listenPort: session.listenPort
        )
        var data = Data([UInt8(version.rawValue)])
        let encodedConfig = try encoder.encode(storedConfig)
        data.append(encodedConfig)
        return data
    }
}
