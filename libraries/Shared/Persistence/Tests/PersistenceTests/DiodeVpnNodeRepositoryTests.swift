//
//  Copyright (c) 2026 Diode

import GRDB
import XCTest

@testable import Persistence

final class DiodeVpnNodeRepositoryTests: XCTestCase {
    private var repository: DiodeVpnNodeRepository!
    private var dbWriter: DatabaseWriter!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let config = DatabaseConfiguration.withTestExecutor(databaseType: .ephemeral)
        dbWriter = DatabaseWriter.from(databaseConfiguration: config)
        repository = DiodeVpnNodeRepository.live(dbWriter: dbWriter, executor: config.executor)
    }

    func testGetAllReturnsEmptyInitially() {
        XCTAssertTrue(repository.getAll().isEmpty)
    }

    func testReplaceAllSortsByHostOnRead() throws {
        let nodeB = DiodeVpnNodeRecord(
            nodeIdHex: "0000000000000000000000000000000000000002",
            host: "b.example.com",
            name: "B",
            updatedAt: 0
        )
        let nodeA = DiodeVpnNodeRecord(
            nodeIdHex: "0000000000000000000000000000000000000001",
            host: "a.example.com",
            name: "A",
            updatedAt: 0
        )

        repository.replaceAll([nodeB, nodeA])

        let all = repository.getAll()
        XCTAssertEqual(all.map(\.host), ["a.example.com", "b.example.com"])
        XCTAssertEqual(all.map(\.name), ["A", "B"])
    }

    func testReplaceAllIsAtomic() {
        let first = DiodeVpnNodeRecord(
            nodeIdHex: "0000000000000000000000000000000000000001",
            host: "first.example.com",
            updatedAt: 0
        )
        let second = DiodeVpnNodeRecord(
            nodeIdHex: "0000000000000000000000000000000000000002",
            host: "second.example.com",
            updatedAt: 0
        )

        repository.replaceAll([first])
        repository.replaceAll([second])

        let all = repository.getAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.host, "second.example.com")
    }

    func testReplaceAllSetsUpdatedAt() throws {
        let before = Int64(Date().timeIntervalSince1970 * 1000)
        repository.replaceAll([
            DiodeVpnNodeRecord(
                nodeIdHex: "0000000000000000000000000000000000000001",
                host: "node.example.com",
                updatedAt: 0
            ),
        ])
        let after = Int64(Date().timeIntervalSince1970 * 1000)

        let updatedAt = try XCTUnwrap(repository.getAll().first?.updatedAt)
        XCTAssertGreaterThanOrEqual(updatedAt, before)
        XCTAssertLessThanOrEqual(updatedAt, after)
    }

    func testConnectFailureTimestamps() {
        XCTAssertTrue(repository.getConnectFailureTimestamps().isEmpty)

        repository.recordConnectFailure(nodeIdHex: "0000000000000000000000000000000000000001")

        let timestamps = repository.getConnectFailureTimestamps()
        XCTAssertEqual(timestamps.count, 1)
        XCTAssertNotNil(timestamps["0000000000000000000000000000000000000001"])
    }

    func testConnectFailuresSurviveReplaceAll() {
        repository.replaceAll([
            DiodeVpnNodeRecord(
                nodeIdHex: "0000000000000000000000000000000000000001",
                host: "node.example.com",
                updatedAt: 0
            ),
        ])
        repository.recordConnectFailure(nodeIdHex: "0000000000000000000000000000000000000001")

        repository.replaceAll([
            DiodeVpnNodeRecord(
                nodeIdHex: "0000000000000000000000000000000000000002",
                host: "other.example.com",
                updatedAt: 0
            ),
        ])

        XCTAssertEqual(repository.getConnectFailureTimestamps().count, 1)
        XCTAssertNotNil(repository.getConnectFailureTimestamps()["0000000000000000000000000000000000000001"])
    }
}
