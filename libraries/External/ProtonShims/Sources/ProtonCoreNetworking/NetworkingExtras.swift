import Foundation

public typealias ProgressCompletion = (Progress) -> Void

public enum TrustKitWrapper {
    public static var current: AnyObject?

    public static func setUp() {
        current = nil
    }
}

public extension URLSession {
    var sessionConfiguration: URLSessionConfiguration {
        configuration
    }
}
