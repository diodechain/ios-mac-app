import Foundation
import ProtonCoreDataModel
import ProtonCoreNetworking
import ProtonCoreServices

public enum ProtonCoreAuthentication {}

public protocol AuthService: AnyObject {}

public final class Authenticator {
    private let api: APIService

    public init(api: APIService) {
        self.api = api
    }

    public func getUserInfo(completion: @escaping (Result<User, Error>) -> Void) {
        completion(.success(User()))
    }

    public func getUserInfo() async throws -> User {
        User()
    }

    public func getUserSettings(_: Credential) async throws -> UserSettings {
        .default
    }

    public func getAddresses() async throws -> [Address] {
        []
    }
}
