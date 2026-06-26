import Foundation
import os

/// Registers this device's TicketV2 signing key as a fleet member via
/// [Diode Console JSON-RPC](https://console.diode.io/docs/api) (`fleet.member.add`).
public enum DiodeConsoleFleetRegistrar {
    private static let logger = Logger(subsystem: "io.diode.vpn", category: "DiodeConsoleFleet")

    /// Best-effort registration on app launch; logs and returns on HTTP/RPC failure.
    public static func registerOnLaunch(
        deviceAddress0x: String,
        label: String,
        apiKey: String = NetworkConfig.diodeConsoleAPIKey,
        fleetUUID: String = NetworkConfig.diodeConsoleFleetUUID,
        session: URLSession = .shared
    ) async {
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
}
