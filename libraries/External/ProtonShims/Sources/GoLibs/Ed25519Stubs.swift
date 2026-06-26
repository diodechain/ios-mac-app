import CryptoKit
import Foundation

public final class Ed25519KeyPair: NSObject {
    private let privateKey: Curve25519.Signing.PrivateKey

    public override init() {
        privateKey = Curve25519.Signing.PrivateKey()
        super.init()
    }

    public func publicKeyBytes() -> Data? {
        Data(privateKey.publicKey.rawRepresentation)
    }

    public func privateKeyBytes() -> Data? {
        Data(privateKey.rawRepresentation)
    }

    public func publicKeyPKIXPem(_ error: NSErrorPointer) -> String {
        guard let bytes = publicKeyBytes() else {
            error?.pointee = NSError(domain: "GoLibs", code: 1)
            return ""
        }
        return Self.pem(label: "PUBLIC KEY", der: bytes)
    }

    public func privateKeyPKIXPem() -> String {
        guard let bytes = privateKeyBytes() else { return "" }
        return Self.pem(label: "PRIVATE KEY", der: bytes)
    }

    public func toX25519Base64() -> String {
        privateKeyBytes()?.base64EncodedString() ?? ""
    }

    private static func pem(label: String, der: Data) -> String {
        let body = der.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
        return "-----BEGIN \(label)-----\n\(body)\n-----END \(label)-----\n"
    }
}

public func Ed25519NewKeyPair(_ error: NSErrorPointer) -> Ed25519KeyPair? {
    let keyPair = Ed25519KeyPair()
    error?.pointee = nil
    return keyPair
}
