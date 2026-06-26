import Foundation

public struct UserSettings: Sendable {
    public struct Password: Sendable {
        public enum Mode: Sendable {
            case singlePassword
            case loginAndMailbox
        }

        public let mode: Mode

        public init(mode: Mode) {
            self.mode = mode
        }
    }

    public struct TwoFA: Sendable {
        public enum Enabled: Sendable {
            case off
            case totp
            case u2f
            case both
        }

        public let enabled: Enabled
        public let registeredKeys: [String]

        public init(enabled: Enabled, registeredKeys: [String]) {
            self.enabled = enabled
            self.registeredKeys = registeredKeys
        }
    }

    public let password: Password
    public let _2FA: TwoFA

    public init(password: Password, _2FA: TwoFA) {
        self.password = password
        self._2FA = _2FA
    }

    public static let `default` = UserSettings(
        password: .init(mode: .singlePassword),
        _2FA: .init(enabled: .both, registeredKeys: [])
    )
}
