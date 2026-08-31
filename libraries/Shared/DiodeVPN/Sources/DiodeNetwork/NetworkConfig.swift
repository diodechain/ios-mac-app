import Foundation

/// Central configuration for Diode API endpoints.
public enum NetworkConfig {
    public static let prenetRpcURL = "https://prenet.diode.io:8443/"
    public static let prenetWsURL = "wss://prenet.diode.io:8443/ws"
    public static let geoBaseURL = "https://monitor.testnet.diode.io"
    /// [Diode Console](https://console.diode.io/docs/api) JSON-RPC endpoint (HTTPS).
    public static let diodeConsoleRpcURL = "https://console.diode.io/api/v1/rpc"
    /// Console `fleet.member.add` target fleet UUID (public identifier, not a secret).
    public static let diodeConsoleFleetUUID = "75894474-0117-4f83-89d1-ee8f260c490b"
    public static let defaultWireguardPort = 51_820

    public static let debugLocalNodeHostLoopback = "127.0.0.1"
    public static let debugLocalNodeHostSimulator = "127.0.0.1"
    public static let debugLocalRPCPort = 8545

    /// Host for the synthetic "Local (debug)" VPN node.
    public static var debugLocalNodeHost: String {
        #if targetEnvironment(simulator)
        return debugLocalNodeHostSimulator
        #else
        return debugLocalNodeHostLoopback
        #endif
    }

    public static func isDebugLocalNodeHost(_ host: String) -> Bool {
        host == debugLocalNodeHost ||
            host == debugLocalNodeHostLoopback ||
            host == debugLocalNodeHostSimulator ||
            host == "localhost"
    }

    public static let moonbeamChainID: UInt64 = 1284
    public static let moonbeamRPCURL = "https://rpc.api.moonbeam.network"
    public static let moonbeamEpochDurationSec: UInt64 = 2_592_000
    public static let diodeDeveloperFleetHex = "6000000000000000000000000000000000000000"
    public static let diodeVpnFleetContractHex = "d5b1221fce90049fbfc917f28b8996a07fdfdea7"
    public static let ticketTotalBytesInitial: UInt64 = 4096
    public static let ticketRefreshHeadroomBytes: UInt64 = 65_536
    public static let ticketMaxStepBytes: UInt64 = 50_000_000
}
