import Foundation
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreServices

public enum AccountType {
    case username
    case external
}

public enum LoginIntent {
    case proton
    case sso
}

public struct SSOResponseToken {
    public let token: String
    public let uid: String

    public init(token: String, uid: String) {
        self.token = token
        self.uid = uid
    }
}

public struct AuthenticationOptions {
    public let relyingPartyIdentifier: String
    public let challenge: Data
    public let allowedCredentialIds: [Data]

    public init(
        relyingPartyIdentifier: String = "",
        challenge: Data = Data(),
        allowedCredentialIds: [Data] = []
    ) {
        self.relyingPartyIdentifier = relyingPartyIdentifier
        self.challenge = challenge
        self.allowedCredentialIds = allowedCredentialIds
    }
}

public struct Fido2Signature {
    public let signature: Data
    public let credentialID: Data
    public let authenticatorData: Data
    public let clientData: Data
    public let authenticationOptions: AuthenticationOptions

    public init(
        signature: Data,
        credentialID: Data,
        authenticatorData: Data,
        clientData: Data,
        authenticationOptions: AuthenticationOptions
    ) {
        self.signature = signature
        self.credentialID = credentialID
        self.authenticatorData = authenticatorData
        self.clientData = clientData
        self.authenticationOptions = authenticationOptions
    }

    public init(credentialAssertion _: Any, authenticationOptions: AuthenticationOptions) {
        self.init(
            signature: Data(),
            credentialID: Data(),
            authenticatorData: Data(),
            clientData: Data(),
            authenticationOptions: authenticationOptions
        )
    }
}

public enum AvailableDomainsType {
    case login
    case signup
}

public struct LoginData {
    public let getCredential: Credential

    public init(getCredential: Credential) {
        self.getCredential = getCredential
    }
}

public enum LoginStatus {
    case finished(LoginData)
    case ssoChallenge(URLRequest)
    case askTOTP
    case askAny2FA(AuthenticationOptions)
    case askFIDO2(AuthenticationOptions)
    case askSecondPassword
    case chooseInternalUsernameAndCreateInternalAddress
}

public enum LoginError: Error {
    case generic(message: String?, code: Int, originalError: Error)
    case wrongCredentials
    case apiMightBeBlocked
    case invalidResponse
    case invalidAccessToken(message: String?)
    case invalidCredentials(message: String?)
    case invalid2FACode(message: String?)

    public var bestShotAtReasonableErrorCode: Int {
        switch self {
        case let .generic(_, code, _):
            code
        case .wrongCredentials, .invalidCredentials:
            401
        case .invalid2FACode:
            403
        case .invalidAccessToken:
            401
        case .apiMightBeBlocked:
            APIErrorCode.potentiallyBlocked
        case .invalidResponse:
            500
        }
    }

    public var userFacingMessageInLogin: String {
        switch self {
        case let .generic(message, _, _):
            message ?? "Login failed"
        case let .invalidAccessToken(message),
             let .invalidCredentials(message),
             let .invalid2FACode(message):
            message ?? "Login failed"
        case .wrongCredentials:
            "Wrong credentials"
        case .apiMightBeBlocked:
            "API might be blocked"
        case .invalidResponse:
            "Invalid response"
        }
    }
}

public final class LoginService: Login {
    public init(
        api _: APIService,
        clientApp _: ClientApp,
        minimumAccountType _: AccountType,
        ssoCallbackScheme _: String
    ) {}

    public func login(
        username _: String,
        password _: String,
        intent _: LoginIntent,
        challenge _: String?,
        completion: @escaping (Result<LoginStatus, LoginError>) -> Void
    ) {
        completion(.failure(.invalidResponse))
    }

    public func processResponseToken(
        idpEmail _: String,
        responseToken _: SSOResponseToken,
        completion: @escaping (Result<LoginStatus, LoginError>) -> Void
    ) {
        completion(.failure(.invalidResponse))
    }

    public func provide2FACode(_: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        completion(.failure(.invalidResponse))
    }

    public func provideFido2Signature(_: Fido2Signature, completion: @escaping (Result<LoginStatus, LoginError>) -> Void) {
        completion(.failure(.invalidResponse))
    }

    public func updateAllAvailableDomains(type _: AvailableDomainsType, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(()))
    }

    public func getSSORequest(challenge _: URLRequest) async -> (URLRequest?, String?) {
        (nil, "SSO is not available")
    }
}

public protocol Login: AnyObject {
    func login(
        username: String,
        password: String,
        intent: LoginIntent,
        challenge: String?,
        completion: @escaping (Result<LoginStatus, LoginError>) -> Void
    )
    func processResponseToken(
        idpEmail: String,
        responseToken: SSOResponseToken,
        completion: @escaping (Result<LoginStatus, LoginError>) -> Void
    )
    func provide2FACode(_ code: String, completion: @escaping (Result<LoginStatus, LoginError>) -> Void)
    func provideFido2Signature(_ signature: Fido2Signature, completion: @escaping (Result<LoginStatus, LoginError>) -> Void)
    func updateAllAvailableDomains(type _: AvailableDomainsType, completion: @escaping (Result<Void, Error>) -> Void)
    func getSSORequest(challenge: URLRequest) async -> (URLRequest?, String?)
}

public struct SignupParameters {
    public enum PasswordRestrictions {
        case `default`
    }

    public enum SummaryScreenVariant {
        case noSummaryScreen
    }

    public let separateDomainsButton: Bool
    public let passwordRestrictions: PasswordRestrictions
    public let summaryScreenVariant: SummaryScreenVariant

    public init(
        separateDomainsButton: Bool,
        passwordRestrictions: PasswordRestrictions,
        summaryScreenVariant: SummaryScreenVariant
    ) {
        self.separateDomainsButton = separateDomainsButton
        self.passwordRestrictions = passwordRestrictions
        self.summaryScreenVariant = summaryScreenVariant
    }
}

public enum SignupAvailability {
    case unavailable
    case available(parameters: SignupParameters)
}
