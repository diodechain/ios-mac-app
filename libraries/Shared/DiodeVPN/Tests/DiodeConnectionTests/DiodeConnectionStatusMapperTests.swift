import DiodeNetwork
import Domain
import XCTest

@testable import DiodeConnection

final class DiodeConnectionStatusMapperTests: XCTestCase {
  func testConnectingMapsSpecAndServer() {
    let node = VpnNode(
      nodeIdHex: "0xabc",
      host: "203.0.113.1",
      name: "diode-eu1",
      latitude: 52.0,
      longitude: 21.0,
      city: "Warsaw",
      country: "PL"
    )
    let spec = ConnectionSpec(location: .country(code: "PL", order: .fastest), features: [])

    let status = DiodeConnectionStatusMapper.vpnConnectionStatus(
      phase: .connecting,
      spec: spec,
      node: node
    )

    XCTAssertEqual(status, .connecting(spec, DiodeConnectionStatusMapper.server(from: node)))
    XCTAssertEqual(status.server?.logical.exitCountryCode, "PL")
    XCTAssertEqual(status.server?.logical.name, "diode-eu1")
  }

  func testConnectedIncludesActual() {
    let node = VpnNode(nodeIdHex: "0xdef", host: "203.0.113.2", country: "US")
    let spec = ConnectionSpec.defaultFastest
    let connectedAt = Date(timeIntervalSince1970: 1_700_000_000)

    let status = DiodeConnectionStatusMapper.vpnConnectionStatus(
      phase: .connected,
      spec: spec,
      node: node,
      connectedDate: connectedAt
    )

    guard case let .connected(mappedSpec, actual) = status else {
      return XCTFail("Expected connected status")
    }
    XCTAssertNotNil(actual)
    XCTAssertEqual(mappedSpec, spec)
    XCTAssertEqual(actual?.connectedDate, connectedAt)
    XCTAssertEqual(actual?.vpnProtocol, .wireGuard(.udp))
    XCTAssertEqual(actual?.server.logical.id, "0xdef")
  }

  func testDisconnectedIgnoresNode() {
    let node = VpnNode(nodeIdHex: "0x1", host: "1.2.3.4")
    let spec = ConnectionSpec.defaultFastest

    let status = DiodeConnectionStatusMapper.vpnConnectionStatus(
      phase: .disconnected,
      spec: spec,
      node: node
    )

    XCTAssertEqual(status, .disconnected)
  }
}
