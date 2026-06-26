//
//  DiodeConnectBridge.swift
//  DiodeConnection
//
//  Entry bridge from LegacyCommon ConnectToVPN into the Diode connection stack.

import Dependencies
import Domain
import Foundation

public enum DiodeConnectBridge {
    public static func connect(
        spec: ConnectionSpec,
        trigger: UserInitiatedVPNChange.VPNTrigger?
    ) async throws {
        @Dependency(\.diodeConnectionCoordinator) var coordinator
        try await coordinator.connect(spec, trigger)
    }

    public static func disconnect() async throws {
        @Dependency(\.diodeConnectionCoordinator) var coordinator
        try await coordinator.disconnect()
    }
}
