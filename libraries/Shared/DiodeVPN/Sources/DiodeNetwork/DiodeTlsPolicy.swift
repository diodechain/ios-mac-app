import Foundation

/// TLS policy for Diode exit-node endpoints whose certificates are often issued for DNS names,
/// not the numeric IP literals returned by `dio_network`.
///
/// Android reference: `OkHttpTlsHelper` in `diode_vpn_android`.
///
/// ## Production behavior (Android parity)
/// - **IP-literal hosts** (`wss://157.x.x.x:8443/ws`): skip certificate hostname verification
///   because the directory already selected that numeric endpoint.
/// - **DNS hosts** (`wss://prenet.diode.io:8443/ws`): use standard system trust evaluation.
///
/// ## Debug behavior (Android parity)
/// When `DEBUG_TRUST_ALL_TLS` is enabled in debug builds, all HTTPS/WSS calls may bypass
/// verification to work around transient operator misconfiguration (prenet, geo, console RPC).
///
/// ## iOS/macOS stub
/// URLSession does not expose OkHttp-style per-request trust managers. Integrators should
/// attach a `URLSessionDelegate` that applies the rules above via `urlSession(_:didReceive:completionHandler:)`
/// when connecting to inet-literal Diode nodes. This type documents the policy only.
public enum DiodeTlsPolicy {
    public static let debugTrustAllTLS = true

    /// `true` when [wsURL]'s host is only an IP literal (IPv4 dotted decimal or IPv6).
    public static func websocketHostIsStrictInetLiteral(_ wsURL: String) -> Bool {
        guard let host = URL(string: wsURL)?.host?.split(separator: "%", maxSplits: 1).first.map(String.init) else {
            return false
        }
        if strictIPv4.firstMatch(in: host, range: NSRange(host.startIndex..., in: host)) != nil {
            return true
        }
        if host.contains(":") {
            return isValidIPv6(host)
        }
        return false
    }

    /// Mirrors `OkHttpTlsHelper.shouldTrustAllCertificatesForWebSocketUrl`.
    public static func shouldTrustAllCertificatesForWebSocketURL(_ wsURL: String) -> Bool {
        websocketHostIsStrictInetLiteral(wsURL) ||
            (isDebugBuild && debugTrustAllTLS)
    }

    /// Mirrors `OkHttpTlsHelper.applyUnsafeTrustAllIfDebug` for non-RPC HTTP callers.
    public static func shouldTrustAllCertificatesForDebugHTTP() -> Bool {
        isDebugBuild && debugTrustAllTLS
    }

    private static let strictIPv4 = try! NSRegularExpression(
        pattern: "^((25[0-5]|2[0-4]\\d|[01]?\\d\\d?)\\.){3}(25[0-5]|2[0-4]\\d|[01]?\\d\\d?)$"
    )

    private static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private static func isValidIPv6(_ host: String) -> Bool {
        var addr = in6_addr()
        return host.withCString { inet_pton(AF_INET6, $0, &addr) == 1 }
    }
}
