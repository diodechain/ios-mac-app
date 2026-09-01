import CryptoKit
import Darwin
import Foundation

/// Pure-Swift WireGuard initiator handshake (Noise IKpsk2).
enum WireGuardHandshake {
    static let initMessageLen = 148
    static let respMessageLen = 92
    static let transportHeaderLen = 16
    static let minTransportLen = transportHeaderLen + WireGuardCrypto.aeadTagLen

    private static let msgTypeInit: UInt8 = 1
    private static let msgTypeResp: UInt8 = 2
    private static let msgTypeTransport: UInt8 = 4

    private static let construction = Data("Noise_IKpsk2_25519_ChaChaPoly_BLAKE2s".utf8)
    private static let labelMac1 = Data("mac1----".utf8)
    private static let identifier = Data(("WireGuard v1 zx2c4 Jason" + "@" + "zx2c4.com").utf8)

    private static let initialChainingKey = WireGuardCrypto.hash([construction])
    private static let initialHash = WireGuardCrypto.hash([initialChainingKey, identifier])

    final class Session {
        var chainingKey: Data
        var hashState: Data
        let ephemeralPriv: Data
        let ephemeralPub: Data
        let staticPriv: Data
        let staticPub: Data
        let responderStaticPub: Data
        let senderIndex: UInt32
        var receiverIndex: UInt32 = 0
        var responderEphemeralPub = Data()
        var sendKey = Data()
        var recvKey = Data()
        var sendCounter: UInt64 = 0

        init(
            chainingKey: Data,
            hashState: Data,
            ephemeralPriv: Data,
            ephemeralPub: Data,
            staticPriv: Data,
            staticPub: Data,
            responderStaticPub: Data,
            senderIndex: UInt32
        ) {
            self.chainingKey = chainingKey
            self.hashState = hashState
            self.ephemeralPriv = ephemeralPriv
            self.ephemeralPub = ephemeralPub
            self.staticPriv = staticPriv
            self.staticPub = staticPub
            self.responderStaticPub = responderStaticPub
            self.senderIndex = senderIndex
        }
    }

    enum HandshakeException: Error, Equatable {
        case wrongLength(String)
        case wrongType(String)
        case wrongIndex(String)
        case badMac1(String)
        case aeadFailed(String)
    }

    struct TransportFrame: Equatable {
        let counter: UInt64
        let payload: Data
    }

    static func buildInitiation(
        staticPriv: Data,
        staticPub: Data,
        responderStaticPub: Data,
        senderIndex: UInt32 = randomIndex(),
        ephemeralPriv: Data = generateEphemeralPrivate(),
        nowMillis: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) throws -> (Data, Session) {
        guard staticPriv.count == WireGuardCrypto.x25519Len,
              staticPub.count == WireGuardCrypto.x25519Len,
              responderStaticPub.count == WireGuardCrypto.x25519Len
        else {
            throw WireGuardHandshakeError.invalidKeyLength
        }

        let ephemeralPub = try WireGuardCrypto.x25519PublicFromPrivate(ephemeralPriv)

        var ci = initialChainingKey
        var hi = WireGuardCrypto.hash([initialHash, responderStaticPub])

        ci = WireGuardCrypto.kdf(key: ci, input: ephemeralPub, n: 1)[0]
        hi = WireGuardCrypto.hash([hi, ephemeralPub])

        let kdf1 = WireGuardCrypto.kdf(key: ci, input: try WireGuardCrypto.x25519(privateKey: ephemeralPriv, publicKey: responderStaticPub), n: 2)
        ci = kdf1[0]
        let encryptedStatic = try WireGuardCrypto.aeadEncrypt(key: kdf1[1], counter: 0, plaintext: staticPub, ad: hi)
        hi = WireGuardCrypto.hash([hi, encryptedStatic])

        let kdf2 = WireGuardCrypto.kdf(key: ci, input: try WireGuardCrypto.x25519(privateKey: staticPriv, publicKey: responderStaticPub), n: 2)
        ci = kdf2[0]
        let encryptedTimestamp = try WireGuardCrypto.aeadEncrypt(
            key: kdf2[1],
            counter: 0,
            plaintext: WireGuardCrypto.tai64n(nowMillis: nowMillis),
            ad: hi
        )
        hi = WireGuardCrypto.hash([hi, encryptedTimestamp])

        var packet = Data(count: initMessageLen)
        packet[0] = msgTypeInit
        packet.replaceSubrange(4 ..< 8, with: senderIndex.littleEndianBytes)
        packet.replaceSubrange(8 ..< 40, with: ephemeralPub)
        packet.replaceSubrange(40 ..< 88, with: encryptedStatic)
        packet.replaceSubrange(88 ..< 116, with: encryptedTimestamp)

        let mac1Key = WireGuardCrypto.hash([labelMac1, responderStaticPub])
        let mac1 = WireGuardCrypto.keyedHash(key: mac1Key, data: packet.prefix(116), outLen: WireGuardCrypto.macLen)
        packet.replaceSubrange(116 ..< 132, with: mac1)

        let session = Session(
            chainingKey: ci,
            hashState: hi,
            ephemeralPriv: ephemeralPriv,
            ephemeralPub: ephemeralPub,
            staticPriv: staticPriv,
            staticPub: staticPub,
            responderStaticPub: responderStaticPub,
            senderIndex: senderIndex
        )
        return (packet, session)
    }

