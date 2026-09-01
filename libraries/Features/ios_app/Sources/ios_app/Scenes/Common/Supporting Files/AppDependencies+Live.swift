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
import ProtonCoreChallenge
import ProtonCoreFoundations
import Sharing

// MARK: Live implementations of app dependencies

extension DatabaseConfigurationKey: @retroactive DependencyKey {
    public static let liveValue: DatabaseConfiguration = .live
}

extension AppInfoKey: @retroactive DependencyKey {
    public static let liveValue: AppInfo = .live(context: .mainApp, beta: Bundle.isTestflight)
}

extension ChallengeParametersProviderKey: @retroactive DependencyKey {
    public static let liveValue: ChallengeParametersProvider = .forAPIService(clientApp: .vpn, challenge: PMChallenge())
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
    /// Injects app-target `ObfuscatedConstants` into Diode backend configuration.
    public static func configureFromObfuscatedConstantsIfNeeded(
        consoleApiKey: String,
        consoleFleetUuid: String,
        vpnYearlyProductId: String
    ) {
        guard DiodeBackend.isEnabled else { return }
        configure(
            consoleApiKey: consoleApiKey,
            consoleFleetUuid: consoleFleetUuid,
            vpnYearlyProductId: vpnYearlyProductId
        )
    }
}

extension DiodeVpnNodeCacheKey: @retroactive DependencyKey {
    public static var liveValue: DiodeVpnNodeCache {
        guard DiodeBackend.isEnabled else { return .inMemory }
        @Dependency(\.diodeVpnNodeRepository) var repository
        return persistenceBackedDiodeVpnNodeCache(repository: repository)
    }
}

private func persistenceBackedDiodeVpnNodeCache(
    repository: DiodeVpnNodeRepository
) -> DiodeVpnNodeCache {
    DiodeVpnNodeCache(
        getAll: {
            repository.getAll().map(vpnNode(from:))
        },
        lastRefreshEpochMs: {
            repository.getAll().map(\.updatedAt).max()
        },
        replaceAll: { nodes in
            let now = Int64(Date().timeIntervalSince1970 * 1000)
            repository.replaceAll(nodes.map { diodeVpnNodeRecord(from: $0, updatedAt: now) })
        },
        recordConnectFailure: { nodeIdHex in
            repository.recordConnectFailure(nodeIdHex)
        },
        getConnectFailureTimestamps: {
            repository.getConnectFailureTimestamps()
        }
    )
}

private func vpnNode(from record: DiodeVpnNodeRecord) -> VpnNode {
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

private func diodeVpnNodeRecord(from node: VpnNode, updatedAt: Int64) -> DiodeVpnNodeRecord {
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

public enum DiodeBackendLiveConfiguration {
    public static func configureIfNeeded(
        consoleApiKey: String,
        consoleFleetUuid: String,
        vpnYearlyProductId: String
    ) {
        DiodeBackendConfig.configureFromObfuscatedConstantsIfNeeded(
            consoleApiKey: consoleApiKey,
            consoleFleetUuid: consoleFleetUuid,
            vpnYearlyProductId: vpnYearlyProductId
        )
    }

    /// Pushes Diode nodes into `ServerManager` so Countries/Home read from the shared repository.
    public static func syncServerListIfNeeded() {
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
