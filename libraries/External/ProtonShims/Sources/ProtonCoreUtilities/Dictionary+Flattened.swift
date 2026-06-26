import Foundation

public extension Dictionary where Key == String {
    func flattened<T>(removing wildcard: String) -> [String: [String: [T]]] where Value == [String: [T]] {
        var result: [String: [String: [T]]] = [:]
        for (outerKey, inner) in self where outerKey != wildcard {
            var innerResult: [String: [T]] = [:]
            for (innerKey, values) in inner where innerKey != wildcard {
                innerResult[innerKey] = values
            }
            result[outerKey] = innerResult
        }
        return result
    }
}
