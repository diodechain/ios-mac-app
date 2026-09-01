import CryptoKit
import Foundation

/// Low-level WireGuard primitives (BLAKE2s, HKDF, ChaCha20-Poly1305, X25519, TAI64N).
enum WireGuardCrypto {
    static let hashLen = 32
    static let macLen = 16
    static let keyLen = 32
    static let x25519Len = 32
    static let aeadTagLen = 16
    static let tai64nLen = 12

    enum AeadAuthFailed: Error {
        case tagMismatch(counter: UInt64, ciphertextLen: Int)
    }

    static func hash(_ parts: [Data]) -> Data {
        Blake2s.hash(parts: parts, digestLength: hashLen)
    }

    static func keyedHash(key: Data, data: Data, outLen: Int) -> Data {
        Blake2s.keyedHash(key: key, data: data, digestLength: outLen)
    }

    private static func hmacBlake2s(key: Data, data: Data) -> Data {
        var blockKey = key
        if blockKey.count > hashLen {
            blockKey = hash([blockKey])
        }
        if blockKey.count < hashLen {
            blockKey.append(Data(repeating: 0, count: hashLen - blockKey.count))
        }

        let ipad = Data(blockKey.map { $0 ^ 0x36 })
        let opad = Data(blockKey.map { $0 ^ 0x5c })
        let inner = hash([ipad, data])
        return hash([opad, inner])
    }

    static func kdf(key: Data, input: Data, n: Int) -> [Data] {
        precondition((1 ... 3).contains(n))
        let prk = hmacBlake2s(key: key, data: input)
        var outputs: [Data] = []
        var previous = Data()
        for index in 0 ..< n {
            var message = previous
            message.append(UInt8(index + 1))
            let output = hmacBlake2s(key: prk, data: message)
            outputs.append(output)
            previous = output
        }
        return outputs
    }

    static func aeadEncrypt(key: Data, counter: UInt64, plaintext: Data, ad: Data) throws -> Data {
        let nonce = try nonceFromCounter(counter)
        let sealed = try ChaChaPoly.seal(plaintext, using: SymmetricKey(data: key), nonce: nonce, authenticating: ad)
        return sealed.ciphertext + sealed.tag
    }

    static func aeadDecrypt(key: Data, counter: UInt64, ciphertext: Data, ad: Data) throws -> Data {
        guard ciphertext.count >= aeadTagLen else {
            throw AeadAuthFailed.tagMismatch(counter: counter, ciphertextLen: ciphertext.count)
        }
        let ct = ciphertext.prefix(ciphertext.count - aeadTagLen)
        let tag = ciphertext.suffix(aeadTagLen)
        let nonce = try nonceFromCounter(counter)
        do {
            return try ChaChaPoly.open(
                ChaChaPoly.SealedBox(nonce: nonce, ciphertext: ct, tag: tag),
                using: SymmetricKey(data: key),
                authenticating: ad
            )
        } catch {
            throw AeadAuthFailed.tagMismatch(counter: counter, ciphertextLen: ciphertext.count - aeadTagLen)
        }
    }

    static func x25519(privateKey: Data, publicKey: Data) throws -> Data {
        guard privateKey.count == x25519Len, publicKey.count == x25519Len else {
            throw WireGuardHandshakeError.invalidKeyLength
        }
        let privateKeyObject = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKey)
        let publicKeyObject = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: publicKey)
        let secret = try privateKeyObject.sharedSecretFromKeyAgreement(with: publicKeyObject)
        let shared = secret.withUnsafeBytes { Data($0) }
        guard shared.contains(where: { $0 != 0 }) else {
            throw WireGuardHandshakeError.lowOrderPoint
        }
        return shared
    }

    static func x25519PublicFromPrivate(_ privateKey: Data) throws -> Data {
        guard privateKey.count == x25519Len else {
            throw WireGuardHandshakeError.invalidKeyLength
        }
        return try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKey).publicKey.rawRepresentation
    }

    static func tai64n(nowMillis: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) -> Data {
        let seconds = UInt64(nowMillis / 1000) + 0x4000_0000_0000_0000 + 10
        let nanos = UInt32((nowMillis % 1000) * 1_000_000)
        var bytes = Data(count: tai64nLen)
        bytes.withUnsafeMutableBytes { buffer in
            buffer.storeBytes(of: seconds.bigEndian, toByteOffset: 0, as: UInt64.self)
            buffer.storeBytes(of: nanos.bigEndian, toByteOffset: 8, as: UInt32.self)
        }
        return bytes
    }

    private static func nonceFromCounter(_ counter: UInt64) throws -> ChaChaPoly.Nonce {
        var bytes = Data(repeating: 0, count: 12)
        bytes.withUnsafeMutableBytes { buffer in
            buffer.storeBytes(of: counter.littleEndian, toByteOffset: 4, as: UInt64.self)
        }
        return try ChaChaPoly.Nonce(data: bytes)
    }
}

enum WireGuardHandshakeError: Error {
    case invalidKeyLength
    case lowOrderPoint
}

