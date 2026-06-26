import Foundation

public struct DioTicketSummary: Equatable, Sendable {
    public let totalConnections: UInt64
    public let totalBytes: UInt64

    public init(totalConnections: UInt64, totalBytes: UInt64) {
        self.totalConnections = totalConnections
        self.totalBytes = totalBytes
    }
}

struct ParsedTooLow: Equatable {
    let usage: UInt64
    let summary: DioTicketSummary?
}

/// Success payload of `dio_wireguard_open` per WireGuard exit-node spec v0.1.4.
public struct WireGuardSessionInfo: Equatable, Sendable {
    public let serverPublicKey: String
    public let endpointHost: String
    public let listenPort: Int
    public let clientAddress: String

    public init(serverPublicKey: String, endpointHost: String, listenPort: Int, clientAddress: String) {
        self.serverPublicKey = serverPublicKey
        self.endpointHost = endpointHost
        self.listenPort = listenPort
        self.clientAddress = clientAddress
    }

    public static func fromRpcResult(_ result: Any?) throws -> WireGuardSessionInfo {
        let object: [String: Any]
        switch result {
        case let dict as [String: Any]:
            object = dict
        case let string as String:
            guard let data = string.data(using: .utf8),
                  let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                throw WireGuardSessionInfoError.invalidResult
            }
            object = parsed
        case .none:
            throw WireGuardSessionInfoError.nullResult
        default:
            throw WireGuardSessionInfoError.invalidResult
        }

        guard let serverPublicKey = object["server_public_key"] as? String,
              let endpointHost = object["endpoint_host"] as? String,
              let clientAddress = object["client_address"] as? String
        else {
            throw WireGuardSessionInfoError.missingField
        }

        let listenPort: Int
        switch object["listen_port"] {
        case let number as Int:
            listenPort = number
        case let number as Double:
            listenPort = Int(number)
        case let string as String:
            guard let parsed = Int(string) else { throw WireGuardSessionInfoError.missingField }
            listenPort = parsed
        default:
            throw WireGuardSessionInfoError.missingField
        }

        return WireGuardSessionInfo(
            serverPublicKey: serverPublicKey,
            endpointHost: endpointHost,
            listenPort: listenPort,
            clientAddress: clientAddress
        )
    }
}

public enum WireGuardSessionInfoError: Error {
    case nullResult
    case invalidResult
    case missingField
}
