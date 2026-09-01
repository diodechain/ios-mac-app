import Foundation

/// RLP encoding aligned with DiodeClient.Rlp / Ethereum RLP.
/// Unsigned integers use minimal big-endian; 0 encodes as empty byte array.
public enum DiodeRlp {
    private static let offsetShortString: UInt8 = 0x80
    private static let offsetShortList: UInt8 = 0xC0
    private static let offsetLongString: UInt8 = 0xB7
    private static let offsetLongList: UInt8 = 0xF7
    private static let maxShortPayload = 55

    public static func encodeUnsignedLong(_ value: UInt64) -> Data {
        if value == 0 {
            return Data()
        }
        var v = value
        var bytes = [UInt8]()
        while v != 0 {
            bytes.insert(UInt8(v & 0xFF), at: 0)
            v >>= 8
        }
        return Data(bytes)
    }

    public static func encodeStringUtf8(_ string: String) -> Data {
        encodeBytes(Data(string.utf8))
    }

    public static func encodeBytes(_ data: Data) -> Data {
        if data.count == 1, data[0] < offsetShortString {
            return data
        }
        return wrapWithLength(shortPrefix: offsetShortString, longPrefix: offsetLongString, payload: data)
    }

    /// RLP-encode a list of already-encoded RLP items (concatenate encodings, then wrap as list).
    public static func encodeListOfEncodedItems(_ encodedItems: [Data]) -> Data {
        var payload = Data()
        for item in encodedItems {
            payload.append(item)
        }
        return wrapWithLength(shortPrefix: offsetShortList, longPrefix: offsetLongList, payload: payload)
    }

    private static func wrapWithLength(shortPrefix: UInt8, longPrefix: UInt8, payload: Data) -> Data {
        let size = payload.count
        if size <= maxShortPayload {
            var result = Data([shortPrefix + UInt8(size)])
            result.append(payload)
            return result
        }
        let lenBytes = encodeUnsignedLong(UInt64(size))
        var result = Data([longPrefix + UInt8(lenBytes.count)])
        result.append(lenBytes)
        result.append(payload)
        return result
    }
}