/// Minimal BLAKE2s implementation for WireGuard Noise (RFC 7693).
private enum Blake2s {
    private static let blockSize = 64

    static func hash(parts: [Data], digestLength: Int) -> Data {
        var state = Blake2sState(digestLength: digestLength)
        for part in parts {
            state.update(part)
        }
        return state.finalize()
    }

    static func keyedHash(key: Data, data: Data, digestLength: Int) -> Data {
        var state = Blake2sState(keyed: digestLength, key: key)
        state.update(data)
        return state.finalize()
    }

    private struct Blake2sState {
        private var h: [UInt32]
        private var t: [UInt32] = [0, 0]
        private var buffer = Data()
        private let digestLength: Int

        init(digestLength: Int, keyLength: Int = 0) {
            precondition((1 ... 32).contains(digestLength))
            self.digestLength = digestLength
            h = iv
            h[0] ^= UInt32(truncatingIfNeeded: digestLength)
            h[0] ^= UInt32(truncatingIfNeeded: keyLength) << 8
            h[2] ^= 0x0101_0000
        }

        init(keyed digestLength: Int, key: Data) {
            var normalizedKey = key
            if normalizedKey.count > 32 {
                normalizedKey = Blake2s.hash(parts: [normalizedKey], digestLength: 32)
            }
            self.init(digestLength: digestLength, keyLength: normalizedKey.count)
            var block = Data(repeating: 0, count: blockSize)
            block.replaceSubrange(0 ..< normalizedKey.count, with: normalizedKey)
            compress(block: block, dataLen: blockSize, isFinalBlock: false)
        }

        mutating func update(_ data: Data) {
            buffer.append(data)
            while buffer.count >= blockSize {
                let block = buffer.prefix(blockSize)
                buffer.removeFirst(blockSize)
                compress(block: Data(block), dataLen: blockSize, isFinalBlock: false)
            }
        }

        mutating func finalize() -> Data {
            let remaining = buffer.count
            var last = buffer
            if last.count < blockSize {
                last.append(Data(repeating: 0, count: blockSize - last.count))
            }
            compress(block: last, dataLen: remaining, isFinalBlock: true)
            var out = Data()
            for word in h {
                out.append(contentsOf: withUnsafeBytes(of: word.littleEndian) { Array($0) })
            }
            return out.prefix(digestLength)
        }

        private mutating func compress(block: Data, dataLen: Int, isFinalBlock: Bool) {
            t[0] &+= UInt32(dataLen)
            if t[0] < UInt32(dataLen) { t[1] &+= 1 }
            if isFinalBlock { t[1] |= 0xffff_ffff }

            let m = stride(from: 0, to: blockSize, by: 4).map { offset -> UInt32 in
                block.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
            }

            var v = h + iv
            v[12] ^= t[0]
            v[13] ^= t[1]
            if isFinalBlock {
                v[14] ^= 0xffff_ffff
            }

            for round in 0 ..< 10 {
                let s = sigma[round]
                func g(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ x: Int, _ y: Int) {
                    v[a] = v[a] &+ v[b] &+ m[x]
                    v[d] = rotateRight(v[d] ^ v[a], by: 16)
                    v[c] = v[c] &+ v[d]
                    v[b] = rotateRight(v[b] ^ v[c], by: 12)
                    v[a] = v[a] &+ v[b] &+ m[y]
                    v[d] = rotateRight(v[d] ^ v[a], by: 8)
                    v[c] = v[c] &+ v[d]
                    v[b] = rotateRight(v[b] ^ v[c], by: 7)
                }
                g(0, 4, 8, 12, Int(s[0]), Int(s[1]))
                g(1, 5, 9, 13, Int(s[2]), Int(s[3]))
                g(2, 6, 10, 14, Int(s[4]), Int(s[5]))
                g(3, 7, 11, 15, Int(s[6]), Int(s[7]))
                g(0, 5, 10, 15, Int(s[8]), Int(s[9]))
                g(1, 6, 11, 12, Int(s[10]), Int(s[11]))
                g(2, 7, 8, 13, Int(s[12]), Int(s[13]))
                g(3, 4, 9, 14, Int(s[14]), Int(s[15]))
            }

            for index in 0 ..< 8 {
                h[index] ^= v[index] ^ v[index + 8]
            }
        }

        private func rotateRight(_ value: UInt32, by amount: Int) -> UInt32 {
            (value >> UInt32(amount)) | (value << UInt32(32 - amount))
        }
    }

    private static let iv: [UInt32] = [
        0x6a09_e667, 0xbb67_ae85, 0x3c6e_f372, 0xa54f_f53a,
        0x510e_527f, 0x9b05_688c, 0x1f83_d9ab, 0x5be0_cd19,
    ]

    private static let sigma: [[UInt8]] = [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
        [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3],
        [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4],
        [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8],
        [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13],
        [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9],
        [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11],
        [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10],
        [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5],
        [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0],
    ]
}
