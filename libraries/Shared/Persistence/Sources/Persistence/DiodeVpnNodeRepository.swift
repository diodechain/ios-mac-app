//
//  Copyright (c) 2026 Diode

import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
public struct DiodeVpnNodeRepository: Sendable {
    public var getAll: @Sendable () -> [DiodeVpnNodeRecord] = { [] }
    public var replaceAll: @Sendable ([DiodeVpnNodeRecord]) -> Void
    public var recordConnectFailure: @Sendable (String) -> Void
    public var getConnectFailureTimestamps: @Sendable () -> [String: Int64] = { [:] }
}

public extension DependencyValues {
    var diodeVpnNodeRepository: DiodeVpnNodeRepository {
        get { self[DiodeVpnNodeRepositoryKey.self] }
        set { self[DiodeVpnNodeRepositoryKey.self] = newValue }
    }
}
