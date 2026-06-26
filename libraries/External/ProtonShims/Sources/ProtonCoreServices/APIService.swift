import Foundation
import ProtonCoreDoh

public protocol APIService: AnyObject {
    var dohInterface: DoH { get }
}

public protocol APIServiceDelegate: AnyObject {
    var additionalHeaders: [String: String]? { get }
    var locale: String { get }
    var appVersion: String { get }
    var userAgent: String? { get }
    func onUpdate(serverTime: Int64)
    func isReachable() -> Bool
    func onDohTroubleshot()
}

public extension APIServiceDelegate {
    var additionalHeaders: [String: String]? { nil }
    var locale: String { "en_US" }
    var appVersion: String { "0.0.0" }
    var userAgent: String? { nil }
    func onUpdate(serverTime: Int64) {}
    func isReachable() -> Bool { true }
    func onDohTroubleshot() {}
}

public protocol AuthSessionInvalidatedDelegate: AnyObject {
    func sessionWasInvalidated(for sessionUID: String, isAuthenticatedSession: Bool)
}

public enum SessionAcquiringResult {
    case sessionAlreadyPresent(credential: Any?)
    case sessionFetchedAndAvailable(credential: Any?)
}

public extension SessionAcquiringResult {
    func get() throws -> Self { self }
}

public enum ClientApp: String {
    case vpn
    case mail
    case calendar
    case drive
    case pass
}

public enum SettingsEndpoint: String {
    case settings
}