    static func consumeResponse(_ session: Session, response: Data) throws {
        guard response.count == respMessageLen else {
            throw HandshakeException.wrongLength("Expected \(respMessageLen)-byte handshake response, got \(response.count)")
        }
        guard response[0] == msgTypeResp else {
            throw HandshakeException.wrongType("Expected msg.type=2 (response), got \(response[0])")
        }

        let responderIndex = response.readUInt32LE(at: 4)
        let receiverIndex = response.readUInt32LE(at: 8)
        guard receiverIndex == session.senderIndex else {
            throw HandshakeException.wrongIndex(
                "Response receiver_index=\(receiverIndex) does not match our sender_index=\(session.senderIndex)"
            )
        }

        let responderEphemeral = response.subdata(in: 12 ..< 44)
        let encryptedNothing = response.subdata(in: 44 ..< 60)
        let mac1 = response.subdata(in: 60 ..< 76)

        let expectedMac1Key = WireGuardCrypto.hash([labelMac1, session.staticPub])
        let expectedMac1 = WireGuardCrypto.keyedHash(key: expectedMac1Key, data: response.prefix(60), outLen: WireGuardCrypto.macLen)
        guard constantTimeEquals(expectedMac1, mac1) else {
            throw HandshakeException.badMac1(
                "MAC1 verification failed — response not bound to our static public key."
            )
        }

        var ci = session.chainingKey
        var hi = session.hashState
        ci = WireGuardCrypto.kdf(key: ci, input: responderEphemeral, n: 1)[0]
        hi = WireGuardCrypto.hash([hi, responderEphemeral])
        ci = WireGuardCrypto.kdf(key: ci, input: try WireGuardCrypto.x25519(privateKey: session.ephemeralPriv, publicKey: responderEphemeral), n: 1)[0]
        ci = WireGuardCrypto.kdf(key: ci, input: try WireGuardCrypto.x25519(privateKey: session.staticPriv, publicKey: responderEphemeral), n: 1)[0]

        let psk = Data(repeating: 0, count: WireGuardCrypto.keyLen)
        let kdf3 = WireGuardCrypto.kdf(key: ci, input: psk, n: 3)
        ci = kdf3[0]
        hi = WireGuardCrypto.hash([hi, kdf3[1]])

        do {
            let payload = try WireGuardCrypto.aeadDecrypt(key: kdf3[2], counter: 0, ciphertext: encryptedNothing, ad: hi)
            if !payload.isEmpty {
                throw HandshakeException.aeadFailed("Decrypted handshake payload is non-empty (\(payload.count) bytes)")
            }
        } catch let error as WireGuardCrypto.AeadAuthFailed {
            throw HandshakeException.aeadFailed(
                "Failed to decrypt handshake response: \(error). The server may be using a stale static key."
            )
        }

        let transportKeys = WireGuardCrypto.kdf(key: ci, input: Data(), n: 2)
        session.chainingKey = ci
        session.hashState = hi
        session.responderEphemeralPub = responderEphemeral
        session.receiverIndex = responderIndex
        session.sendKey = transportKeys[0]
        session.recvKey = transportKeys[1]
    }

    static func encodeTransport(_ session: Session, payload: Data) throws -> Data {
        guard !session.sendKey.isEmpty else {
            throw HandshakeException.aeadFailed("encodeTransport called before consumeResponse()")
        }
        let counter = session.sendCounter
        session.sendCounter = counter + 1
        let ciphertext = try WireGuardCrypto.aeadEncrypt(key: session.sendKey, counter: counter, plaintext: payload, ad: Data())
        var packet = Data(count: transportHeaderLen + ciphertext.count)
        packet[0] = msgTypeTransport
        packet.replaceSubrange(4 ..< 8, with: session.receiverIndex.littleEndianBytes)
        packet.replaceSubrange(8 ..< 16, with: counter.littleEndianBytes)
        packet.replaceSubrange(16 ..< packet.count, with: ciphertext)
        return packet
    }

