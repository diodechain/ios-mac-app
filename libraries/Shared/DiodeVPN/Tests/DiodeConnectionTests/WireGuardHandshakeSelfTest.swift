import XCTest
@testable import DiodeConnection

final class WireGuardHandshakeSelfTest: XCTestCase {
    func testAeadRoundTrip() throws {
        let key = Data((1 ... 32).map { UInt8($0) })
        let plaintext = Data("hello world ".utf8) + Data(repeating: 0, count: 7)
        let ad = Data([0xAA, 0xBB])
        let ciphertext = try WireGuardCrypto.aeadEncrypt(key: key, counter: 7, plaintext: plaintext, ad: ad)
        XCTAssertEqual(ciphertext.count, plaintext.count + WireGuardCrypto.aeadTagLen)
        let recovered = try WireGuardCrypto.aeadDecrypt(key: key, counter: 7, ciphertext: ciphertext, ad: ad)
        XCTAssertEqual(recovered, plaintext)
    }

    func testAeadWrongCounterFailsAuth() throws {
        let key = Data(repeating: 9, count: 32)
        let ciphertext = try WireGuardCrypto.aeadEncrypt(key: key, counter: 1, plaintext: Data([1, 2, 3, 4]), ad: Data())
        XCTAssertThrowsError(try WireGuardCrypto.aeadDecrypt(key: key, counter: 2, ciphertext: ciphertext, ad: Data())) {
            XCTAssertTrue($0 is WireGuardCrypto.AeadAuthFailed)
        }
    }

    func testKdfOutputLengthsMatchN() {
        let chainingKey = Data((0 ..< 32).map { UInt8($0) })
        let input = Data("x25519 dh result".utf8)
        let one = WireGuardCrypto.kdf(key: chainingKey, input: input, n: 1)
        let two = WireGuardCrypto.kdf(key: chainingKey, input: input, n: 2)
        let three = WireGuardCrypto.kdf(key: chainingKey, input: input, n: 3)
        XCTAssertEqual(one.count, 1)
        XCTAssertEqual(two.count, 2)
        XCTAssertEqual(three.count, 3)
        XCTAssertEqual(one[0], two[0])
        XCTAssertEqual(two[1], three[1])
    }

    func testBuildInitiationMessageShapeMatchesSpec() throws {
        let (staticPriv, staticPub) = staticKeypair()
        let (_, responderPub) = staticKeypair()
        let (message, session) = try WireGuardHandshake.buildInitiation(
            staticPriv: staticPriv,
            staticPub: staticPub,
            responderStaticPub: responderPub,
            senderIndex: 0x0102_0304
        )
        XCTAssertEqual(message.count, WireGuardHandshake.initMessageLen)
        XCTAssertEqual(message[0], 1)
        XCTAssertEqual(message.readUInt32LE(at: 4), 0x0102_0304)
        XCTAssertEqual(session.senderIndex, 0x0102_0304)
        for index in (WireGuardHandshake.initMessageLen - 16) ..< WireGuardHandshake.initMessageLen {
            XCTAssertEqual(message[index], 0, "MAC2[\(index)] should be zero")
        }
    }

    func testFullHandshakeLocalResponderSucceedsAndTransportRoundTrips() throws {
        let (initiatorPriv, initiatorPub) = staticKeypair()
        let (responderPriv, responderPub) = staticKeypair()
        let responder = LoopbackResponder(
            responderStaticPriv: responderPriv,
            responderStaticPub: responderPub,
            expectedInitiatorStaticPub: initiatorPub
        )

        let (initPacket, session) = try WireGuardHandshake.buildInitiation(
            staticPriv: initiatorPriv,
            staticPub: initiatorPub,
            responderStaticPub: responderPub,
            senderIndex: 0xC0DE_F00D
        )
        let response = try responder.respondTo(initPacket)
        try WireGuardHandshake.consumeResponse(session, response: response)

        XCTAssertEqual(responder.transportRecvKey, session.sendKey)
        XCTAssertEqual(responder.transportSendKey, session.recvKey)
        XCTAssertEqual(session.receiverIndex, responder.senderIndex)

        let ipPacket = Data([0x45, 0, 0, 0x14, 0, 1, 0, 0, 0x40, 0x06, 0, 0, 10, 0, 0, 2, 1, 1, 1, 1])
        let transport = try WireGuardHandshake.encodeTransport(session, payload: ipPacket)
        let decrypted = try responder.decryptTransport(transport)
        XCTAssertEqual(decrypted, ipPacket)

        let replyPlain = Data((0 ..< 40).map { UInt8($0) })
        let responderTransport = try responder.encryptTransport(replyPlain)
        let frame = try WireGuardHandshake.decodeTransport(session, message: responderTransport)
        XCTAssertEqual(frame.payload, replyPlain)
    }

