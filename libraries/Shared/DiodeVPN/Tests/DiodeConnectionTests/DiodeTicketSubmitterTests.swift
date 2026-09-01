import DiodeCrypto
import DiodeTicket
import XCTest
@testable import DiodeConnection

final class DiodeTicketSubmitterTests: XCTestCase {
    func testApplyFleetHintNormalizesHexPrefix() throws {
        let base = TicketV2.Params(
            chainID: NetworkConfigConstants.moonbeamChainID,
            epoch: 1,
            fleetContract20: Data(repeating: 0x11, count: 20),
            serverID20: Data(repeating: 0x22, count: 20),
            totalConnections: 0,
            totalBytes: 4096,
            localAddress: "0xabc"
        )
        let updated = DiodeTicketSubmitter.applyFleetHint(to: base, fleetHintHex: "0xdead")
        XCTAssertEqual(updated.fleetContract20, try DiodeHex.decode("dead"))
    }
}
