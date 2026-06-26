//
//  Copyright (c) 2026 Diode

import Dependencies
import Foundation
import GRDB

public enum DiodeVpnNodeRepositoryKey: DependencyKey {
    public static var liveValue: DiodeVpnNodeRepository {
        @Dependency(\.databaseConfiguration) var config
        let dbWriter = DatabaseQueue.from(databaseConfiguration: config)
        return DiodeVpnNodeRepository.live(dbWriter: dbWriter, executor: config.executor)
    }
}

extension DiodeVpnNodeRepositoryKey: TestDependencyKey {
    public static var testValue: DiodeVpnNodeRepository {
        let config = DatabaseConfiguration.withTestExecutor(databaseType: .ephemeral)
        let dbWriter = DatabaseQueue.from(databaseConfiguration: config)
        return DiodeVpnNodeRepository.live(dbWriter: dbWriter, executor: config.executor)
    }
}

public extension DiodeVpnNodeRepository {
    static func live(dbWriter: DatabaseWriter, executor: DatabaseExecutor) -> DiodeVpnNodeRepository {
        DiodeVpnNodeRepository(
            getAll: {
                executor.read(dbWriter: dbWriter) { db in
                    try DiodeVpnNodeRecord
                        .order(DiodeVpnNodeRecord.Columns.host)
                        .fetchAll(db)
                }
            },
            replaceAll: { nodes in
                let now = Int64(Date().timeIntervalSince1970 * 1000)
                executor.write(dbWriter: dbWriter) { db in
                    try db.inTransaction {
                        try DiodeVpnNodeRecord.deleteAll(db)
                        for node in nodes {
                            let record = DiodeVpnNodeRecord(
                                nodeIdHex: node.nodeIdHex,
                                host: node.host,
                                name: node.name,
                                latitude: node.latitude,
                                longitude: node.longitude,
                                city: node.city,
                                country: node.country,
                                wsRpcUrlOverride: node.wsRpcUrlOverride,
                                httpRpcUrlOverride: node.httpRpcUrlOverride,
                                updatedAt: now
                            )
                            try record.insert(db, onConflict: .replace)
                        }
                        return .commit
                    }
                }
            },
            recordConnectFailure: { nodeIdHex in
                let failedAt = Int64(Date().timeIntervalSince1970 * 1000)
                executor.write(dbWriter: dbWriter) { db in
                    try DiodeVpnConnectFailureRecord(nodeIdHex: nodeIdHex, failedAt: failedAt)
                        .insert(db, onConflict: .replace)
                }
            },
            getConnectFailureTimestamps: {
                executor.read(dbWriter: dbWriter, operation: { db in
                    try DiodeVpnConnectFailureRecord.fetchAll(db).reduce(into: [String: Int64]()) { result, row in
                        result[row.nodeIdHex] = row.failedAt
                    }
                }, fallback: [:])
            }
        )
    }
}
