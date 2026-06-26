# Diode VPN — Implementation Progress

Live tracker for parallel subagent work. Update after each workstream lands.

**Plan:** [DIODE_VPN_PORT_PLAN.md](./DIODE_VPN_PORT_PLAN.md) §10  
**Status checklist:** [DIODE_VPN_PORT_STATUS.md](./DIODE_VPN_PORT_STATUS.md)

---

## Workstreams

| ID | Scope | Status | Tests | Notes |
|----|-------|--------|-------|-------|
| W1 | §10.1 GRDB `diode_vpn_nodes` + cache wiring | ✅ done | Persistence tests written; blocked without protoncore | `SchemaVersion+V4`, `DiodeVpnNodeRepository`; GRDB wired via `DiodeVpnNodeCache` in app `AppDependencies+Live` |
| W2 | §10.2 `DiodeSubscriptionService` + Payments shim | ✅ done | Entitlement evaluator tests written | `DiodePaymentsPlanServiceV2` (`#if DIODE_BACKEND`) |
| W3 | §10.4 `DiodeVpnNodeAdapter` + `LogicalsClient` swap | ✅ done | `DiodeVpnNodeAdapterTests` written | `syncServerListIfNeeded()` on launch |
| W4 | §10.2/§10.3 login bypass + `connectionBridge` status | ✅ done | `DiodeConnectionStatusMapperTests` written | `establishDiodeNavigationSession()`, coordinator `pushStatus` |
| W5 | §10.3 WG preflight IKpsk2 | ✅ done | `WireGuardHandshakeSelfTest` (6 tests) | `DiodeWireGuardPreflight` + IKpsk2 stack; mid-session `dio_ticket_request` via `DiodeActiveSession` |
| W6 | VpnApiClient Diode shim (server refresh) | ✅ done | | `diodeVpnProperties` stub; `AppSessionRefresher` guards; launch sync before session |

---

## End-to-end readiness

| Checkpoint | Status | Verified by |
|------------|--------|-------------|
| Lean crypto/RPC tests (no protoncore) | ✅ **10/10 pass** | `scripts/test-diode-lean.sh` |
| ProtonShims package (`swift build`) | ✅ | Local replacement for `external/protoncore` |
| Theme package (`swift build`) | ✅ | Diode `ColorProvider` + `IconProvider` shims |
| Domain / Localization / NEHelper | ✅ | `swift build` |
| DiodeVPN package (`swift build`) | ✅ | Includes Persistence + Connection graph |
| CommonNetworking (`swift build`) | ✅ | ProtonShims stubs: DoH, APIDecodableResponse, NSError, UserSettings, Authenticator |
| LegacyCommon (`swift build`) | ✅ | GoLibs LocalAgent/Crypto stubs; `ProtonCoreEnvironment.fidoPortal`; `PushNotificationServiceFactory` |
| ios_app (`Package.swift` graph) | ✅ | `DiodeConnection` product reference; SPM compile on macOS host blocked by iOS-only platform resolution |
| DiodeConnection tests | ✅ **24/24** | Preflight + handshake + ticket submitter |
| Xcode `DiodeVPN-iOS` / `DiodeVPN-macOS` schemes | ✅ wired | `Debug-Diode` + xcconfig; see `docs/DIODE_XCODE_SCHEMES.md` |
| Full Xcode workspace build | ⬜ | Needs `wireguard-apple` submodule + workspace SPM graph |
| Device connect (ticket → RPC → TUN) | ⬜ | Schemes ready; physical QA + secrets |

---

## Test commands

```bash
# Always-on (no protoncore): crypto + ticket + RPC
./scripts/test-diode-lean.sh

# Full DiodeVPN package (ProtonShims, no protoncore submodule)
cd libraries/Shared/DiodeVPN && swift build

# Theme / foundations
cd libraries/Foundations/Theme && swift build

# GRDB repository
cd libraries/Shared/Persistence && swift test --filter DiodeVpnNodeRepositoryTests
```

---

## Issues log

| # | Workstream | Severity | Description | Resolution |
|---|------------|----------|-------------|------------|
| I1 | Env | **resolved (in progress)** | `external/protoncore` replaced by `libraries/External/ProtonShims` | 22 `Package.swift` files repointed; submodule deprecated in `.gitmodules` |
| I2 | W3/W6 | **resolved** | Proton refresh could overwrite Diode server list | `diodeVpnProperties` + `AppSessionRefresher` guards + awaited launch sync |
| I3 | W3 | **resolved** | `DiodeNodeSelector` now resolves `diode-<hex>` logical IDs | `nodeIDHex(forLogicalID:)` + refactored selector |
| I4 | W5 | **resolved** | No WG preflight / mid-session ticket refresh | `DiodeWireGuardPreflight` + `DiodeActiveSession` lifecycle |

---

## Files added (this session)

### Persistence
- `Schema/Migration/Version/SchemaVersion+V4.swift`
- `Schema/Tables/DiodeVpnNodeRecord.swift`
- `DiodeVpnNodeRepository.swift`, `DiodeVpnNodeRepository+Live.swift`
- `Tests/PersistenceTests/DiodeVpnNodeRepositoryTests.swift`

### DiodeVPN / DiodeConnection
- `DiodeVpnNodeCache.swift` — persistence boundary (GRDB wired in app)
- `DiodeSubscriptionService.swift`, `DiodePaymentsPlanServiceV2.swift` (Payments)
- `DiodeVpnNodeAdapter.swift`, `DiodeLogicalsLive.swift`
- `DiodeConnectionStatusMapper.swift`, `DiodeSessionBootstrap.swift`
- Tests: adapter, entitlement, status mapper, subscription evaluator

### App integration (no UI edits)
- iOS/macOS `AppDependencies+Live.swift` — `LogicalsClient`, `DiodeVpnNodeCache`, `syncServerListIfNeeded`
- iOS/macOS `AppSessionManager` — login bypass
- macOS `NavigationService`, `LoginViewModel`
- `SharedPropertiesFeature` — macOS status stream
- `DisconnectVPN` — Diode disconnect path

### Tooling
- `libraries/Shared/DiodeVPN/Package.lean.swift`
- `scripts/test-diode-lean.sh`

---

## Recommended next steps

1. **Clone `external/wireguard-apple`** — unblock `ProtonVPN.xcworkspace` resolution
2. **Generate `ObfuscatedConstants.swift`** from `.example` (console key, fleet UUID, StoreKit product ID)
3. **Workspace build** — `xcodebuild -workspace ProtonVPN.xcworkspace -scheme DiodeVPN-iOS -configuration Debug-Diode build`
4. **§10.6** — physical device QA checklist
5. **Release-Diode** configuration for TestFlight archives

---

*Last updated: 2026-06-25 — W5/W6, Xcode schemes, ticket refresh*
