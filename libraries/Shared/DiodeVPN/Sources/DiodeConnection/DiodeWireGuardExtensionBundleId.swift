import Foundation

#if os(iOS)
enum DiodeWireGuardExtensionBundleId {
    static let provider: String = {
        #if DEBUG
        if Bundle.main.bundleIdentifier?.contains("debug") == true {
            return "ch.protonmail.vpn.debug.WireGuardiOS-Extension"
        }
        return "ch.protonmail.vpn.WireGuardiOS-Extension"
        #else
        return "ch.protonmail.vpn.WireGuardiOS-Extension"
        #endif
    }()
}
#elseif os(macOS)
enum DiodeWireGuardExtensionBundleId {
    static let provider = "ch.protonvpn.mac.WireGuard-Extension"
}
#else
enum DiodeWireGuardExtensionBundleId {
    static let provider = "ch.protonmail.vpn.WireGuardiOS-Extension"
}
#endif
