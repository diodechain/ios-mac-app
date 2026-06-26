//
//  DiodeSessionBootstrap.swift
//  DiodeConnection
//

import Domain
import Foundation

/// Establishes app navigation without Proton OAuth (G2-5 Option A).
public enum DiodeSessionBootstrap {
    /// Warms the Diode node list; does not create Proton auth credentials or `UserInfo`.
    public static func warmServerList() async {
        _ = try? await DiodeServerListRepository.shared.cachedOrFetchNodes()
    }

    public static var isEnabled: Bool {
        DiodeBackend.isEnabled
    }
}
