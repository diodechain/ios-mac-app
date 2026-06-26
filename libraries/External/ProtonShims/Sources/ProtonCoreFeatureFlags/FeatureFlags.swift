import Foundation
@_exported import ProtonCoreUtilities
import ProtonCoreServices

public protocol FeatureFlagTypeProtocol {
    var rawValue: String { get }
}

public struct FeatureFlag: Sendable, Equatable {
    public let name: String
    public let enabled: Bool
    public let variant: String?

    public init(name: String, enabled: Bool, variant: String?) {
        self.name = name
        self.enabled = enabled
        self.variant = variant
    }
}

public enum CoreFeatureFlagType: String, CaseIterable, FeatureFlagTypeProtocol {
    case dynamicPlan = "DynamicPlan"
    case accountRecovery = "AccountRecovery"
    case pushNotifications = "PushNotifications"
    case credentialLessAccount = "CredentialLessAccount"
    case easyDeviceMigrationDisabled = "EasyDeviceMigrationDisabled"
    case changePassword = "ChangePassword"
    case paymentsOmnichannelEnabled = "PaymentsOmnichannelEnabled"
}

public final class FeatureFlagsRepository {
    public static let shared = FeatureFlagsRepository()

    private var overrides: [String: Bool] = [:]
    private var apiService: (any APIService)?
    private var userId: String?

    private init() {}

    public func setApiService(_ apiService: any APIService) {
        self.apiService = apiService
    }

    public func fetchFlags() async {}

    public func setUserId(_ userId: String?) {
        self.userId = userId
    }

    public func clearUserId() {
        userId = nil
    }

    public func resetFlags(for userId: String) {
        _ = userId
    }

    public func resetOverrides() {
        overrides.removeAll()
    }

    public func setFlagOverride(_ flag: any FeatureFlagTypeProtocol, _ value: Bool) {
        overrides[flag.rawValue] = value
    }

    public func resetFlagOverride(_ flag: any FeatureFlagTypeProtocol) {
        overrides.removeValue(forKey: flag.rawValue)
    }

    public func isEnabled(_ flag: any FeatureFlagTypeProtocol, reloadValue: Bool = false) -> Bool {
        _ = reloadValue
        if let override = overrides[flag.rawValue] {
            return override
        }
        if let core = flag as? CoreFeatureFlagType, core == .dynamicPlan {
            return true
        }
        return defaultEnabled(for: flag)
    }

    private func defaultEnabled(for flag: any FeatureFlagTypeProtocol) -> Bool {
        if flag.rawValue == "AllowSandboxPurchases" {
            return true
        }
        return false
    }
}
