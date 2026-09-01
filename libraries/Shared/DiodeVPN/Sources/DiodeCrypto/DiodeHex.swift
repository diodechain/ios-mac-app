import Foundation

public enum DiodeHex {
    /// Elixir `DiodeClient.Base16.decode/1` only accepts `0x`/`0X`-prefixed hex (see `Base16.encode/2`).
    public static func ensureHex0xPrefix(_ hex: String) -> String {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("0x") {
            return trimmed
        }
        return "0x\(trimmed)"
    }

    /// 40 lowercase hex chars (20 bytes), no `0x`; nil if invalid.
    public static func normalizeAddressHex(_ raw: String) -> String? {
        var hex = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if hex.hasPrefix("0x") {
            hex = String(hex.dropFirst(2))
        }
        guard hex.count == 40 else { return nil }
        guard hex.allSatisfy({ $0.isHexDigit }) else { return nil }
        return hex
    }

    public static func decode(_ hex: String) throws -> Data {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if h.hasPrefix("0x") {
            h = String(h.dropFirst(2))
        }
        if h.count % 2 != 0 {
            h = "0" + h
        }
        guard !h.isEmpty else {
            return Data()
        }
        guard h.count.isMultiple(of: 2) else {
            throw DiodeHexError.invalidLength
        }
        var data = Data(capacity: h.count / 2)
        var index = h.startIndex
        while index < h.endIndex {
            let next = h.index(index, offsetBy: 2)
            guard let byte = UInt8(h[index..<next], radix: 16) else {
                throw DiodeHexError.invalidCharacter
            }
            data.append(byte)
            index = next
        }
        return data
    }

    public static func encode(_ bytes: Data, with0x: Bool = false) -> String {
        var result = with0x ? "0x" : ""
        result.reserveCapacity((with0x ? 2 : 0) + bytes.count * 2)
        for byte in bytes {
            result.append(String(format: "%02x", byte))
        }
        return result
    }

    public static func decodeBigInt(_ hex: String) throws -> UInt64 {
        let data = try decode(hex)
        guard !data.isEmpty else { return 0 }
        var value: UInt64 = 0
        for byte in data {
            guard value <= (UInt64.max >> 8) else {
                throw DiodeHexError.overflow
            }
            value = (value << 8) | UInt64(byte)
        }
        return value
    }
}

public enum DiodeHexError: Error {
    case invalidLength
    case invalidCharacter
    case overflow
}
