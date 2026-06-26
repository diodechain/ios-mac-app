import Foundation

/**
 * Computes TicketV2 `total_bytes` for a follow-up `dio_ticket` after `too_low` or
 * `dio_ticket_request`, per feature-message.md (`usage` + score beat `summary`).
 */
public enum TicketCommitment {
    /// Ticket score: `total_connections * 1024 + total_bytes` (matches `Ticket.score/1` on the node).
    public static func ticketScore(totalConnections: UInt64, totalBytes: UInt64) -> UInt64 {
        totalConnections * 1024 + totalBytes
    }

    /**
     * Next `total_bytes` for a ticket with `total_connections = 0` that satisfies:
     * - `total_bytes >= usage` (with refresh headroom)
     * - `score(new) > score(summary)` when summary fields are known
     * - respects `NetworkConfigConstants.ticketMaxStepBytes` per hop from `lastSignedBytes`
     */
    public static func minimumTotalBytesForRetry(
        usage: UInt64,
        summaryConnections: UInt64,
        summaryBytes: UInt64,
        lastSignedBytes: UInt64
    ) -> UInt64 {
        let headroom = NetworkConfigConstants.ticketRefreshHeadroomBytes
        let maxStep = NetworkConfigConstants.ticketMaxStepBytes
        let summaryScore = ticketScore(totalConnections: summaryConnections, totalBytes: summaryBytes)
        let minFromUsage = usage + headroom
        let minFromScore = summaryScore + 1
        let minCover = max(minFromUsage, minFromScore)
        var target = max(minCover, lastSignedBytes + headroom)
        if target - lastSignedBytes > maxStep {
            target = lastSignedBytes + maxStep
            if target < minCover {
                target = minCover
            }
        }
        return target
    }
}
