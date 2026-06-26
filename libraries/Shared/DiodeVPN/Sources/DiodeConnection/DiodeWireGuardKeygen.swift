import CryptoKit
import Foundation

public struct DiodeWireGuardKeyPair: Sendable {
    public let privateKeyBase64: String
    public let publicKeyHex: String

    public static func generate() -> DiodeWireGuardKeyPair {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKey = privateKey.publicKey
        let privateBase64 = privateKey.rawRepresentation.base64EncodedString()
        let publicHex = publicKey.rawRepresentation.map { String(format: "%02x", $0) }.joined()
        return DiodeWireGuardKeyPair(privateKeyBase64: privateBase64, publicKeyHex: publicHex)
    }
}
