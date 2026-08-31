import Foundation
@_exported import ProtonCoreAPIClient
import ProtonCoreDoh
import ProtonCoreFoundations
import ProtonCoreServices
import ProtonCoreUtilities

public typealias JSONDictionary = [String: Any]

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

public protocol Request {
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: [String: Any]? { get }
    var header: [String: Any] { get }
    var isAuth: Bool { get }
    var authRetry: Bool { get }
    var authCredential: AuthCredential? { get }
    var nonDefaultTimeout: TimeInterval? { get }
    var retryPolicy: ProtonRetryPolicy.RetryMode { get }
}

public extension Request {
    var method: HTTPMethod { .get }
    var parameters: [String: Any]? { nil }
    var header: [String: Any] { [:] }
    var isAuth: Bool { true }
    var authRetry: Bool { true }
    var authCredential: AuthCredential? { nil }
    var nonDefaultTimeout: TimeInterval? { nil }
    var retryPolicy: ProtonRetryPolicy.RetryMode { .background }
}

public protocol APIDecodableResponse: Decodable {}

public protocol AuthDelegate: AnyObject {
    var authSessionInvalidatedDelegateForLoginAndSignup: AuthSessionInvalidatedDelegate? { get set }
    func onAdditionalCredentialsInfoObtained(sessionUID: String, password: String?, salt: String?, privateKey: String?)
    func onAuthenticatedSessionInvalidated(sessionUID: String)
    func onUnauthenticatedSessionInvalidated(sessionUID: String)
    func onSessionObtaining(credential: Credential)
    func credential(sessionUID: String) -> Credential?
    func authCredential(sessionUID: String) -> AuthCredential?
    func onLogout(sessionUID: String)
    func onUpdate(credential: Credential, sessionUID: String)
    func onForceUpgrade()
}

public extension AuthDelegate {
    func onForceUpgrade() {}
}

public protocol ForceUpgradeDelegate: AnyObject {
    func onForceUpgrade(message: String)
}

public protocol HumanVerifyDelegate: AnyObject {
    var responseDelegateForLoginAndSignup: HumanVerifyResponseDelegate? { get set }
    var paymentDelegateForLoginAndSignup: HumanVerifyPaymentDelegate? { get set }
    func onHumanVerify(parameters: HumanVerifyParameters, currentURL: URL?, completion: @escaping (HumanVerifyFinishReason) -> Void)
    func onDeviceVerify(parameters: DeviceVerifyParameters) -> String?
    func getSupportURL() -> URL
}

public protocol HumanVerifyResponseDelegate: AnyObject {}
public protocol HumanVerifyPaymentDelegate: AnyObject {}

public struct HumanVerifyParameters {
    public init() {}
}

public struct DeviceVerifyParameters {
    public init() {}
}

public enum HumanVerifyFinishReason {
    case success
    case cancelled
    case verification(header: [String: Any], verificationCodeBlock: ((@escaping (String) -> Void) -> Void)?)
}

public struct Credential: Sendable {
    public let UID: String
    public var accessToken: String
    public var refreshToken: String
    public let userName: String
    public let userID: String
    public var scopes: [String]
    public var mailboxPassword: String
    public var isCredentialLess: Bool

    public init(
        UID: String,
        accessToken: String,
        refreshToken: String,
        userName: String,
        userID: String,
        scopes: [String],
        mailboxPassword: String = "",
        isCredentialLess: Bool = false
    ) {
        self.UID = UID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userName = userName
        self.userID = userID
        self.scopes = scopes
        self.mailboxPassword = mailboxPassword
        self.isCredentialLess = isCredentialLess
    }

    public var isForUnauthenticatedSession: Bool {
        scopes.contains("session") && userID.isEmpty
    }
}

public extension Credential {
    init(_ authCredential: AuthCredential) {
        self.init(
            UID: authCredential.sessionID,
            accessToken: authCredential.accessToken,
            refreshToken: authCredential.refreshToken,
            userName: "",
            userID: "",
            scopes: authCredential.scopes,
            mailboxPassword: authCredential.mailboxPassword,
            isCredentialLess: authCredential.isCredentialLess
        )
    }
}

public final class AuthCredential: NSObject {
    public var accessToken: String
    public var refreshToken: String
    public let sessionID: String
    public var scopes: [String]
    public var mailboxPassword: String = ""
    public var isCredentialLess: Bool = false
    public var userID: String = ""
    private var password: String?
    private var salt: String?
    private var privateKey: String?

    public init(_ credential: Credential) {
        self.accessToken = credential.accessToken
        self.refreshToken = credential.refreshToken
        self.sessionID = credential.UID
        self.scopes = credential.scopes
        self.mailboxPassword = credential.mailboxPassword
        self.isCredentialLess = credential.isCredentialLess
        self.userID = credential.userID
        super.init()
    }

    public var isForUnauthenticatedSession: Bool {
        scopes.contains("session")
    }

