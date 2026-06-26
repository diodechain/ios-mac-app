import XCTest
@testable import DiodeConnection

final class DiodeBackendConfigTests: XCTestCase {
    override func tearDown() {
        DiodeBackendConfig.configure(
            consoleApiKey: "",
            consoleFleetUuid: "",
            vpnYearlyProductId: ""
        )
        super.tearDown()
    }

    func testVpnYearlyProductIdUsesInjectedValue() {
        DiodeBackendConfig.configure(
            consoleApiKey: "key",
            consoleFleetUuid: "fleet",
            vpnYearlyProductId: "com.diode.vpn.yearly"
        )
        XCTAssertEqual(DiodeBackendConfig.vpnYearlyProductId, "com.diode.vpn.yearly")
    }

    #if DEBUG
    func testVpnYearlyProductIdDebugFallback() {
        XCTAssertEqual(DiodeBackendConfig.vpnYearlyProductId, "diode_vpn_yearly")
    }
    #endif
}
