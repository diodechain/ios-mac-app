//
//  Created on 03/03/2024.
//
//  Copyright (c) 2024 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.

import Combine
import CommonNetworking
import Dependencies
import DiodeConnection
import DiodeNetwork
import Domain
import Ergonomics
import Foundation
import LegacyCommon
import Persistence
import PMLogger
import ProtonCoreFoundations
import Sharing

// MARK: Live implementations of app dependencies

extension DatabaseConfigurationKey: @retroactive DependencyKey {
    public static let liveValue: DatabaseConfiguration = .live
}

extension ChallengeParametersProviderKey: @retroactive DependencyKey {
    public static let liveValue: ChallengeParametersProvider = .empty
}

extension DoHConfigurationKey: @retroactive DependencyKey {
    public static var liveValue: DoHVPN {
        @Dependency(\.propertiesManager) var propertiesManager
        var cancellables: Set<AnyCancellable> = []

        let customHost = Bundle.dynamicDomain ?? propertiesManager.apiEndpoint
        let atlasSecret = Bundle.atlasSecret ?? propertiesManager.atlasSecret
        log.info("Custom host: \(optional: customHost), atlasSecret: \(optional: atlasSecret)")

        @Shared(.alternativeRouting) var alternativeRouting

        let doh = DoHVPN(
            alternativeRouting: alternativeRouting,
            customHost: customHost,
            atlasSecret: atlasSecret
        )

        $alternativeRouting.publisher.sink { alternativeRouting in
            doh.alternativeRouting = alternativeRouting
        }.store(in: &cancellables)

        return doh
    }
}

extension DoHVPN {
    convenience init(alternativeRouting: Bool, customHost: String?, atlasSecret: String?) {
        self.init(
            apiHost: ObfuscatedConstants.apiHost,
            verifyHost: ObfuscatedConstants.humanVerificationV3Host,
            alternativeRouting: alternativeRouting,
            customHost: customHost,
            atlasSecret: atlasSecret,
            // Will get updated once AppStateManager is initialized
            isConnected: false,
            isAppStateNotificationConnected: DoHVPN.isAppStateChangeNotificationInConnectedState
        )
    }
}

extension DiodeBackendConfig {
    static func configureFromObfuscatedConstantsIfNeeded() {
        guard DiodeBackend.isEnabled else { return }
        configure(
            consoleApiKey: ObfuscatedConstants.diodeConsoleApiKey,
            consoleFleetUuid: ObfuscatedConstants.diodeConsoleFleetUuid,
            vpnYearlyProductId: ObfuscatedConstants.diodeVpnYearlyProductId
        )
    }
}

extension DiodeVpnNodeCacheKey: @retroactive DependencyKey {
    public static var liveValue: DiodeVpnNodeCache {
        guard DiodeBackend.isEnabled else { return .inMemory }
        @Dependency(\.diodeVpnNodeRepository) var repository
        return DiodeVpnNodeCache(
            getAll: { repository.getAll().map(macVpnNode(from:)) },
            lastRefreshEpochMs: { repository.getAll().map(\.updatedAt).max() },
            replaceAll: { nodes in
                let now = Int64(Date().timeIntervalSince1970 * 1000)
                repository.replaceAll(nodes.map { macDiodeRecord(from: $0, updatedAt: now) })
            },
            recordConnectFailure: { repository.recordConnectFailure($0) },
            getConnectFailureTimestamps: { repository.getConnectFailureTimestamps() }
        )
    }
}

private func macVpnNode(from record: DiodeVpnNodeRecord) -> VpnNode {
    VpnNode(
        nodeIdHex: record.nodeIdHex,
        host: record.host,
        name: record.name,
        latitude: record.latitude,
        longitude: record.longitude,
        city: record.city,
        country: record.country,
        wsRpcURLOverride: record.wsRpcUrlOverride,
        httpRpcURLOverride: record.httpRpcUrlOverride
    )
}

private func macDiodeRecord(from node: VpnNode, updatedAt: Int64) -> DiodeVpnNodeRecord {
    DiodeVpnNodeRecord(
        nodeIdHex: node.nodeIdHex,
        host: node.host,
        name: node.name,
        latitude: node.latitude,
        longitude: node.longitude,
        city: node.city,
        country: node.country,
        wsRpcUrlOverride: node.wsRpcURLOverride,
        httpRpcUrlOverride: node.httpRpcURLOverride,
        updatedAt: updatedAt
    )
}

extension LogicalsClient: @retroactive DependencyKey {
    public static var liveValue: LogicalsClient {
        guard DiodeBackend.isEnabled else {
            return .proton
        }
        return LogicalsClient(
            fetchLogicals: { _, countryCode in
                try await DiodeLogicalsLive.fetchLogicals(countryCode: countryCode)
            },
            fetchLoads: { _ in
                try await DiodeLogicalsLive.fetchLoads()
            }
        )
    }
}

enum DiodeBackendLiveConfiguration {
    static func syncServerListIfNeeded() {
        guard DiodeBackend.isEnabled else { return }
        Task {
            @Dependency(\.logicalsClient) var logicalsClient
            @Dependency(\.serverManager) var serverManager
            do {
                let servers = try await logicalsClient.fetchLogicals(ip: nil, countryCode: nil)
                serverManager.update(servers: servers, freeServersOnly: false, lastModifiedAt: nil)
            } catch {
                log.error("Failed to sync Diode server list", category: .api, metadata: ["error": "\(error)"])
            }
        }
    }
}

extension CustomHostValidator: @retroactive DependencyKey {
    /// By default, `testValue` defined in `CommonNetworking` uses release host validation.
    /// Let's override it here when building for staging or debug.
    /// This cannot be done in `CommonNetworking` until SPM decides to allow more than just
    /// `debug` and `release` build configurations.
    public static let liveValue: CustomHostValidator = {
        #if DEBUG || STAGING
            log.info("Using debug custom host validator", category: .api)
            return CustomHostValidator.debug
        #else
            return CustomHostValidator.release
        #endif
    }()
}

extension VPNNetworkingKey: @retroactive DependencyKey {
    public static let liveValue: VPNNetworking = {
        #if TLS_PIN_DISABLE
            let pinAPIEndpoints = false
        #else
            let pinAPIEndpoints = true
        #endif

        let networking = CoreNetworking(pinApiEndpoints: pinAPIEndpoints)

        return CoreNetworkingWrapper(wrapped: networking)
    }()
}

extension AppInfoKey: @retroactive DependencyKey {
    public static var liveValue: AppInfo = {
        @Dependency(\.propertiesManager) var propertiesManager

        return .live(context: .mainApp, beta: propertiesManager.earlyAccess)
    }()
}
