import XCTest
@testable import DiodeConnection

final class DiodeSubscriptionEntitlementEvaluatorTests: XCTestCase {
    func testHasActiveEntitlementMatchesYearlyProductId() {
        XCTAssertTrue(
            DiodeSubscriptionEntitlementEvaluator.hasActiveEntitlement(
                entitledProductIDs: ["other", "diode_vpn_yearly"],
                yearlyProductId: "diode_vpn_yearly"
            )
        )
    }

    func testHasActiveEntitlementReturnsFalseForMissingProduct() {
        XCTAssertFalse(
            DiodeSubscriptionEntitlementEvaluator.hasActiveEntitlement(
                entitledProductIDs: ["iosvpn_vpn2022_12_usd_auto_renewing"],
                yearlyProductId: "diode_vpn_yearly"
            )
        )
    }

    func testHasActiveEntitlementReturnsFalseForEmptyYearlyProductId() {
        XCTAssertFalse(
            DiodeSubscriptionEntitlementEvaluator.hasActiveEntitlement(
                entitledProductIDs: ["diode_vpn_yearly"],
                yearlyProductId: ""
            )
        )
    }

    func testIsEntitledProductMatchesConfiguredId() {
        XCTAssertTrue(
            DiodeSubscriptionEntitlementEvaluator.isEntitledProduct(
                "diode_vpn_yearly",
                yearlyProductId: "diode_vpn_yearly"
            )
        )
        XCTAssertFalse(
            DiodeSubscriptionEntitlementEvaluator.isEntitledProduct(
                "other_product",
                yearlyProductId: "diode_vpn_yearly"
            )
        )
    }
}
