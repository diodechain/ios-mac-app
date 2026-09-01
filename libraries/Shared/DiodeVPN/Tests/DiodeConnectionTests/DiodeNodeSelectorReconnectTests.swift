import DiodeNetwork
import XCTest
@testable import DiodeConnection

final class DiodeNodeSelectorReconnectTests: XCTestCase {
    func testSameCountryReconnect_seedFirstThenNeverFailedThenOldestFailure() {
        let seed = VpnNode(nodeIdHex: "aa", host: "1.1.1.1", name: "seed", country: "US")
        let neverFailed = VpnNode(nodeIdHex: "bb", host: "2.2.2.2", name: "never", country: "US")
        let oldFail = VpnNode(nodeIdHex: "cc", host: "3.3.3.3", name: "old", country: "US")
        let newFail = VpnNode(nodeIdHex: "dd", host: "4.4.4.4", name: "new", country: "US")
        let otherCountry = VpnNode(nodeIdHex: "ee", host: "5.5.5.5", name: "de", country: "DE")
        let now: Int64 = 1_000_000
        let failures: [String: Int64] = [
            "cc": now - 10_000,
            "dd": now - 1_000,
        ]
        let ordered = DiodeNodeSelector.sameCountryReconnectCandidates(
            seedNode: seed,
            cachedServers: [seed, neverFailed, oldFail, newFail, otherCountry],
            failureTimestamps: failures,
            nowMs: now
        )
        XCTAssertEqual(ordered.map(\.nodeIdHex), ["aa", "bb", "cc", "dd"])
    }

    func testSameCountryReconnect_staleFailureSortedAsNeverFailed() {
        let seed = VpnNode(nodeIdHex: "aa", host: "1.1.1.1", country: "US")
        let stale = VpnNode(nodeIdHex: "bb", host: "2.2.2.2", name: "stale", country: "US")
        let recent = VpnNode(nodeIdHex: "cc", host: "3.3.3.3", name: "recent", country: "US")
        let now: Int64 = 1_000_000
        let staleCutoff = Int64(DiodeNodeSelector.staleFailureSeconds * 1000)
        let failures: [String: Int64] = [
            "bb": now - staleCutoff - 1,
            "cc": now - 1_000,
        ]
        let ordered = DiodeNodeSelector.sameCountryReconnectCandidates(
            seedNode: seed,
            cachedServers: [seed, stale, recent],
            failureTimestamps: failures,
            nowMs: now
        )
        XCTAssertEqual(ordered.map(\.nodeIdHex), ["aa", "bb", "cc"])
    }
}