    public func update(password: String) {
        self.password = password
    }

    public func update(salt: String, privateKey: String) {
        self.salt = salt
        self.privateKey = privateKey
    }

    public func archive() -> Data {
        let payload = ArchivePayload(
            accessToken: accessToken,
            refreshToken: refreshToken,
            sessionID: sessionID,
            scopes: scopes,
            mailboxPassword: mailboxPassword,
            isCredentialLess: isCredentialLess
        )
        return (try? JSONEncoder().encode(payload)) ?? Data()
    }

    public static func unarchive(data: NSData) -> AuthCredential? {
        guard let payload = try? JSONDecoder().decode(ArchivePayload.self, from: data as Data) else {
            return nil
        }
        let credential = AuthCredential(
            Credential(
                UID: payload.sessionID,
                accessToken: payload.accessToken,
                refreshToken: payload.refreshToken,
                userName: "",
                userID: "",
                scopes: payload.scopes,
                mailboxPassword: payload.mailboxPassword,
                isCredentialLess: payload.isCredentialLess
            )
        )
        return credential
    }

    private struct ArchivePayload: Codable {
        let accessToken: String
        let refreshToken: String
        let sessionID: String
        let scopes: [String]
        let mailboxPassword: String
        let isCredentialLess: Bool
    }
}

public enum ResponseError: Error {
    case unknownError
    case httpError(code: Int, message: String?)
    case generic(message: String?, code: Int, underlyingError: Error?)
    case apiError(httpCode: Int, responseCode: Int, userFacingMessage: String?, underlyingError: Error?)

    public var underlyingError: Error? {
        switch self {
        case let .generic(_, _, underlying):
            underlying
        case let .apiError(_, _, _, underlying):
            underlying
        default:
            nil
        }
    }

    public init(
        httpCode: Int,
        responseCode: Int,
        userFacingMessage: String?,
        underlyingError: Error?
    ) {
        self = .apiError(
            httpCode: httpCode,
            responseCode: responseCode,
            userFacingMessage: userFacingMessage,
            underlyingError: underlyingError
        )
    }
}

public enum HttpStatusCode: Int {
    case notModified = 304
}

public final class PMAPIService: APIService {
    public static var noTrustKit = true
    public static var trustKit: AnyObject?

    public weak var authDelegate: AuthDelegate?
    public weak var serviceDelegate: APIServiceDelegate?
    public weak var forceUpgradeDelegate: ForceUpgradeDelegate?
    public weak var humanDelegate: HumanVerifyDelegate?

    public let dohInterface: DoH

    public init(dohInterface: DoH) {
        self.dohInterface = dohInterface
    }

    public static func createAPIService(
        doh: DoH,
        sessionUID _: String,
        challengeParametersProvider _: ChallengeParametersProvider
    ) -> PMAPIService {
        PMAPIService(dohInterface: doh)
    }

    public static func createAPIServiceWithoutSession(
        doh: DoH,
        challengeParametersProvider _: ChallengeParametersProvider
    ) -> PMAPIService {
        PMAPIService(dohInterface: doh)
    }

    public func getSession() -> URLSession? {
        URLSession.shared
    }

    public func setSessionUID(uid _: String) {}

    public func acquireSessionIfNeeded(completion: @escaping (Result<SessionAcquiringResult, Error>) -> Void) {
        completion(.success(.sessionAlreadyPresent(AcquiredSessionCredential())))
    }

    public func acquireSessionIfNeeded() async throws -> Result<SessionAcquiringResult, Error> {
        .success(.sessionAlreadyPresent(AcquiredSessionCredential()))
    }

    public func request(
        method _: HTTPMethod,
        path _: String,
        parameters _: [String: Any]?,
        headers _: [String: Any],
        authenticated _: Bool,
        authRetry _: Bool,
        customAuthCredential _: AuthCredential?,
        nonDefaultTimeout _: TimeInterval?,
        retryPolicy _: Any?,
        completion: @escaping (URLSessionDataTask?, Result<JSONDictionary, Error>) -> Void
    ) {
        completion(nil, .success([:]))
    }

    public func perform<T: Decodable>(
        request _: Request,
        completion: @escaping (URLSessionDataTask?, Result<T, ResponseError>) -> Void
    ) {
        completion(nil, .failure(.unknownError))
    }

    public func perform<T: Decodable>(request _: Request) async throws -> (URLSessionDataTask?, T) {
        throw ResponseError.unknownError
    }

    public func perform(request _: Request) async throws -> (URLSessionDataTask?, JSONDictionary) {
        (nil, [:])
    }

    public func performUpload<T: Decodable>(
        request _: Request,
        files _: [String: URL],
        uploadProgress _: ((Progress) -> Void)?,
        completion: @escaping (URLSessionDataTask?, Result<T, ResponseError>) -> Void
    ) {
        completion(nil, .failure(.unknownError))
    }
}

extension PMAPIService: APIServiceDelegate {}
