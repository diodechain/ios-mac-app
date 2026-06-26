import Foundation

open class DoH: NSObject {
    public enum Status: Sendable {
        case on
        case off
    }

    public var status: Status = .off

    override public init() {
        super.init()
    }

    open func getCurrentlyUsedHostUrl() -> String { "" }
    open func getAccountHost() -> String { "" }
    open func getCaptchaHostUrl() -> String { "" }
    open func getHumanVerificationV3Host() -> String { "" }
    open func getAccountHeaders(for _: String) -> [String: String] { [:] }
    open func getHumanVerificationV3Headers() -> [String: String] { [:] }
    open func getAccountHeaders() -> [String: String] { [:] }
    open func getCaptchaHeaders() -> [String: String] { [:] }
    open func synchronizeCookies(with _: [String: String], completion: @escaping () -> Void) { completion() }
    open var currentlyUsedCookiesStorage: HTTPCookieStorage { .shared }
}

public protocol ServerConfig {
    var liveURL: String { get }
    var signupDomain: String { get }
    var defaultPath: String { get }
}

public func handleAuthenticationChallenge(
    didReceive _: URLAuthenticationChallenge,
    noTrustKit _: Bool,
    trustKit _: AnyObject?,
    challengeCompletionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
) {
    challengeCompletionHandler(.performDefaultHandling, nil)
}

public final class AlternativeRoutingRequestInterceptor {
    public init(
        headersGetter _: @escaping (String) -> [String: String],
        cookiesSynchronization _: @escaping ([String: String], @escaping () -> Void) -> Void,
        cookiesStorage _: HTTPCookieStorage,
        challengeHandler _: @escaping (URLAuthenticationChallenge, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void
    ) {}

    public func setup(webViewConfiguration _: Any) {}
}