    static func decodeTransport(_ session: Session, message: Data) throws -> TransportFrame {
        guard !session.recvKey.isEmpty else {
            throw HandshakeException.aeadFailed("decodeTransport called before consumeResponse()")
        }
        guard message.count >= minTransportLen else {
            throw HandshakeException.wrongLength("Transport message too short: \(message.count) < \(minTransportLen)")
        }
        guard message[0] == msgTypeTransport else {
            throw HandshakeException.wrongType("Expected msg.type=4 (transport), got \(message[0])")
        }
        let receiverIndex = message.readUInt32LE(at: 4)
        guard receiverIndex == session.senderIndex else {
            throw HandshakeException.wrongIndex(
                "Transport receiver_index=\(receiverIndex) does not match our sender_index=\(session.senderIndex)"
            )
        }
        let counter = message.readUInt64LE(at: 8)
        let ciphertext = message.subdata(in: transportHeaderLen ..< message.count)
        do {
            let payload = try WireGuardCrypto.aeadDecrypt(key: session.recvKey, counter: counter, ciphertext: ciphertext, ad: Data())
            return TransportFrame(counter: counter, payload: payload)
        } catch let error as WireGuardCrypto.AeadAuthFailed {
            throw HandshakeException.aeadFailed("Failed to decrypt transport message (counter=\(counter)): \(error)")
        }
    }

    static func sendAndAwait(host: String, port: Int, packet: Data, timeoutMs: Int = 3_000) throws -> Data {
        var hints = addrinfo(
            ai_flags: AI_ADDRCONFIG,
            ai_family: AF_UNSPEC,
            ai_socktype: SOCK_DGRAM,
            ai_protocol: IPPROTO_UDP,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil
        )
        var infoPointer: UnsafeMutablePointer<addrinfo>?
        let resolveStatus = getaddrinfo(host, String(port), &hints, &infoPointer)
        guard resolveStatus == 0, let infoPointer else {
            throw PreflightUDPError.resolveFailed(host: host, port: port)
        }
        defer { freeaddrinfo(infoPointer) }

        let socketFD = Darwin.socket(infoPointer.pointee.ai_family, infoPointer.pointee.ai_socktype, infoPointer.pointee.ai_protocol)
        guard socketFD >= 0 else {
            throw PreflightUDPError.socketFailed
        }
        defer { close(socketFD) }

        var timeout = timeval(
            tv_sec: timeoutMs / 1000,
            tv_usec: Int32((timeoutMs % 1000) * 1000)
        )
        setsockopt(socketFD, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

        let sendStatus = packet.withUnsafeBytes { buffer in
            sendto(
                socketFD,
                buffer.baseAddress,
                buffer.count,
                0,
                infoPointer.pointee.ai_addr,
                infoPointer.pointee.ai_addrlen
            )
        }
        guard sendStatus == packet.count else {
            throw PreflightUDPError.sendFailed
        }

        var receiveBuffer = [UInt8](repeating: 0, count: 2048)
        var address = sockaddr_storage()
        var addressLength = socklen_t(MemoryLayout<sockaddr_storage>.size)
        let received = recvfrom(
            socketFD,
            &receiveBuffer,
            receiveBuffer.count,
            0,
            withUnsafeMutablePointer(to: &address) { pointer in
                UnsafeMutableRawPointer(pointer).assumingMemoryBound(to: sockaddr.self)
            },
            &addressLength
        )
        guard received > 0 else {
            if errno == EAGAIN || errno == EWOULDBLOCK {
                throw PreflightUDPError.timeout(host: host, port: port, timeoutMs: timeoutMs)
            }
            throw PreflightUDPError.receiveFailed
        }
        return Data(receiveBuffer.prefix(received))
    }

    static func generateEphemeralPrivate() -> Data {
        Curve25519.KeyAgreement.PrivateKey().rawRepresentation
    }

    static func randomIndex() -> UInt32 {
        var bytes = Data(count: 4)
        _ = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 4, $0.baseAddress!) }
        return bytes.readUInt32LE(at: 0)
    }

    private static func constantTimeEquals(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var diff: UInt8 = 0
        for index in lhs.indices {
            diff |= lhs[index] ^ rhs[index]
        }
        return diff == 0
    }
}

enum PreflightUDPError: Error {
    case resolveFailed(host: String, port: Int)
    case socketFailed
    case sendFailed
    case receiveFailed
    case timeout(host: String, port: Int, timeoutMs: Int)
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
