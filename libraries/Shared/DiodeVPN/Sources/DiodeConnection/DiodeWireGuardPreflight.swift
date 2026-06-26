import Domain
import Foundation

/// Pure-Swift WireGuard Noise IKpsk2 UDP probe before bringing up the OS tunnel.
public enum DiodeWireGuardPreflight {
    public enum Result: Sendable, Equatable {
        case ok
        case noResponse(endpoint: String, timeoutMs: Int)
        case badMac1
        case staleServerKey
        case other(String)
    }

    public static let defaultTimeoutMs = 4_000

    /// Run a one-shot handshake against [session]. Blocking UDP work runs off the caller's executor.
    public static func probe(
        session: DiodeWireGuardSession,
        privateKeyBase64: String,
        publicKeyHex: String,
        timeoutMs: Int = defaultTimeoutMs
    ) -> Result {
        guard let staticPriv = Data(base64Encoded: privateKeyBase64) else {
            return .other("Invalid client private key (base64)")
        }
        guard let staticPub = Data(hexString: publicKeyHex), staticPub.count == WireGuardCrypto.x25519Len else {
            return .other("Invalid client public key (hex)")
        }
        guard let serverPub = Data(base64Encoded: session.serverPublicKey), serverPub.count == WireGuardCrypto.x25519Len else {
            return .other("Invalid server_public_key (base64)")
        }

        do {
            let (initPacket, hsSession) = try WireGuardHandshake.buildInitiation(
                staticPriv: staticPriv,
                staticPub: staticPub,
                responderStaticPub: serverPub
            )
            let response = try WireGuardHandshake.sendAndAwait(
                host: session.endpointHost,
                port: session.listenPort,
                packet: initPacket,
                timeoutMs: timeoutMs
            )
            do {
                try WireGuardHandshake.consumeResponse(hsSession, response: response)
                return .ok
            } catch WireGuardHandshake.HandshakeException.badMac1 {
                return .badMac1
            } catch WireGuardHandshake.HandshakeException.aeadFailed {
                return .staleServerKey
            } catch {
                return .other(error.localizedDescription)
            }
        } catch let error as PreflightUDPError {
            switch error {
            case let .timeout(host, port, timeoutMs):
                return .noResponse(endpoint: "\(host):\(port)", timeoutMs: timeoutMs)
            case let .resolveFailed(host, port):
                return .other("Could not resolve \(host):\(port)")
            default:
                return .other(String(describing: error))
            }
        } catch {
            return .other(error.localizedDescription)
        }
    }

    public static func describe(_ result: Result) -> String {
        switch result {
        case .ok:
            return "WireGuard preflight OK"
        case let .noResponse(endpoint, timeoutMs):
            return "Exit node \(endpoint) did not respond to a WireGuard handshake in \(timeoutMs)ms. " +
                "The server may be down, blocked by a firewall, or the kernel WG interface is not up."
        case .badMac1:
            return "Exit node responded but with a wrong MAC. Another process is likely answering on the " +
                "WireGuard port. Try a different node."
        case .staleServerKey:
            return "Exit node responded but with a key that does not match what it advertised. The node " +
                "likely restarted; reconnect to refresh keys."
        case let .other(message):
            return "WireGuard preflight error: \(message)"
        }
    }
}

private extension Data {
    init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.count % 2 != 0 {
            hex = "0" + hex
        }
        var data = Data()
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard next <= hex.endIndex, let byte = UInt8(hex[index ..< next], radix: 16) else {
                return nil
            }
            data.append(byte)
            index = next
        }
        self = data
    }
}
