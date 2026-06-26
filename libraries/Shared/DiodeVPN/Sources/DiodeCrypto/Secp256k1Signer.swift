import Foundation
import P256K

/// secp256k1 signing and Ethereum address recovery for TicketV2.
public enum Secp256k1Signer {
    /// Sign a 32-byte digest; returns 65-byte compact signature (recId, r, s).
    public static func signDigest(_ digest32: Data, privateKey32: Data) throws -> Data {
        guard digest32.count == 32 else {
            throw Secp256k1SignerError.invalidDigestLength
        }
        guard privateKey32.count == 32 else {
            throw Secp256k1SignerError.invalidPrivateKeyLength
        }

        let privateKey = try P256K.Recovery.PrivateKey(dataRepresentation: privateKey32)
        let digest = HashDigest(Array(digest32))
        let signature = privateKey.signature(for: digest)
        let compact = signature.compactRepresentation

        guard compact.recoveryId == 0 || compact.recoveryId == 1 else {
            throw Secp256k1SignerError.unexpectedRecoveryID(Int(compact.recoveryId))
        }

        var result = Data([UInt8(compact.recoveryId)])
        result.append(compact.signature)
        return result
    }

    /// Ethereum-style address (`0x` + 40 lowercase hex) from a 32-byte private key.
    public static func address0x(fromPrivateKey32 privateKey32: Data) throws -> String {
        let privateKey = try P256K.Recovery.PrivateKey(dataRepresentation: privateKey32, format: .uncompressed)
        let uncompressed = privateKey.publicKey.dataRepresentation
        return DiodeHex.ensureHex0xPrefix(ethereumAddressHex(fromUncompressedPublicKey: uncompressed))
    }

    /// Recover Ethereum address from digest + 65-byte signature (recId, r, s).
    public static func recoverAddress0x(digest32: Data, signature65: Data) throws -> String {
        guard digest32.count == 32 else {
            throw Secp256k1SignerError.invalidDigestLength
        }
        guard signature65.count == 65 else {
            throw Secp256k1SignerError.invalidSignatureLength
        }

        let recId = Int32(signature65[0])
        let compact = signature65.suffix(64)
        let digest = HashDigest(Array(digest32))
        let signature = try P256K.Recovery.ECDSASignature(
            compactRepresentation: compact,
            recoveryId: recId
        )
        let publicKey = P256K.Recovery.PublicKey(digest, signature: signature, format: .uncompressed)
        return DiodeHex.ensureHex0xPrefix(ethereumAddressHex(fromUncompressedPublicKey: publicKey.dataRepresentation))
    }

    private static func ethereumAddressHex(fromUncompressedPublicKey publicKey: Data) -> String {
        let keyBytes = publicKey.count == 65 ? publicKey.dropFirst() : publicKey
        let hash = Keccak256.hash(Data(keyBytes))
        return DiodeHex.encode(Data(hash.suffix(20)))
    }
}

public enum Secp256k1SignerError: Error {
    case invalidDigestLength
    case invalidPrivateKeyLength
    case invalidSignatureLength
    case unexpectedRecoveryID(Int)
}
