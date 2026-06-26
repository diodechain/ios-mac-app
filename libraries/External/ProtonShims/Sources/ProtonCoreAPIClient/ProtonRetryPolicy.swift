import Foundation

public enum ProtonRetryPolicy {
    public enum RetryMode {
        case background
        case foreground
        case userInitiated
        case none
    }
}
