import DiodeCrypto
import DiodeNetwork
import Foundation

/// App-launch tasks for Diode backend builds (fleet registration, server list warm-up).
public enum DiodeAppLifecycle {
    public static func onAppLaunch(appLabel: String) {
        DiodeSubscriptionService.shared.start()
        Task {
            await registerFleetIfPossible(label: appLabel)
            _ = try? await DiodeServerListRepository.shared.refreshNodes()
        }
    }

    private static func registerFleetIfPossible(label: String) async {
        do {
            let keys = DeviceKeyStore()
            let address = try keys.getDeviceAddress0x()
            await DiodeConsoleFleetRegistrar.registerOnLaunch(
                deviceAddress0x: address,
                label: label,
                apiKey: DiodeBackendConfig.consoleApiKey,
                fleetUUID: DiodeBackendConfig.consoleFleetUuid
            )
        } catch {
            // Best-effort; connect may still work if device was registered earlier.
        }
    }
}
