import Foundation

public enum PMLogLevel: Int {
    case debug = 0
    case info = 1
    case warn = 2
    case error = 3
    case trace = 4
    case fatal = 5
}

public enum PMLog {
    public static var callback: ((String, PMLogLevel) -> Void)?

    public static func setExternalLoggerHost(_: String) {}
    public static func disableExternalLogging() {}
}
