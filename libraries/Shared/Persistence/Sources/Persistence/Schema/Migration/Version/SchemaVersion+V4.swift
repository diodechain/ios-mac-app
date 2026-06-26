//
//  Copyright (c) 2026 Diode
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

import Foundation

import GRDB

public extension SchemaVersion {
    static let v4: SchemaVersion = {
        let migrationBlock: MigrationBlock = { db in
            try db.create(table: "diode_vpn_nodes") { t in
                t.column("node_id_hex", .text).notNull().primaryKey()
                t.column("host", .text).notNull()
                t.column("name", .text)
                t.column("latitude", .double)
                t.column("longitude", .double)
                t.column("city", .text)
                t.column("country", .text)
                t.column("ws_rpc_url_override", .text)
                t.column("http_rpc_url_override", .text)
                t.column("updated_at", .integer).notNull()
            }

            try db.create(table: "diode_vpn_connect_failures") { t in
                t.column("node_id_hex", .text).notNull().primaryKey()
                t.column("failed_at", .integer).notNull()
            }
        }

        return SchemaVersion(identifier: "diode_vpn_nodes", migrationBlock: migrationBlock)
    }()
}
