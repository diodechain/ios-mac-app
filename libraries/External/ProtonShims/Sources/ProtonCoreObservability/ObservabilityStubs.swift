import Foundation
import ProtonCoreNetworking
import ProtonCoreServices

public protocol ObservabilityRequestPerformer {}

public enum ObservabilityEvent {
    case ssoIdentityProviderLoginResult(status: SSOIdentityProviderLoginStatus)
}

public enum SSOIdentityProviderLoginStatus {
    case successful
    case failed
}

public final class ObservabilityEnv {
    public static var current = ObservabilityEnv()

    public func setupWorld(requestPerformer _: APIService) {}

    public static func report(_: ObservabilityEvent) {}
}
