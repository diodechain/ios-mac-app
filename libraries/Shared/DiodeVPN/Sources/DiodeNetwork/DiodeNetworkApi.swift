import DiodeCrypto
import Foundation

/// Response from GET `https://monitor.testnet.diode.io/ip/<ip>`.
public struct GeoResponse: Codable, Equatable, Sendable {
    public let city: String?
    public let ip: String?
    public let latitude: Double?
    public let longitude: Double?

    public init(city: String? = nil, ip: String? = nil, latitude: Double? = nil, longitude: Double? = nil) {
        self.city = city
        self.ip = ip
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Chain id + current epoch detected from a single node's HTTP RPC.
public struct ChainContext: Equatable, Sendable {
    public let chainID: UInt64
    public let epoch: UInt64

    public init(chainID: UInt64, epoch: UInt64) {
        self.chainID = chainID
        self.epoch = epoch
    }
}

/// Fetches Diode JSON-RPC results over HTTPS and geo lookups.
open class DiodeNetworkApi: @unchecked Sendable {
    public static let chainIDAnvil: UInt64 = 31_337
    private static let legacyDiodeL1ChainID: UInt64 = 15
    private static let legacyDiodeL1EpochBlocks: UInt64 = 40_320

    private let baseURL: String
    private let geoBaseURL: String
    private let session: URLSession

    public init(
        baseURL: String = NetworkConfig.prenetRpcURL,
        geoBaseURL: String = NetworkConfig.geoBaseURL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.geoBaseURL = geoBaseURL
        self.session = session
    }

    /// POST `dio_network`; returns the raw `result` array.
    open func fetchNetwork() async throws -> [[String: Any]] {
        let body = #"{"jsonrpc":"2.0","id":1,"method":"dio_network","params":[]}"#
        let raw = try await postJSONRPC(urlString: baseURL, jsonBody: body)
        guard let json = try JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any],
              let result = json["result"] as? [[String: Any]]
        else {
            throw DiodeNetworkApiError.invalidResponse("no result array")
        }
        return result
    }

    /// Current ticket epoch on Moonbeam: `latest_block.timestamp / MOONBEAM_EPOCH_DURATION_SEC`.
    public func fetchMoonbeamEpoch() async throws -> UInt64 {
        try await fetchChainContext(httpRpcURL: NetworkConfig.moonbeamRPCURL).epoch
    }

    /// Detect chain id and current epoch for the node at `httpRpcURL`.
    public func fetchChainContext(httpRpcURL: String) async throws -> ChainContext {
        try await fetchChainContextInternal(httpURL: httpRpcURL)
    }

    /// Query the node for `eth_coinbase` (40-char hex, no `0x`).
    public func fetchEthCoinbaseHex(httpRpcURL: String) async throws -> String {
        let body = #"{"jsonrpc":"2.0","id":1,"method":"eth_coinbase","params":[]}"#
        let raw = try await postJSONRPCResultString(urlString: httpRpcURL, jsonBody: body)
        guard let normalized = DiodeHex.normalizeAddressHex(raw) else {
            throw DiodeNetworkApiError.invalidResponse("Unexpected eth_coinbase address: \(raw)")
        }
        return normalized
    }

    /// GET `/ip/{host}` geo lookup.
    public func fetchGeo(host: String) async throws -> GeoResponse {
        guard let url = URL(string: "\(geoBaseURL)/ip/\(host)") else {
            throw DiodeNetworkApiError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw DiodeNetworkApiError.invalidResponse("non-HTTP response")
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw DiodeNetworkApiError.httpError(http.statusCode)
        }
        return try JSONDecoder().decode(GeoResponse.self, from: data)
    }

    private func fetchChainContextInternal(httpURL: String) async throws -> ChainContext {
        let chainIDHex = try await postJSONRPCResultString(
            urlString: httpURL,
            jsonBody: #"{"jsonrpc":"2.0","id":2,"method":"eth_chainId","params":[]}"#
        )
        let chainID = try parseHexUInt64(chainIDHex)

        let blockTagHex = try await postJSONRPCResultString(
            urlString: httpURL,
            jsonBody: #"{"jsonrpc":"2.0","id":4,"method":"eth_blockNumber","params":[]}"#
        )

        let epoch: UInt64
        switch chainID {
        case Self.chainIDAnvil, NetworkConfig.moonbeamChainID:
            epoch = try await epochFromBlockTimestamp(httpURL: httpURL, blockTagHex: blockTagHex)
        case Self.legacyDiodeL1ChainID:
            let blockNumber = try parseHexUInt64(blockTagHex)
            epoch = blockNumber / Self.legacyDiodeL1EpochBlocks
        default:
            epoch = try await epochFromBlockTimestamp(httpURL: httpURL, blockTagHex: blockTagHex)
        }

        return ChainContext(chainID: chainID, epoch: epoch)
    }

    private func epochFromBlockTimestamp(httpURL: String, blockTagHex: String) async throws -> UInt64 {
        let body = """
        {"jsonrpc":"2.0","id":3,"method":"eth_getBlockByNumber","params":["\(blockTagHex)",false]}
        """
        let raw = try await postJSONRPC(urlString: httpURL, jsonBody: body)
        guard let json = try JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let timestamp = result["timestamp"] as? String
        else {
            throw DiodeNetworkApiError.invalidResponse("missing block timestamp")
        }
        let ts = try parseHexUInt64(timestamp)
        return ts / NetworkConfig.moonbeamEpochDurationSec
    }

    private func postJSONRPCResultString(urlString: String, jsonBody: String) async throws -> String {
        let raw = try await postJSONRPC(urlString: urlString, jsonBody: jsonBody)
        guard let json = try JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any] else {
            throw DiodeNetworkApiError.invalidResponse("invalid JSON")
        }
        if let error = json["error"] as? [String: Any], !error.isEmpty {
            let message = error["message"] as? String ?? "RPC error"
            throw DiodeNetworkApiError.rpcError(message)
        }
        guard let result = json["result"] as? String else {
            throw DiodeNetworkApiError.invalidResponse("missing JSON-RPC result")
        }
        return result
    }

    private func postJSONRPC(urlString: String, jsonBody: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw DiodeNetworkApiError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(jsonBody.utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw DiodeNetworkApiError.invalidResponse("non-HTTP response")
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw DiodeNetworkApiError.httpError(http.statusCode)
        }
        guard let body = String(data: data, encoding: .utf8), !body.isEmpty else {
            throw DiodeNetworkApiError.invalidResponse("empty body")
        }
        return body
    }

    private func parseHexUInt64(_ value: String) throws -> UInt64 {
        var hex = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.lowercased().hasPrefix("0x") {
            hex = String(hex.dropFirst(2))
        }
        guard let parsed = UInt64(hex, radix: 16) else {
            throw DiodeNetworkApiError.invalidResponse("invalid hex integer: \(value)")
        }
        return parsed
    }
}

public enum DiodeNetworkApiError: Error, Equatable {
    case invalidURL
    case httpError(Int)
    case invalidResponse(String)
    case rpcError(String)
}
