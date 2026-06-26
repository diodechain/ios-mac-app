import Foundation
import P256K
import Security

/// Persists secp256k1 device key (TicketV2 signing) and stable `local_address` string in Keychain.
public final class DeviceKeyStore: @unchecked Sendable {
    private let service: String
    private let localAddressPrefix: String

    public init(
        service: String = "diode_vpn_device_keys",
        localAddressPrefix: String? = nil
    ) {
        self.service = service
        #if os(macOS)
        self.localAddressPrefix = localAddressPrefix ?? "macos:"
        #else
        self.localAddressPrefix = localAddressPrefix ?? "ios:"
        #endif
    }

    /// 32-byte secp256k1 private key (big-endian magnitude).
    public func getOrCreateSecp256k1PrivateKey32() throws -> Data {
        if let existing = try readKeychain(account: Self.keyTicketPriv) {
            return try DiodeHex.decode(existing)
        }

        let privateKey = try P256K.Recovery.PrivateKey()
        let priv32 = privateKey.dataRepresentation
        try writeKeychain(account: Self.keyTicketPriv, value: DiodeHex.encode(priv32))
        return priv32
    }

    /// Ethereum-style address (`0x` + 40 hex) for this install's TicketV2 signing key.
    public func getDeviceAddress0x() throws -> String {
        try Secp256k1Signer.address0x(fromPrivateKey32: getOrCreateSecp256k1PrivateKey32())
    }

    /// Opaque string stored in the ticket; stable per install.
    public func getOrCreateTicketLocalAddress() throws -> String {
        if let existing = try readKeychain(account: Self.keyLocalAddress) {
            return existing
        }
        let localAddress = "\(localAddressPrefix)\(UUID().uuidString.lowercased())"
        try writeKeychain(account: Self.keyLocalAddress, value: localAddress)
        return localAddress
    }

    public static func address0xFromSecp256k1PrivateKey32(_ priv32: Data) throws -> String {
        try Secp256k1Signer.address0x(fromPrivateKey32: priv32)
    }

    private static let keyTicketPriv = "ticket_secp256k1_priv_hex"
    private static let keyLocalAddress = "ticket_local_address"

    private func readKeychain(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw DeviceKeyStoreError.keychainReadFailed(status)
        }
        guard let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
            throw DeviceKeyStoreError.invalidStoredValue
        }
        return value
    }

    private func writeKeychain(account: String, value: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }
        if updateStatus != errSecItemNotFound {
            throw DeviceKeyStoreError.keychainWriteFailed(updateStatus)
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw DeviceKeyStoreError.keychainWriteFailed(addStatus)
        }
    }
}

public enum DeviceKeyStoreError: Error {
    case keychainReadFailed(OSStatus)
    case keychainWriteFailed(OSStatus)
    case invalidStoredValue
}
