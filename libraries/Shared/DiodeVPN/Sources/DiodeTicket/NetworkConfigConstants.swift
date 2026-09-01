import Foundation

/// Ticket/chain constants mirrored from Android `NetworkConfig`.
public enum NetworkConfigConstants {
    public static let moonbeamChainID: UInt64 = 1284
    public static let moonbeamRPCURL = "https://rpc.api.moonbeam.network"
    public static let moonbeamEpochDurationSec: UInt64 = 2_592_000
    public static let diodeDeveloperFleetHex = "6000000000000000000000000000000000000000"
    public static let diodeVpnFleetContractHex = "d5b1221fce90049fbfc917f28b8996a07fdfdea7"
    public static let ticketTotalBytesInitial: UInt64 = 4096
    public static let ticketRefreshHeadroomBytes: UInt64 = 65_536
    public static let ticketMaxStepBytes: UInt64 = 50_000_000
}
