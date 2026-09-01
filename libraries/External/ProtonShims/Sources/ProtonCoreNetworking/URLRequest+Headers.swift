import Foundation

public extension URLRequest {
    var headers: [String: String] {
        allHTTPHeaderFields ?? [:]
    }
}
