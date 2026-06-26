import Foundation
import ProtonCoreNetworking

public struct ForceUpgradeHelper {
    public struct Config {
        public static func mobile(_: URL) -> Config { Config() }
    }

    public init(config _: Config) {}
}

public final class ForceUpgradeAlert {
    public init() {}
}
