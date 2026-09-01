import Foundation
import ProtonCoreNetworking
import ProtonCoreServices
import StoreKit

public enum IAPSupportStatusV2: Sendable {
    case enabled
    case disabled(localizedReason: String)
}

public struct AvailablePlan: Sendable {
    public var name: String
    public var instances: [PlanInstance]

    public init(name: String, instances: [PlanInstance] = []) {
        self.name = name
        self.instances = instances
    }
}

public struct PlanInstance: Sendable {
    public var cycle: Int
    public var amount: Int
    public var currency: String

    public init(cycle: Int = 12, amount: Int = 0, currency: String = "USD") {
        self.cycle = cycle
        self.amount = amount
        self.currency = currency
    }
}

public struct ComposedPlan: Sendable {
    public let plan: AvailablePlan
    public let instance: PlanInstance
    public let product: Product?

    public init(plan: AvailablePlan, instance: PlanInstance, product: Product? = nil) {
        self.plan = plan
        self.instance = instance
        self.product = product
    }
}

public struct CurrentSubscriptionResponse: Sendable {
    public var id: String
    public var name: String
    public var title: String
    public var description: String
    public var cycle: Int

    public init(
        id: String = "",
        name: String = "",
        title: String = "",
        description: String = "",
        cycle: Int = 12
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.description = description
        self.cycle = cycle
    }
}

public enum ProtonPlansManagerError: Error {
    case transactionCancelledByUser
    case transactionUnknownError
    case noUnfinshedTransactionsFound
    case unableToRestorePurchases
}

public protocol RemoteManagerProviding {}
public protocol PlansComposerProviding {}
public protocol PublicProtonPlansManagerProviding {}

public final class PaymentsV2 {
    public init() {}
}

public enum ViewCycleState {
    case idle
}
