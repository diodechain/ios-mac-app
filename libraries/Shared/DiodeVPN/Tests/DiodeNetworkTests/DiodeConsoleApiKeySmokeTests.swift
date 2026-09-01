import XCTest
import DiodeNetwork

/// CI smoke: proves `DIODE_CONSOLE_API_KEY` was available at test time and authenticates
/// against Console (`fleet.info`). Outside CI, skips when the key was not injected.
final class DiodeConsoleApiKeySmokeTests: XCTestCase {
    func testApiKeyIsPresentAndValidAgainstConsoleFleetInfo() async throws {
        let apiKey = ProcessInfo.processInfo.environment["DIODE_CONSOLE_API_KEY"] ?? ""
        let inCI = isCIEnvironment()

        if apiKey.isEmpty {
            if inCI {
                XCTFail(
                    "DIODE_CONSOLE_API_KEY is empty in CI. " +
                        "Set GitHub Actions secret DIODE_CONSOLE_API_KEY (dck_…) and pass it into the job env."
                )
            } else {
                throw XCTSkip("Skipping Console API key smoke: DIODE_CONSOLE_API_KEY not set")
            }
            return
        }

        XCTAssertTrue(
            apiKey.hasPrefix("dck_"),
            "DIODE_CONSOLE_API_KEY should look like a Console org key (dck_…)"
        )

        do {
            let result = try await DiodeConsoleFleetRegistrar.fleetInfo(apiKey: apiKey)
            XCTAssertFalse(result.isEmpty, "fleet.info result empty")
        } catch let error as DiodeConsoleError {
            XCTFail("Console rejected key or fleet.info failed: \(error)")
        }
    }

    private func isCIEnvironment() -> Bool {
        let ci = ProcessInfo.processInfo.environment["CI"]
        let gha = ProcessInfo.processInfo.environment["GITHUB_ACTIONS"]
        return ci?.lowercased() == "true" || gha?.lowercased() == "true"
    }
}
