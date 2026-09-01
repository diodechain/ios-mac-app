import Foundation
import os

/// Registers this device's TicketV2 signing key as a fleet member via
/// [Diode Console JSON-RPC](https://console.diode.io/docs/api) (`fleet.member.add`).
public enum DiodeConsoleFleetRegistrar {
    private static let logger = Logger(subsystem: "io.diode.vpn", category: "DiodeConsoleFleet")

    /// Best-effort registration on app launch; logs and returns on HTTP/RPC failure.
    /// Skips when `apiKey` is empty (key not injected at build time).
    public static func registerOnLaunch(
        deviceAddress0x: String,
        label: String,
        apiKey: String,
        fleetUUID: String = NetworkConfig.diodeConsoleFleetUUID,
        session: URLSession = .shared
    ) async {
        guard !apiKey.isEmpty else {
            logger.info("fleet.member.add skipped: DIODE_CONSOLE_API_KEY not set at build time")
            return
        }

        let params: [String: Any] = [
            "fleet_id": fleetUUID,
            "address": deviceAddress0x,
            "label": label,
        ]
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "fleet.member.add",
            "params": params,
        ]

        guard let url = URL(string: NetworkConfig.diodeConsoleRpcURL) else {
            logger.warning("fleet.member.add: invalid console RPC URL")
            return
        }

        var request = URLRequest(url: url, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await session.data(for: request)
            let text = String(data: data, encoding: .utf8)
            guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                logger.warning("fleet.member.add HTTP \(code) body=\(text?.prefix(800) ?? "", privacy: .public)")
                return
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                logger.warning("fleet.member.add: invalid JSON: \(text?.prefix(400) ?? "", privacy: .public)")
                return
            }
            if let error = json["error"] as? [String: Any], !error.isEmpty {
                let message = error["message"] as? String ?? String(describing: error)
                logger.info("fleet.member.add RPC error: \(message, privacy: .public)")
                return
            }
            logger.info("fleet.member.add OK for \(deviceAddress0x, privacy: .public)")
        } catch {
            logger.warning("fleet.member.add failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// CI / package smoke: `fleet.info` with an injected org API key.
    public static func fleetInfo(
        apiKey: String,
        fleetUUID: String = NetworkConfig.diodeConsoleFleetUUID,
        session: URLSession = .shared
    ) async throws -> [String: Any] {
        guard !apiKey.isEmpty else {
            throw DiodeConsoleError.emptyAPIKey
        }
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "fleet.info",
            "params": ["fleet_id": fleetUUID],
        ]
        guard let url = URL(string: NetworkConfig.diodeConsoleRpcURL) else {
            throw DiodeConsoleError.invalidURL
        }
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        let http = response as? HTTPURLResponse
        let status = http?.statusCode ?? -1
        let text = String(data: data, encoding: .utf8) ?? ""
        guard (200 ..< 300).contains(status) else {
            throw DiodeConsoleError.http(status: status, body: String(text.prefix(400)))
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DiodeConsoleError.invalidJSON(body: String(text.prefix(400)))
        }
        if let error = json["error"] as? [String: Any], !error.isEmpty {
            let message = error["message"] as? String ?? String(describing: error)
            throw DiodeConsoleError.rpc(message: message, body: String(text.prefix(400)))
        }
        guard let result = json["result"] as? [String: Any], !result.isEmpty else {
            throw DiodeConsoleError.emptyResult(body: String(text.prefix(400)))
        }
        return result
    }
}

public enum DiodeConsoleError: Error, Equatable {
    case emptyAPIKey
    case invalidURL
    case http(status: Int, body: String)
    case invalidJSON(body: String)
    case rpc(message: String, body: String)
    case emptyResult(body: String)
}
