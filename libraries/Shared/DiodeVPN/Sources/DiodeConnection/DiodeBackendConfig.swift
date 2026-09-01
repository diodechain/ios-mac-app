//
//  DiodeBackendConfig.swift
//  DiodeConnection
//
//  Reads Diode credentials from app-injected values (ObfuscatedConstants) with
//  launch-argument overrides. The Console API key is never committed; inject it
//  at build time (see scripts/inject-diode-console-secrets.sh).

import DiodeNetwork
import Foundation

public enum DiodeBackendConfig {
    private enum LaunchArgument {
        static let consoleApiKey = "DIODE_CONSOLE_API_KEY"
        static let consoleFleetUuid = "DIODE_CONSOLE_FLEET_UUID"
        static let vpnYearlyProductId = "DIODE_VPN_YEARLY_PRODUCT_ID"
    }

    /// Values set by the app target from `ObfuscatedConstants` at startup.
    private static var injectedConsoleApiKey: String?
    private static var injectedConsoleFleetUuid: String?
    private static var injectedVpnYearlyProductId: String?

    public static func configure(
        consoleApiKey: String,
        consoleFleetUuid: String,
        vpnYearlyProductId: String
    ) {
        injectedConsoleApiKey = consoleApiKey
        injectedConsoleFleetUuid = consoleFleetUuid
        injectedVpnYearlyProductId = vpnYearlyProductId
    }

    /// Organization Console API key. Empty when not injected (fleet registration no-ops).
    public static var consoleApiKey: String {
        resolve(
            launchArgument: LaunchArgument.consoleApiKey,
            injected: injectedConsoleApiKey,
            fallback: ""
        )
    }

    /// Fleet UUID for Console `fleet.member.add` / `fleet.info`.
    public static var consoleFleetUuid: String {
        resolve(
            launchArgument: LaunchArgument.consoleFleetUuid,
            injected: injectedConsoleFleetUuid,
            fallback: NetworkConfig.diodeConsoleFleetUUID
        )
    }

    public static var vpnYearlyProductId: String {
        resolve(
            launchArgument: LaunchArgument.vpnYearlyProductId,
            injected: injectedVpnYearlyProductId,
            fallback: "diode_vpn_yearly"
        )
    }

    private static func resolve(
        launchArgument: String,
        injected: String?,
        fallback: String
    ) -> String {
        if let injected, !injected.isEmpty {
            return injected
        }
        if let override = launchArgumentValue(launchArgument), !override.isEmpty {
            return override
        }
        return fallback
    }

    private static func launchArgumentValue(_ key: String) -> String? {
        let prefix = "\(key)="
        for argument in ProcessInfo.processInfo.arguments where argument.hasPrefix(prefix) {
            let value = String(argument.dropFirst(prefix.count))
            return value.isEmpty ? nil : value
        }
        return nil
    }
}
