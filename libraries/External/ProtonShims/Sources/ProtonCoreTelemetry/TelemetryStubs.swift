import Foundation
import ProtonCoreServices

public final class TelemetryService {
    public static let shared = TelemetryService()

    private init() {}

    public func setApiService(apiService _: APIService) {}
    public func setTelemetryEnabled(_: Bool) {}
}
