import Foundation

public func VpnPingPingSyncWithError(
    _: String,
    _: Int,
    _: String,
    _: Int,
    _ ret: UnsafeMutablePointer<ObjCBool>,
    _: NSErrorPointer
) -> Bool {
    ret.pointee = false
    return false
}
