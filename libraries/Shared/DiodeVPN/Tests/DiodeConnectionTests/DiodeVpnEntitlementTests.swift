import XCTest
@testable import DiodeConnection

final class DiodeVpnEntitlementTests: XCTestCase {
    override func tearDown() {
        DiodeSubscriptionStatus.shared.setActive(false)
        super.tearDown()
    }

    func testHasEntitlementWithActiveSubscription() {
        DiodeSubscriptionStatus.shared.setActive(true)
        XCTAssertTrue(DiodeVpnEntitlement.hasEntitlement(debug: false, demoActive: false))
    }

    func testHasEntitlementWithoutSubscription() {
        DiodeSubscriptionStatus.shared.setActive(false)
        XCTAssertFalse(DiodeVpnEntitlement.hasEntitlement(debug: false, demoActive: false))
    }

    func testHasEntitlementWithDemoActive() {
        DiodeSubscriptionStatus.shared.setActive(false)
        XCTAssertTrue(DiodeVpnEntitlement.hasEntitlement(debug: false, demoActive: true))
    }

    #if DEBUG
    func testDebugBypassAllowsEntitlementWithoutSubscription() {
        DiodeSubscriptionStatus.shared.setActive(false)
        XCTAssertTrue(DiodeVpnEntitlement.hasEntitlement())
    }
    #endif
}
