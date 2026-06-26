import Foundation
import ProtonCoreServices

public protocol PushNotificationServiceProtocol: AnyObject {
    func registerForRemoteNotifications(uid: String)
}

public protocol PushNotificationServiceFactory: AnyObject {
    func makePushNotificationService() -> PushNotificationServiceProtocol
}

public final class PushNotificationService: PushNotificationServiceProtocol {
    public static let shared = PushNotificationService(apiService: nil)

    public init(apiService _: APIService?) {}

    public func registerForRemoteNotifications(uid _: String) {}
}
