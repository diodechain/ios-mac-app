import Foundation
import ProtonCoreDataModel
import ProtonCoreFeatureFlags
import ProtonCoreNetworking
import ProtonCoreServices

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
    public typealias UIViewController = NSViewController
#endif

public enum PasswordChangeModule {
    public enum PasswordChangeMode {
        case singlePassword
        case loginAndMailbox
    }

    public static func makePasswordChangeViewController(
        mode _: PasswordChangeMode,
        apiService _: APIService,
        authCredential _: AuthCredential,
        userInfo _: UserInfo,
        completion: @escaping (AuthCredential, UserInfo) -> Void
    ) -> PasswordChangeViewController? {
        _ = completion
        return nil
    }
}

public final class PasswordChangeViewController: UIViewController {}
