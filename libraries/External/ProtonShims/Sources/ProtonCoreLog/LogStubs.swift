import Foundation

public enum PMLogLevel: Int {
    case debug = 0
    case info = 1
    case warn = 2
    case error = 3
}

public enum PMLog {
    public static var callback: ((String, PMLogLevel) -> Void)?

    public static func setExternalLoggerHost(_: String) {}
    public static func disableExternalLogging() {}
}
