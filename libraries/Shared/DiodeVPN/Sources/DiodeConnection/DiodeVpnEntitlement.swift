import Foundation

/// Mirrors Android `hasVpnEntitlement(debug, hasSubscription, demoActive)`.
/// `hasSubscription` reflects StoreKit entitlements via `DiodeSubscriptionService`.
public enum DiodeVpnEntitlement {
    public static func hasEntitlement(
        debug: Bool = {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }(),
        hasSubscription: Bool = DiodeSubscriptionStatus.shared.isActive,
        demoActive: Bool = false
    ) -> Bool {
        debug || hasSubscription || demoActive
    }
}

/// Updated by `DiodeSubscriptionService` when StoreKit entitlements change.
public final class DiodeSubscriptionStatus: @unchecked Sendable {
    public static let shared = DiodeSubscriptionStatus()
    private let lock = NSLock()
    private var _isActive = false

    public var isActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isActive
    }

    public func setActive(_ active: Bool) {
        lock.lock()
        _isActive = active
        lock.unlock()
    }
}