    func testDiodeWireGuardPreflightDescribeMapsResults() {
        XCTAssertEqual(DiodeWireGuardPreflight.describe(.ok), "WireGuard preflight OK")
        XCTAssertTrue(
            DiodeWireGuardPreflight.describe(.noResponse(endpoint: "1.2.3.4:51820", timeoutMs: 4000))
                .contains("did not respond")
        )
    }

    private func staticKeypair() -> (Data, Data) {
        let privateKey = WireGuardHandshake.generateEphemeralPrivate()
        let publicKey = try! WireGuardCrypto.x25519PublicFromPrivate(privateKey)
        return (privateKey, publicKey)
    }
}

private final class LoopbackResponder {
    private let responderStaticPriv: Data
    private let expectedInitiatorStaticPub: Data
    private(set) var senderIndex: UInt32 = 0xDEAD_BEEF
    private(set) var transportSendKey = Data()
    private(set) var transportRecvKey = Data()
    private var transportSendCounter: UInt64 = 0
    private var receiverIndex: UInt32 = 0

    init(responderStaticPriv: Data, responderStaticPub: Data, expectedInitiatorStaticPub: Data) {
        self.responderStaticPriv = responderStaticPriv
        _ = responderStaticPub
        self.expectedInitiatorStaticPub = expectedInitiatorStaticPub
    }

