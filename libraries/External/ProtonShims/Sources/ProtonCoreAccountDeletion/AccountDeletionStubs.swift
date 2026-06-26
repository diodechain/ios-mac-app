import Foundation
import ProtonCoreNetworking
import ProtonCoreServices

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
    public typealias UIViewController = NSViewController
#endif

public final class AccountDeletionService {
    public static let defaultButtonName = "Delete account"
    public static let defaultExplanationMessage = "Account deletion is not available in this build."

    private let api: APIService

    public init(api: APIService) {
        self.api = api
    }

    public func initiateAccountDeletionProcess(
        over _: UIViewController,
        performAfterShowingAccountDeletionScreen: @escaping () -> Void,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        performAfterShowingAccountDeletionScreen()
        completion(.failure(NSError(domain: "ProtonShims", code: 1)))
    }
}
