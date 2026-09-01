import DiodeConnection
import DiodeNetwork
import Domain
import XCTest

final class DiodeVpnNodeAdapterTests: XCTestCase {
    func testMapsNodesToVpnServersWithUppercaseCountryCodes() {
        let nodes = [
            VpnNode(
                nodeIdHex: "0xAbCdEf0123456789AbCdEf0123456789AbCdEf01",
                host: "de1.example.com",
                name: "Diode EU 1",
                latitude: 52.52,
                longitude: 13.405,
                city: "Berlin",
                country: "de"
            ),
            VpnNode(
                nodeIdHex: "0xfedcba0987654321fedcba0987654321fedcba09",
                host: "us1.example.com",
                name: "Diode US 1",
                latitude: 40.7128,
                longitude: -74.0060,
                city: "New York",
                country: "US"
            ),
        ]

        let servers = DiodeVpnNodeAdapter.toVpnServers(from: nodes)

        XCTAssertEqual(servers.count, 2)
        XCTAssertEqual(servers[0].logical.exitCountryCode, "DE")
        XCTAssertEqual(servers[0].logical.entryCountryCode, "DE")
        XCTAssertEqual(servers[1].logical.exitCountryCode, "US")
        XCTAssertEqual(servers[1].logical.entryCountryCode, "US")
        XCTAssertEqual(servers[0].logical.city, "Berlin")
        XCTAssertEqual(servers[0].logical.latitude, 52.52, accuracy: 0.0001)
        XCTAssertEqual(servers[0].logical.longitude, 13.405, accuracy: 0.0001)
        XCTAssertEqual(servers[0].logical.name, "Diode EU 1")
    }

    func testLogicalIDsAreStableFromNodeIDHex() {
        let node = VpnNode(
            nodeIdHex: "0xABCDEF0123456789ABCDEF0123456789ABCDEF01",
            host: "node.example.com",
            name: "Node",
            country: "CH"
        )

        let servers = DiodeVpnNodeAdapter.toVpnServers(from: [node])
        let expectedLogicalID = "diode-abcdef0123456789abcdef0123456789abcdef01"

        XCTAssertEqual(servers[0].id, expectedLogicalID)
        XCTAssertEqual(DiodeVpnNodeAdapter.logicalID(forNodeIDHex: node.nodeIdHex), expectedLogicalID)
        XCTAssertEqual(DiodeVpnNodeAdapter.nodeIDHex(forLogicalID: expectedLogicalID), "abcdef0123456789abcdef0123456789abcdef01")
    }

    func testWireGuardEndpointIsCreatedPerNode() {
        let node = VpnNode(
            nodeIdHex: "0x1111111111111111111111111111111111111111",
            host: "10.0.0.1",
            name: "WG Node",
            country: "NL"
        )

        let server = DiodeVpnNodeAdapter.toVpnServers(from: [node])[0]

        XCTAssertEqual(server.endpoints.count, 1)
        XCTAssertTrue(server.supportedProtocols.contains(.wireGuardUDP))
        XCTAssertEqual(server.endpoints[0].exitIp, "10.0.0.1")
        XCTAssertEqual(server.endpoints[0].overridePorts(using: .wireGuard(.udp)), [node.wireguardPort])
    }

    func testNodeCountMatchesLogicalCount() {
        let nodes = (0 ..< 5).map { index in
            VpnNode(
                nodeIdHex: String(format: "0x%040x", index + 1),
                host: "host-\(index).example.com",
                name: "Node \(index)",
                country: "FR"
            )
        }

        let servers = DiodeVpnNodeAdapter.toVpnServers(from: nodes)

        XCTAssertEqual(servers.count, nodes.count)
        XCTAssertEqual(Set(servers.map(\.id)).count, nodes.count)
    }
}
