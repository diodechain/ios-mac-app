import Foundation
import ProtonCoreChallenge
import ProtonCoreDoh
import ProtonCoreServices

public struct ChallengeParametersProvider: Sendable {
    public static let empty = ChallengeParametersProvider()

    public static func forAPIService(clientApp _: ClientApp, challenge _: PMChallenge) -> ChallengeParametersProvider {
        .empty
    }
}
