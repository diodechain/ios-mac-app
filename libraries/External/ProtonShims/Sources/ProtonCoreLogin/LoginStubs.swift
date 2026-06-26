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
    public init() {}
}

public struct Fido2Signature {
    public init(credentialAssertion _: Any, authenticationOptions _: AuthenticationOptions) {}
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
    case twoFactorRequired(AuthenticationOptions?)
    case ssoChallenge(URLRequest)
}

public enum LoginError: Error {
    case generic(message: String?, code: Int, originalError: Error)
    case wrongCredentials
    case apiMightBeBlocked
    case invalidResponse
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
