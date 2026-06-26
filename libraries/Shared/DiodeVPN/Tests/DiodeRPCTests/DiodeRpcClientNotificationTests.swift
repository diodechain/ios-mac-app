import XCTest
@testable import DiodeRPC

final class DiodeRpcClientNotificationTests: XCTestCase {
    func testParseTicketRequestNotificationDecodesUsageAndFleet() throws {
        let json = """
        {"jsonrpc":"2.0","method":"dio_ticket_request","params":{"usage":420000,"fleet":"0xdead"}}
        """
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        )
        let parsed = DiodeRpcClient.parseTicketRequestNotification(object)
        XCTAssertEqual(parsed?.usage, 420_000)
        XCTAssertEqual(parsed?.fleetHex, "0xdead")
    }

    func testParseTicketRequestNotificationHexUsage() throws {
        let json = """
        {"jsonrpc":"2.0","method":"dio_ticket_request","params":{"usage":"0x64f40","fleet":"dead"}}
        """
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        )
        let parsed = DiodeRpcClient.parseTicketRequestNotification(object)
        XCTAssertEqual(parsed?.usage, 413_504)
        XCTAssertEqual(parsed?.fleetHex, "dead")
    }

    func testDispatchNotificationInvokesLifecycleListener() throws {
        let json = """
        {"jsonrpc":"2.0","method":"dio_ticket_request","params":{"usage":420000,"fleet":"0xdead"}}
        """
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        )

        let listener = MockLifecycleListener()
        let client = DiodeRpcClient(wsURL: "wss://example.test/ws", lifecycleListener: listener)
        client.dispatchNotification(object)

        XCTAssertEqual(listener.usages, [420_000])
        XCTAssertEqual(listener.fleets, ["0xdead"])
    }

    func testParseTicketRequestNotificationRejectsMalformedPayload() throws {
        let json = #"{"jsonrpc":"2.0","method":"dio_ticket_request","params":{"fleet":"0xdead"}}"#
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
        )
        XCTAssertNil(DiodeRpcClient.parseTicketRequestNotification(object))
    }
}

private final class MockLifecycleListener: DiodeRpcClient.RpcLifecycleListener {
    private(set) var usages: [UInt64] = []
    private(set) var fleets: [String?] = []
    private(set) var closeReasons: [String] = []

    func onTicketRequest(usage: UInt64, fleetHex: String?) {
        usages.append(usage)
        fleets.append(fleetHex)
    }

    func onRpcClosed(reason: String) {
        closeReasons.append(reason)
    }
}
