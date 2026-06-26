import Foundation
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCorePayments
import ProtonCoreServices
import ProtonCoreUIFoundations

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
    public typealias UIViewController = NSViewController
#endif

public final class LoginAndSignup {
    public init(
        appName _: String,
        clientApp _: ClientApp,
        apiService _: APIService,
        minimumAccountType _: AccountType,
        isCloseButtonAvailable _: Bool = false,
        paymentsAvailability _: PaymentsAvailability = .notAvailable,
        signupAvailability _: SignupAvailability = .unavailable,
        ssoCallbackScheme _: String
    ) {}

    public func welcomeScreenForPresentingFlow(
        variant _: WelcomeScreenVariant,
        customization _: LoginCustomizationOptions,
        updateBlock _: @escaping (LoginAndSignupResult) -> Void
    ) -> UIViewController {
        StubViewController()
    }

    public func presentLoginFlow(
        over _: UIViewController,
        customization _: LoginCustomizationOptions,
        updateBlock _: @escaping (LoginAndSignupResult) -> Void
    ) {}

    public func presentSignupFlow(
        over _: UIViewController,
        customization _: LoginCustomizationOptions,
        updateBlock _: @escaping (LoginAndSignupResult) -> Void
    ) {}
}

public protocol LoginAndSignupInterface: AnyObject {
    func welcomeScreenForPresentingFlow(
        variant: WelcomeScreenVariant,
        customization: LoginCustomizationOptions,
        updateBlock: @escaping (LoginAndSignupResult) -> Void
    ) -> UIViewController
    func presentLoginFlow(
        over: UIViewController,
        customization: LoginCustomizationOptions,
        updateBlock: @escaping (LoginAndSignupResult) -> Void
    )
    func presentSignupFlow(
        over: UIViewController,
        customization: LoginCustomizationOptions,
        updateBlock: @escaping (LoginAndSignupResult) -> Void
    )
}

extension LoginAndSignup: LoginAndSignupInterface {}

private final class StubViewController: UIViewController {}

public enum WelcomeScreenVariant {
    case vpn(WelcomeScreenTexts)
    case vpnV2(WelcomeScreenTexts)
}

public struct WelcomeScreenTexts {
    public let body: String

    public init(body: String) {
        self.body = body
    }
}

public struct LoginCustomizationOptions {
    public var username: String?
    public var performBeforeFlow: WorkBeforeFlow?
    public var customErrorPresenter: LoginErrorPresenter?
    public var initialError: String?
    public var helpDecorator: (([[HelpItem]]) -> [[HelpItem]])?
    public var closeSignupFlowAlertConfirmation: CloseSignupFlowAlertConfirmation?

    public init(
        username: String? = nil,
        performBeforeFlow: WorkBeforeFlow? = nil,
        customErrorPresenter: LoginErrorPresenter? = nil,
        initialError: String? = nil,
        helpDecorator: (([[HelpItem]]) -> [[HelpItem]])? = nil,
        closeSignupFlowAlertConfirmation: CloseSignupFlowAlertConfirmation? = nil
    ) {
        self.username = username
        self.performBeforeFlow = performBeforeFlow
        self.customErrorPresenter = customErrorPresenter
        self.initialError = initialError
        self.helpDecorator = helpDecorator
        self.closeSignupFlowAlertConfirmation = closeSignupFlowAlertConfirmation
    }
}

public struct CloseSignupFlowAlertConfirmation {
    public let title: String
    public let cancelButtonTitle: String
    public let continueButtonTitle: String

    public init(title: String, cancelButtonTitle: String, continueButtonTitle: String) {
        self.title = title
        self.cancelButtonTitle = cancelButtonTitle
        self.continueButtonTitle = continueButtonTitle
    }
}

public struct WorkBeforeFlow {
    public let stepName: String
    public let work: (LoginData, @escaping (Result<Void, Error>) -> Void) -> Void

    public init(stepName: String, work: @escaping (LoginData, @escaping (Result<Void, Error>) -> Void) -> Void) {
        self.stepName = stepName
        self.work = work
    }
}

public struct HelpItem {
    public let icon: ProtonIcon
    public let title: String
    public let behaviour: (UIViewController) -> Void

    public static func custom(
        icon: ProtonIcon,
        title: String,
        behaviour: @escaping (UIViewController) -> Void
    ) -> HelpItem {
        HelpItem(icon: icon, title: title, behaviour: behaviour)
    }
}

public enum LoginAndSignupResult {
    case dismissed
    case loginStateChanged(LoginStateChange)
    case signupStateChanged(SignupStateChange)
}

public enum LoginStateChange {
    case loginFinished
    case dataIsAvailable(LoginData)
}

public enum SignupStateChange {
    case signupFinished
    case dataIsAvailable(LoginData)
}

public protocol LoginErrorPresenter: AnyObject {
    func willPresentError(error: LoginError, from: UIViewController) -> Bool
    func willPresentError(error: SignupError, from: UIViewController) -> Bool
    func willPresentError(error: AvailabilityError, from: UIViewController) -> Bool
    func willPresentError(error: SetUsernameError, from: UIViewController) -> Bool
    func willPresentError(error: CreateAddressError, from: UIViewController) -> Bool
    func willPresentError(error: CreateAddressKeysError, from: UIViewController) -> Bool
    func willPresentError(error: StoreKitManagerErrors, from: UIViewController) -> Bool
    func willPresentError(error: ResponseError, from: UIViewController) -> Bool
    func willPresentError(error: Error, from: UIViewController) -> Bool
}

public enum SignupError: Error { case generic }
public enum AvailabilityError: Error { case generic }
public enum SetUsernameError: Error { case generic }
public enum CreateAddressError: Error { case generic }
public enum CreateAddressKeysError: Error { case generic }

public enum PMBannerNewStyle {
    case success
    case error
    case info
}

public final class PMBanner {
    public init(message _: String, style _: PMBannerNewStyle, dismissDuration _: TimeInterval) {}

    public func show(at _: PMBannerPosition, on _: UIViewController) {}
}

public enum PMBannerPosition {
    case top
    case bottom
}

public struct ExternalLinks {
    public let termsAndConditions: String
    public let privacyPolicy: String

    public init(clientApp _: ClientApp) {
        termsAndConditions = "https://proton.me/legal/terms"
        privacyPolicy = "https://proton.me/legal/privacy"
    }
}

public enum LoginUIModule {
    public static func makeSecurityKeysViewController(apiService _: APIService, clientApp _: ClientApp) -> SecurityKeysViewController? {
        nil
    }
}

public final class SecurityKeysViewController: UIViewController {}
