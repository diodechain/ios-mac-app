//
//  DiodePaymentsPlanServiceV2.swift
//  PaymentsShared
//
//  StoreKit-backed PaymentsPlanServiceV2 shim for DIODE_BACKEND builds.

#if DIODE_BACKEND

import Dependencies
import DiodeConnection
import Domain
import Foundation
import PMLogger
import ProtonCorePaymentsV2
import StoreKit
import VPNAppCore

final class DiodePaymentsPlanServiceV2: PaymentsPlanServiceV2, @unchecked Sendable {
    private var cachedComposedPlan: ComposedPlan?

    var countryCode: String? {
        get async {
            await Storefront.current?.countryCode.lowercased()
        }
    }

    var countriesCount: Int {
        @Dependency(\.serverRepository) var serverRepository
        return serverRepository.countryCount()
    }

    var iapStatus: IAPSupportStatusV2 { .enabled }

    var mostExpensivePlan: ComposedPlan? {
        cachedComposedPlan
    }

    var arePaymentsAllowed: Bool { true }

    init() {
        DiodeSubscriptionService.shared.start()
    }

    func pushCantUpgradeAlert(
        localizedReason _: String?,
        presentAlert _: @escaping @Sendable (SystemAlert) -> Void
    ) {}

    func fetchIAPStatus() async throws -> IAPSupportStatusV2 {
        _ = try await DiodeSubscriptionService.shared.loadProduct()
        return .enabled
    }

    func getAvailablePlans() async throws -> [ComposedPlan] {
        let product = try await DiodeSubscriptionService.shared.loadProduct()
        let composedPlan = try makeComposedPlan(product: product)
        cachedComposedPlan = composedPlan
        return [composedPlan]
    }

    func purchase(_ product: Product) async throws -> ComposedPlan? {
        do {
            try await DiodeSubscriptionService.shared.purchase(product)
        } catch DiodeSubscriptionError.userCancelled {
            throw ProtonPlansManagerError.transactionCancelledByUser
        } catch {
            throw ProtonPlansManagerError.transactionUnknownError
        }

        guard DiodeSubscriptionStatus.shared.isActive else {
            throw ProtonPlansManagerError.transactionUnknownError
        }

        let plan = try await getAvailablePlans().first
        AppEvent.userDidCompletePurchase.post(
            PaymentTransactionFinishedEvent(
                newPlanName: plan?.plan.name ?? "vpn2022",
                cycle: plan?.instance.cycle ?? 12,
                offerReference: nil,
                flowType: .oneClick
            )
        )
        return plan
    }

    func presentSubscriptionManagement(
        presentAlert: @escaping @Sendable (SystemAlert) -> Void
    ) async {
        if DiodeSubscriptionStatus.shared.isActive {
            do {
                try await DiodeSubscriptionService.shared.presentSubscriptionManagement()
            } catch {
                log.error("Unable to present subscription management: \(error)", category: .iap)
            }
            return
        }

        do {
            let product = try await DiodeSubscriptionService.shared.loadProduct()
            _ = try await purchase(product)
        } catch ProtonPlansManagerError.transactionCancelledByUser {
            return
        } catch {
            log.error("Unable to start Diode subscription purchase: \(error)", category: .iap)
            presentAlert(PaymentAlert(message: error.localizedDescription, isError: true))
        }
    }

    func recoverTransaction() async throws {
        try await DiodeSubscriptionService.shared.restore()
        guard DiodeSubscriptionStatus.shared.isActive else {
            throw ProtonPlansManagerError.noUnfinshedTransactionsFound
        }
    }

    func restorePurchase() async throws -> CurrentSubscriptionResponse {
        try await DiodeSubscriptionService.shared.restore()
        guard DiodeSubscriptionStatus.shared.isActive else {
            throw ProtonPlansManagerError.unableToRestorePurchases
        }
        return CurrentSubscriptionResponse(
            id: DiodeBackendConfig.vpnYearlyProductId,
            name: "vpn2022",
            title: "Diode VPN",
            description: "Yearly subscription",
            cycle: 12,
            cycleDescription: nil,
            currency: nil,
            amount: nil,
            offer: nil,
            periodStart: nil,
            periodEnd: nil,
            createTime: nil,
            couponCode: nil,
            discount: nil,
            renewDiscount: nil,
            renewAmount: nil,
            renew: nil,
            external: nil,
            entitlements: [],
            decorations: []
        )
    }

    func clear() {
        cachedComposedPlan = nil
        DiodeSubscriptionService.shared.stop()
    }

    private func makeComposedPlan(product: Product) throws -> ComposedPlan {
        let instance = try decodeJSON(PlanInstance.self, from: planInstanceJSONObject(productId: product.id))
        let availablePlan = AvailablePlan(
            description: "Diode VPN yearly subscription",
            instances: [instance],
            name: "vpn2022",
            state: 1,
            title: "VPN Plus",
            features: 0,
            entitlements: [],
            decorations: [],
            ID: "diode-vpn-yearly",
            services: 4
        )
        return ComposedPlan(plan: availablePlan, instance: instance, product: product)
    }

    private func planInstanceJSONObject(productId: String) -> [String: Any] {
        [
            "price": [
                ["current": 0, "currency": "USD", "ID": "diode"],
            ],
            "description": "Yearly",
            "cycle": 12,
            "periodEnd": 0,
            "vendors": [
                "apple": [
                    "productID": productId,
                    "customerID": NSNull(),
                ],
            ],
        ]
    }

    private func decodeJSON<T: Decodable>(_ type: T.Type, from object: [String: Any]) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: object)
        return try JSONDecoder().decode(type, from: data)
    }
}

#endif
