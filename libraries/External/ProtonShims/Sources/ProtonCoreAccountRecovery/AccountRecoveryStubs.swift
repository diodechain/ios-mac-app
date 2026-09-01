import Foundation
import ProtonCoreDataModel
import ProtonCoreFeatureFlags
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreUIFoundations

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
    public typealias UIViewController = NSViewController
#endif

public enum AccountRecoveryModule {
    public static let feature: any FeatureFlagTypeProtocol = CoreFeatureFlagType.accountRecovery
    public static let settingsItem = "Account recovery"

    public static func settingsViewController(
        _: APIService,
        completion: @escaping (AccountRecovery?) -> Void
    ) -> AccountRecoveryViewController {
        completion(nil)
        return AccountRecoveryViewController()
    }
}

public final class AccountRecoveryViewController: UIViewController {}
