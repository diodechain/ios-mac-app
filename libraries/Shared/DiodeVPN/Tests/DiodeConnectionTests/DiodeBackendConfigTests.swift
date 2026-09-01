import XCTest
@testable import DiodeConnection
import DiodeNetwork

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

    func testVpnYearlyProductIdFallback() {
        XCTAssertEqual(DiodeBackendConfig.vpnYearlyProductId, "diode_vpn_yearly")
    }

    func testConsoleApiKeyEmptyWithoutInjection() {
        XCTAssertEqual(DiodeBackendConfig.consoleApiKey, "")
    }

    func testConsoleFleetUuidFallsBackToPublicNetworkConfig() {
        XCTAssertEqual(
            DiodeBackendConfig.consoleFleetUuid,
            NetworkConfig.diodeConsoleFleetUUID
        )
    }

    func testConsoleApiKeyUsesInjectedValue() {
        DiodeBackendConfig.configure(
            consoleApiKey: "dck_test",
            consoleFleetUuid: "",
            vpnYearlyProductId: ""
        )
        XCTAssertEqual(DiodeBackendConfig.consoleApiKey, "dck_test")
    }
}
