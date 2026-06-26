import Foundation
import ProtonCoreNetworking
import ProtonCoreServices

public final class HumanCheckHelper: HumanVerifyDelegate {
    public var responseDelegateForLoginAndSignup: HumanVerifyResponseDelegate?
    public var paymentDelegateForLoginAndSignup: HumanVerifyPaymentDelegate?

    public init(
        apiService _: APIService,
        supportURL _: URL,
        inAppTheme _: @escaping () -> Any,
        clientApp _: ClientApp
    ) {}

    public func onHumanVerify(
        parameters _: HumanVerifyParameters,
        currentURL _: URL?,
        completion: @escaping (HumanVerifyFinishReason) -> Void
    ) {
        completion(.cancelled)
    }

    public func onDeviceVerify(parameters _: DeviceVerifyParameters) -> String? { nil }
    public func getSupportURL() -> URL { URL(string: "https://proton.me/support")! }
}
