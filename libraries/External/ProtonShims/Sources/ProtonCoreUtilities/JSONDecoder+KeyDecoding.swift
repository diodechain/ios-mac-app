import Foundation

public extension JSONDecoder.KeyDecodingStrategy {
    static var decapitaliseFirstLetter: JSONDecoder.KeyDecodingStrategy {
        .custom { keys in
            let key = keys.last!.stringValue
            let first = key.prefix(1).lowercased()
            let rest = key.dropFirst()
            return AnyKey(stringValue: first + rest)!
        }
    }
}

private struct AnyKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