    func respondTo(_ initPacket: Data) throws -> Data {
        precondition(initPacket.count == WireGuardHandshake.initMessageLen)
        precondition(initPacket[0] == 1)

        let initiatorIndex = initPacket.readUInt32LE(at: 4)
        let initiatorEphemeral = initPacket.subdata(in: 8 ..< 40)
        let encryptedStatic = initPacket.subdata(in: 40 ..< 88)
        let encryptedTimestamp = initPacket.subdata(in: 88 ..< 116)

        var ci = WireGuardCrypto.hash([Data("Noise_IKpsk2_25519_ChaChaPoly_BLAKE2s".utf8)])
        let identifier = Data(("WireGuard v1 zx2c4 Jason" + "@" + "zx2c4.com").utf8)
        var hi = WireGuardCrypto.hash([ci, identifier])
        hi = WireGuardCrypto.hash([hi, try WireGuardCrypto.x25519PublicFromPrivate(responderStaticPriv)])

        ci = WireGuardCrypto.kdf(key: ci, input: initiatorEphemeral, n: 1)[0]
        hi = WireGuardCrypto.hash([hi, initiatorEphemeral])

        let kdf1 = WireGuardCrypto.kdf(
            key: ci,
            input: try WireGuardCrypto.x25519(privateKey: responderStaticPriv, publicKey: initiatorEphemeral),
            n: 2
        )
        ci = kdf1[0]
        let initiatorStaticPub = try WireGuardCrypto.aeadDecrypt(key: kdf1[1], counter: 0, ciphertext: encryptedStatic, ad: hi)
        guard initiatorStaticPub == expectedInitiatorStaticPub else {
            throw WireGuardHandshake.HandshakeException.aeadFailed("Initiator static key mismatch in loopback responder")
        }
        hi = WireGuardCrypto.hash([hi, encryptedStatic])

        let kdf2 = WireGuardCrypto.kdf(
            key: ci,
            input: try WireGuardCrypto.x25519(privateKey: responderStaticPriv, publicKey: initiatorStaticPub),
            n: 2
        )
        ci = kdf2[0]
        let timestamp = try WireGuardCrypto.aeadDecrypt(key: kdf2[1], counter: 0, ciphertext: encryptedTimestamp, ad: hi)
        guard timestamp.count == WireGuardCrypto.tai64nLen else {
            throw WireGuardHandshake.HandshakeException.aeadFailed("Invalid TAI64N length in loopback responder")
        }
        hi = WireGuardCrypto.hash([hi, encryptedTimestamp])

        let ephemeralPriv = WireGuardHandshake.generateEphemeralPrivate()
        let ephemeralPub = try WireGuardCrypto.x25519PublicFromPrivate(ephemeralPriv)
        ci = WireGuardCrypto.kdf(key: ci, input: ephemeralPub, n: 1)[0]
        hi = WireGuardCrypto.hash([hi, ephemeralPub])
        ci = WireGuardCrypto.kdf(
            key: ci,
            input: try WireGuardCrypto.x25519(privateKey: ephemeralPriv, publicKey: initiatorEphemeral),
            n: 1
        )[0]
        ci = WireGuardCrypto.kdf(
            key: ci,
            input: try WireGuardCrypto.x25519(privateKey: ephemeralPriv, publicKey: initiatorStaticPub),
            n: 1
        )[0]

        let kdf3 = WireGuardCrypto.kdf(key: ci, input: Data(repeating: 0, count: 32), n: 3)
        ci = kdf3[0]
        hi = WireGuardCrypto.hash([hi, kdf3[1]])
        let encryptedNothing = try WireGuardCrypto.aeadEncrypt(key: kdf3[2], counter: 0, plaintext: Data(), ad: hi)

        var packet = Data(count: WireGuardHandshake.respMessageLen)
        packet[0] = 2
        packet.replaceSubrange(4 ..< 8, with: senderIndex.littleEndianBytes)
        packet.replaceSubrange(8 ..< 12, with: initiatorIndex.littleEndianBytes)
        packet.replaceSubrange(12 ..< 44, with: ephemeralPub)
        packet.replaceSubrange(44 ..< 60, with: encryptedNothing)

        let mac1Key = WireGuardCrypto.hash([Data("mac1----".utf8), expectedInitiatorStaticPub])
        let mac1 = WireGuardCrypto.keyedHash(key: mac1Key, data: packet.prefix(60), outLen: WireGuardCrypto.macLen)
        packet.replaceSubrange(60 ..< 76, with: mac1)

        let transportKeys = WireGuardCrypto.kdf(key: ci, input: Data(), n: 2)
        transportRecvKey = transportKeys[0]
        transportSendKey = transportKeys[1]
        receiverIndex = initiatorIndex
        return packet
    }

    func decryptTransport(_ transport: Data) throws -> Data {
        precondition(transport[0] == 4)
        let counter = transport.readUInt64LE(at: 8)
        let ciphertext = transport.subdata(in: WireGuardHandshake.transportHeaderLen ..< transport.count)
        return try WireGuardCrypto.aeadDecrypt(key: transportRecvKey, counter: counter, ciphertext: ciphertext, ad: Data())
    }

    func encryptTransport(_ payload: Data) throws -> Data {
        let counter = transportSendCounter
        transportSendCounter += 1
        let ciphertext = try WireGuardCrypto.aeadEncrypt(key: transportSendKey, counter: counter, plaintext: payload, ad: Data())
        var packet = Data(count: WireGuardHandshake.transportHeaderLen + ciphertext.count)
        packet[0] = 4
        packet.replaceSubrange(4 ..< 8, with: receiverIndex.littleEndianBytes)
        packet.replaceSubrange(8 ..< 16, with: counter.littleEndianBytes)
        packet.replaceSubrange(16 ..< packet.count, with: ciphertext)
        return packet
    }
}

private extension Data {
    func readUInt32LE(at offset: Int) -> UInt32 {
        withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self).littleEndian }
    }

    func readUInt64LE(at offset: Int) -> UInt64 {
        withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt64.self).littleEndian }
    }
}

private extension UInt32 {
    var littleEndianBytes: Data {
        withUnsafeBytes(of: littleEndian) { Data($0) }
    }
}

private extension UInt64 {
    var littleEndianBytes: Data {
        withUnsafeBytes(of: littleEndian) { Data($0) }
    }
}
