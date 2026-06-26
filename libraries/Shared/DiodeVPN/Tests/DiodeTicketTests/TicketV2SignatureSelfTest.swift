import XCTest
@testable import DiodeCrypto
@testable import DiodeTicket

/// Ensures TicketV2 signing matches Diode Elixir `Secp256k1.sign(..., :kec)` / `recover!` (Keccak-256 of device_blob).
final class TicketV2SignatureSelfTest: XCTestCase {
    func testSignDeviceBlobRecoversToSameAddressAsPrivateKey() throws {
        let priv32 = Data(repeating: 3, count: 32)
        let expected = try Secp256k1Signer.address0x(fromPrivateKey32: priv32).lowercased()

        let fleet = Data(repeating: 1, count: 20)
        let server = Data(repeating: 2, count: 20)
        let params = TicketV2.Params(
            chainID: NetworkConfigConstants.moonbeamChainID,
            epoch: 7,
            fleetContract20: fleet,
            serverID20: server,
            totalConnections: 1,
            totalBytes: 4096,
            localAddress: "rpc_test"
        )

        let blob = try TicketV2.buildDeviceBlob(params)
        let sig65 = try TicketV2.signDeviceBlob(blob, privateKey32: priv32)
        XCTAssertEqual(sig65.count, 65)

        let digest = Keccak256.hash(blob)
        let recoveredAddr = try Secp256k1Signer.recoverAddress0x(digest32: digest, signature65: sig65).lowercased()
        XCTAssertEqual(
            recoveredAddr,
            expected,
            "Ticket signature must recover to the signing key's Ethereum address"
        )

        let hex = try TicketV2.ticketHexForRpc(params, privateKey32: priv32)
        _ = try DiodeHex.decode(hex)
        XCTAssertGreaterThan(hex.count, 2)
    }
}
