import CommonCrypto
import Foundation
import DiodeCrypto

/**
 * Diode TicketV2 for WebSocket `dio_ticket`, matching
 * DiodeClient.TicketV2 device_blob + sign and
 * Network.Rpc rlp_list_to_ticket RLP layout.
 *
 * **server_id in device_blob** must equal the Ethereum address of the **node that terminates the WebSocket**
 * (the RPC process that runs `dio_ticket`). The node replaces `server_id` in the parsed struct with its own
 * wallet, but verification uses the signature over device_blob which includes the expected server id.
 *
 * Device blob fields (each ABI-encoded as `bytes32`, then concatenated), per `TicketV2.device_blob/1`:
 * chain_id, epoch, fleet_contract, server_id, total_connections, total_bytes, sha256(local_address UTF-8).
 *
 * Signing matches `Secp256k1.sign(private, device_blob, :kec)` → Keccak-256(device_blob), then ECDSA;
 * wire format is 65 bytes: recovery id (0 or 1) + r (32) + s (32), as produced by libsecp256k1 compact.
 */
public enum TicketV2 {
    public struct Params: Equatable, Sendable {
        public let chainID: UInt64
        public let epoch: UInt64
        public let fleetContract20: Data
        public let serverID20: Data
        public let totalConnections: UInt64
        public let totalBytes: UInt64
        public let localAddress: String

        public init(
            chainID: UInt64,
            epoch: UInt64,
            fleetContract20: Data,
            serverID20: Data,
            totalConnections: UInt64,
            totalBytes: UInt64,
            localAddress: String
        ) {
            self.chainID = chainID
            self.epoch = epoch
            self.fleetContract20 = fleetContract20
            self.serverID20 = serverID20
            self.totalConnections = totalConnections
            self.totalBytes = totalBytes
            self.localAddress = localAddress
        }
    }

    public static func buildDeviceBlob(_ params: Params) throws -> Data {
        guard params.fleetContract20.count == 20 else {
            throw TicketV2Error.invalidFleetContractLength
        }
        guard params.serverID20.count == 20 else {
            throw TicketV2Error.invalidServerIDLength
        }

        let localHash = Data(SHA256.hash(data: Data(params.localAddress.utf8)))
        var blob = Data()
        blob.append(bytes32Uint(params.chainID))
        blob.append(bytes32Uint(params.epoch))
        blob.append(bytes32Address(params.fleetContract20))
        blob.append(bytes32Address(params.serverID20))
        blob.append(bytes32Uint(params.totalConnections))
        blob.append(bytes32Uint(params.totalBytes))
        blob.append(bytes32Raw(localHash))
        return blob
    }

    /// Sign device blob: Keccak256(blob) then ECDSA (same as Elixir `:kec` path).
    /// Returns 65-byte compact signature (recId, r, s).
    public static func signDeviceBlob(_ deviceBlob: Data, privateKey32: Data) throws -> Data {
        let digest = Keccak256.hash(deviceBlob)
        return try Secp256k1Signer.signDigest(digest, privateKey32: privateKey32)
    }

    /**
     * RLP list for `dio_ticket` param (`0x` + hex for JSON-RPC), matching `Rlp.encode! |> Base16.encode` in rpc_client.ex:
     * ["ticketv2", uint(chain_id), uint(epoch), fleet, uint(tc), uint(tb), local_address, device_signature]
     */
    public static func encodeTicketRlp(_ params: Params, deviceSignature65: Data) -> Data {
        let parts: [Data] = [
            DiodeRlp.encodeStringUtf8("ticketv2"),
            DiodeRlp.encodeBytes(DiodeRlp.encodeUnsignedLong(params.chainID)),
            DiodeRlp.encodeBytes(DiodeRlp.encodeUnsignedLong(params.epoch)),
            DiodeRlp.encodeBytes(params.fleetContract20),
            DiodeRlp.encodeBytes(DiodeRlp.encodeUnsignedLong(params.totalConnections)),
            DiodeRlp.encodeBytes(DiodeRlp.encodeUnsignedLong(params.totalBytes)),
            DiodeRlp.encodeBytes(Data(params.localAddress.utf8)),
            DiodeRlp.encodeBytes(deviceSignature65),
        ]
        return DiodeRlp.encodeListOfEncodedItems(parts)
    }

    /// Hex string for JSON-RPC `dio_ticket` param. **Includes `0x` prefix**.
    public static func ticketHexForRpc(_ params: Params, privateKey32: Data) throws -> String {
        let blob = try buildDeviceBlob(params)
        let signature = try signDeviceBlob(blob, privateKey32: privateKey32)
        let rlp = encodeTicketRlp(params, deviceSignature65: signature)
        return DiodeHex.encode(rlp, with0x: true)
    }

    private static func bytes32Uint(_ value: UInt64) -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        var v = value
        var index = 31
        while v > 0 {
            bytes[index] = UInt8(v & 0xFF)
            v >>= 8
            if index == 0 { break }
            index -= 1
        }
        return Data(bytes)
    }

    private static func bytes32Address(_ address20: Data) -> Data {
        var padded = Data(repeating: 0, count: 32)
        padded.replaceSubrange(12..<32, with: address20)
        return padded
    }

    private static func bytes32Raw(_ hash32: Data) -> Data {
        precondition(hash32.count == 32)
        return hash32
    }
}

public enum TicketV2Error: Error {
    case invalidFleetContractLength
    case invalidServerIDLength
}

private enum SHA256 {
    static func hash(data: Data) -> [UInt8] {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        return hash
    }
}