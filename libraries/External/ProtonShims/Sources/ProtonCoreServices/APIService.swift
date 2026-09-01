import Foundation
import ProtonCoreDoh

public struct AcquiredSessionCredential {
    public let userID: String

    public init(userID: String = "") {
        self.userID = userID
    }
}

public enum SessionAcquiringResult {
    case sessionAlreadyPresent(AcquiredSessionCredential)
    case sessionFetchedAndAvailable(AcquiredSessionCredential)
    case sessionUnavailable
}

public protocol APIService: AnyObject {
    var dohInterface: DoH { get }

    func acquireSessionIfNeeded(completion: @escaping (Result<SessionAcquiringResult, Error>) -> Void)
    func acquireSessionIfNeeded() async throws -> Result<SessionAcquiringResult, Error>
    func setSessionUID(uid: String)
    func getSession() -> URLSession?
}

public extension APIService {
    func acquireSessionIfNeeded(completion: @escaping (Result<SessionAcquiringResult, Error>) -> Void) {
        completion(.success(.sessionUnavailable))
    }

    func acquireSessionIfNeeded() async throws -> Result<SessionAcquiringResult, Error> {
        .success(.sessionUnavailable)
    }

    func setSessionUID(uid _: String) {}

    func getSession() -> URLSession? { nil }
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
    func onUpdate(serverTime _: Int64) {}
    func isReachable() -> Bool { true }
    func onDohTroubleshot() {}
}

public protocol AuthSessionInvalidatedDelegate: AnyObject {
    func sessionWasInvalidated(for sessionUID: String, isAuthenticatedSession: Bool)
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
