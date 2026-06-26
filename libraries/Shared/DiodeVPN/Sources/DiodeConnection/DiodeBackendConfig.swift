//
//  DiodeBackendConfig.swift
//  DiodeConnection
//
//  Reads Diode credentials from app-injected values (ObfuscatedConstants) with
//  DEBUG launch-argument overrides matching the Environment Selector pattern.

import Domain
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

    public static var consoleApiKey: String {
        #if DEBUG
        resolve(
            launchArgument: LaunchArgument.consoleApiKey,
            injected: injectedConsoleApiKey,
            debugFallback: debugFallbackConsoleApiKey
        )
        #else
        resolve(
            launchArgument: LaunchArgument.consoleApiKey,
            injected: injectedConsoleApiKey,
            debugFallback: ""
        )
        #endif
    }

    public static var consoleFleetUuid: String {
        #if DEBUG
        resolve(
            launchArgument: LaunchArgument.consoleFleetUuid,
            injected: injectedConsoleFleetUuid,
            debugFallback: debugFallbackFleetUuid
        )
        #else
        resolve(
            launchArgument: LaunchArgument.consoleFleetUuid,
            injected: injectedConsoleFleetUuid,
            debugFallback: ""
        )
        #endif
    }

    public static var vpnYearlyProductId: String {
        resolve(
            launchArgument: LaunchArgument.vpnYearlyProductId,
            injected: injectedVpnYearlyProductId,
            debugFallback: "diode_vpn_yearly"
        )
    }

    private static func resolve(
        launchArgument: String,
        injected: String?,
        debugFallback: String
    ) -> String {
        if let injected, !injected.isEmpty {
            return injected
        }
        #if DEBUG
        if let override = ProcessInfo.processInfo.firstArgumentValue(forKey: launchArgument),
           !override.isEmpty
        {
            return override
        }
        return debugFallback
        #else
        return ""
        #endif
    }

    #if DEBUG
    // Android NetworkConfig.kt parity for local development.
    private static let debugFallbackConsoleApiKey =
        "dck_4c4511c6bf7943a17a0a720cc90c22bc24968f9c214e9e48"
    private static let debugFallbackFleetUuid = "75894474-0117-4f83-89d1-ee8f260c490b"
    #endif
}
