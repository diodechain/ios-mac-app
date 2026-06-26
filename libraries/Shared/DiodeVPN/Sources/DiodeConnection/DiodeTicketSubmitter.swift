import DiodeCrypto
import DiodeRPC
import DiodeTicket
import Foundation

enum DiodeTicketSubmitter {
    struct SubmitResult: Sendable {
        let params: TicketV2.Params
        let lastSignedTotalBytes: UInt64
    }

    static func applyFleetHint(to params: TicketV2.Params, fleetHintHex: String?) -> TicketV2.Params {
        guard let fleetHintHex else { return params }
        let normalized = fleetHintHex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "0x", with: "", options: .caseInsensitive)
            .filter(\.isHexDigit)
        guard !normalized.isEmpty, let fleetBytes = try? DiodeHex.decode(normalized) else {
            return params
        }
        return TicketV2.Params(
            chainID: params.chainID,
            epoch: params.epoch,
            fleetContract20: fleetBytes,
            serverID20: params.serverID20,
            totalConnections: params.totalConnections,
            totalBytes: params.totalBytes,
            localAddress: params.localAddress
        )
    }

    static func submitWithRetries(
        rpc: DiodeRpcClient,
        baseParams: TicketV2.Params,
        initialTotalBytes: UInt64,
        privateKey32: Data,
        usageHint: UInt64? = nil,
        fleetHintHex: String? = nil
    ) async throws -> SubmitResult {
        var currentParams = applyFleetHint(to: baseParams, fleetHintHex: fleetHintHex)
        var lastSigned = initialTotalBytes
        if let usageHint {
            lastSigned = TicketCommitment.minimumTotalBytesForRetry(
                usage: usageHint,
                summaryConnections: 0,
                summaryBytes: 0,
                lastSignedBytes: lastSigned
            )
        }

        var ticketHex = try TicketV2.ticketHexForRpc(
            TicketV2.Params(
                chainID: currentParams.chainID,
                epoch: currentParams.epoch,
                fleetContract20: currentParams.fleetContract20,
                serverID20: currentParams.serverID20,
                totalConnections: currentParams.totalConnections,
                totalBytes: lastSigned,
                localAddress: currentParams.localAddress
            ),
            privateKey32: privateKey32
        )

        var attempt = 0
        while true {
            do {
                try await rpc.dioTicket(ticketHex: ticketHex)
                currentParams = TicketV2.Params(
                    chainID: currentParams.chainID,
                    epoch: currentParams.epoch,
                    fleetContract20: currentParams.fleetContract20,
                    serverID20: currentParams.serverID20,
                    totalConnections: currentParams.totalConnections,
                    totalBytes: lastSigned,
                    localAddress: currentParams.localAddress
                )
                return SubmitResult(params: currentParams, lastSignedTotalBytes: lastSigned)
            } catch let error as DiodeRpcClient.RpcException {
                guard case let .ticketTooLow(_, usage, summary, _, _) = error,
                      attempt < DiodeRpcClient.maxTooLowAttempts
                else {
                    throw error
                }
                attempt += 1
                let effectiveUsage: UInt64
                if attempt == 1, let usageHint {
                    effectiveUsage = max(usage, usageHint)
                } else {
                    effectiveUsage = usage
                }
                lastSigned = TicketCommitment.minimumTotalBytesForRetry(
                    usage: effectiveUsage,
                    summaryConnections: summary?.totalConnections ?? 0,
                    summaryBytes: summary?.totalBytes ?? 0,
                    lastSignedBytes: lastSigned
                )
                currentParams = TicketV2.Params(
                    chainID: currentParams.chainID,
                    epoch: currentParams.epoch,
                    fleetContract20: currentParams.fleetContract20,
                    serverID20: currentParams.serverID20,
                    totalConnections: currentParams.totalConnections,
                    totalBytes: lastSigned,
                    localAddress: currentParams.localAddress
                )
                ticketHex = try TicketV2.ticketHexForRpc(currentParams, privateKey32: privateKey32)
            }
        }
    }
}

private extension Character {
    var isHexDigit: Bool {
        ("0" ... "9").contains(self) || ("a" ... "f").contains(self) || ("A" ... "F").contains(self)
    }
}
