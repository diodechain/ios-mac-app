import Foundation

@objc public final class LocalAgentFeatures: NSObject {
    @objc public override init() {
        super.init()
    }

    @objc public func hasKey(_: String) -> Bool { false }
    @objc public func getInt(_: String) -> Int64 { 0 }
    @objc public func getBool(_: String) -> Bool { false }
    @objc public func getString(_: String) -> String { "" }
    @objc public func setBool(_: String, value _: Bool) {}
    @objc public func setInt(_: String, value _: Int64) {}
    @objc public func setString(_: String, value _: String) {}
}

@objc public final class LocalAgentAgentConnection: NSObject {
    @objc public dynamic var state: String { "Disconnected" }
    @objc public var status: LocalAgentStatusMessage?

    @objc public func close() {}
    @objc public func setConnectivity(_: Bool) {}
    @objc public func setFeatures(_: LocalAgentFeatures?) {}
    @objc public func sendGetStatus(_: Bool) {}
}

@objc public final class LocalAgentConnectionDetails: NSObject {
    @objc public var serverIpv4: String = ""
    @objc public var serverIpv6: String = ""
    @objc public var deviceIp: String = ""
    @objc public var deviceCountry: String = ""
}

@objc public final class LocalAgentStatusMessage: NSObject {
    @objc public var connectionDetails: LocalAgentConnectionDetails?
    @objc public var featuresStatistics: LocalAgentStringToValueMap?
    @objc public var features: LocalAgentFeatures?
}

@objc public final class LocalAgentStringToValueMap: NSObject {
    @objc public func hasKey(_: String) -> Bool { false }
    @objc public func getInt(_: String) -> Int64 { 0 }
    @objc public func getMap(_: String) -> LocalAgentStringToValueMap? { nil }

    @objc public func marshalJSON() throws -> Data {
        Data("{}".utf8)
    }
}

@objc public protocol LocalAgentNativeClientProtocol {
    func onTlsSessionEnded()
    func onTlsSessionStarted()
    func log(_ text: String?)
    func onError(_ code: Int, description: String?)
    func onState(_ state: String?)
    func onStatusUpdate(_ status: LocalAgentStatusMessage?)
}

@objc public final class LocalAgentConsts: NSObject {
    @objc public var stateConnected: String { "Connected" }
    @objc public var stateConnecting: String { "Connecting" }
    @objc public var stateWaitingForNetwork: String { "WaitingForNetwork" }
    @objc public var stateConnectionError: String { "ConnectionError" }
    @objc public var stateDisconnected: String { "Disconnected" }
    @objc public var stateHardJailed: String { "HardJailed" }
    @objc public var stateServerUnreachable: String { "ServerUnreachable" }
    @objc public var stateServerCertificateError: String { "ServerCertificateError" }
    @objc public var stateClientCertificateUnknownCA: String { "ClientCertificateUnknownCA" }
    @objc public var stateClientCertificateExpiredError: String { "ClientCertificateExpired" }
    @objc public var stateSoftJailed: String { "SoftJailed" }

    @objc public var errorCodeRestrictedServer: Int { 1 }
    @objc public var errorCodeCertificateExpired: Int { 2 }
    @objc public var errorCodeCertificateRevoked: Int { 3 }
    @objc public var errorCodeMaxSessionsUnknown: Int { 4 }
    @objc public var errorCodeMaxSessionsFree: Int { 5 }
    @objc public var errorCodeMaxSessionsBasic: Int { 6 }
    @objc public var errorCodeMaxSessionsPlus: Int { 7 }
    @objc public var errorCodeMaxSessionsVisionary: Int { 8 }
    @objc public var errorCodeMaxSessionsPro: Int { 9 }
    @objc public var errorCodeKeyUsedMultipleTimes: Int { 10 }
    @objc public var errorCodeServerError: Int { 11 }
    @objc public var errorCodePolicyViolationLowPlan: Int { 12 }
    @objc public var errorCodePolicyViolationDelinquent: Int { 13 }
    @objc public var errorCodeUserTorrentNotAllowed: Int { 14 }
    @objc public var errorCodeUserBadBehavior: Int { 15 }
    @objc public var errorCodeGuestSession: Int { 16 }
    @objc public var errorCodeBadCertSignature: Int { 17 }
    @objc public var errorCodeCertNotProvided: Int { 18 }

    @objc public var statsNetshieldLevelKey: String { "netshield" }
    @objc public var statsMalwareKey: String { "malware" }
    @objc public var statsAdsKey: String { "ads" }
    @objc public var statsTrackerKey: String { "tracker" }
    @objc public var statsSavedBytesKey: String { "savedBytes" }
}

public func LocalAgentConstants() -> LocalAgentConsts? {
    LocalAgentConsts()
}

public func LocalAgentNewFeatures() -> LocalAgentFeatures? {
    LocalAgentFeatures()
}

public func LocalAgentNewAgentConnection(
    _: String,
    _: String,
    _: String,
    _: String,
    _: String,
    _: LocalAgentNativeClientProtocol,
    _: LocalAgentFeatures?,
    _: Bool,
    _: Int,
    _: Int,
    _: NSErrorPointer
) -> LocalAgentAgentConnection? {
    LocalAgentAgentConnection()
}

public func LocalAgentNewAgentConnection(
    _: String,
    _: Data,
    _: String,
    _: String,
    _: String,
    _: LocalAgentNativeClientProtocol,
    _: LocalAgentFeatures?,
    _: Bool,
    _: Int,
    _: Int,
    _: NSErrorPointer
) -> LocalAgentAgentConnection? {
    LocalAgentAgentConnection()
}
