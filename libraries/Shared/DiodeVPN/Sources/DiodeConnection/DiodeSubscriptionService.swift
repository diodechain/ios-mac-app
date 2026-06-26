import Foundation
import StoreKit

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

public enum DiodeSubscriptionError: Error, Equatable {
    case missingProductConfiguration
    case productNotFound
    case userCancelled
    case pending
    case verificationFailed
    case manageSubscriptionsUnavailable
    case unknown
}

/// Evaluates StoreKit entitlement product IDs without touching StoreKit (unit-testable).
public enum DiodeSubscriptionEntitlementEvaluator {
    public static func hasActiveEntitlement(
        entitledProductIDs: [String],
        yearlyProductId: String
    ) -> Bool {
        guard !yearlyProductId.isEmpty else { return false }
        return entitledProductIDs.contains(yearlyProductId)
    }

    public static func isEntitledProduct(
        _ productID: String,
        yearlyProductId: String
    ) -> Bool {
        !yearlyProductId.isEmpty && productID == yearlyProductId
    }
}

/// StoreKit 2 yearly subscription for Diode VPN (Android `SubscriptionManager` parity).
public final class DiodeSubscriptionService: @unchecked Sendable {
    public static let shared = DiodeSubscriptionService()

    private let lock = NSLock()
    private var observerTask: Task<Void, Never>?
    private var cachedProduct: Product?

    private init() {}

    public func start() {
        lock.lock()
        defer { lock.unlock() }
        guard observerTask == nil else { return }
        observerTask = Task { [weak self] in
            await self?.runTransactionObserver()
        }
    }

    public func stop() {
        lock.lock()
        observerTask?.cancel()
        observerTask = nil
        cachedProduct = nil
        lock.unlock()
    }

    public func loadProduct() async throws -> Product {
        if let cachedProduct {
            return cachedProduct
        }
        let productId = DiodeBackendConfig.vpnYearlyProductId
        guard !productId.isEmpty else {
            throw DiodeSubscriptionError.missingProductConfiguration
        }
        let products = try await Product.products(for: [productId])
        guard let product = products.first else {
            throw DiodeSubscriptionError.productNotFound
        }
        lock.lock()
        cachedProduct = product
        lock.unlock()
        return product
    }

    public func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case let .success(verification):
            let transaction = try verifiedTransaction(from: verification)
            await transaction.finish()
            await refreshEntitlements()
        case .userCancelled:
            throw DiodeSubscriptionError.userCancelled
        case .pending:
            throw DiodeSubscriptionError.pending
        @unknown default:
            throw DiodeSubscriptionError.unknown
        }
    }

    public func purchase() async throws {
        try await purchase(try await loadProduct())
    }

    public func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    @MainActor
    public func presentSubscriptionManagement() async throws {
        #if os(iOS)
            guard let scene = activeWindowScene() else {
                throw DiodeSubscriptionError.manageSubscriptionsUnavailable
            }
            try await AppStore.showManageSubscriptions(in: scene)
        #elseif os(macOS)
            throw DiodeSubscriptionError.manageSubscriptionsUnavailable
        #else
            throw DiodeSubscriptionError.manageSubscriptionsUnavailable
        #endif
    }

    public func refreshEntitlements() async {
        let yearlyProductId = DiodeBackendConfig.vpnYearlyProductId
        guard !yearlyProductId.isEmpty else {
            DiodeSubscriptionStatus.shared.setActive(false)
            return
        }

        var entitledProductIDs: [String] = []
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            entitledProductIDs.append(transaction.productID)
        }

        let isActive = DiodeSubscriptionEntitlementEvaluator.hasActiveEntitlement(
            entitledProductIDs: entitledProductIDs,
            yearlyProductId: yearlyProductId
        )
        DiodeSubscriptionStatus.shared.setActive(isActive)
    }

    private func runTransactionObserver() async {
        await refreshEntitlements()
        for await update in Transaction.updates {
            await handleTransactionUpdate(update)
        }
    }

    private func handleTransactionUpdate(_ update: VerificationResult<Transaction>) async {
        do {
            let transaction = try verifiedTransaction(from: update)
            await transaction.finish()
            await refreshEntitlements()
        } catch {
            await refreshEntitlements()
        }
    }

    private func verifiedTransaction<T>(
        from result: VerificationResult<T>
    ) throws -> T {
        switch result {
        case let .verified(value):
            return value
        case .unverified:
            throw DiodeSubscriptionError.verificationFailed
        }
    }

    #if os(iOS)
        @MainActor
        private func activeWindowScene() -> UIWindowScene? {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            return scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        }
    #endif
}
