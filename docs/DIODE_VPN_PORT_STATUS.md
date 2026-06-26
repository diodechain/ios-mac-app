# Diode VPN Port — Implementation Status

Last updated: 2026-06-24

See [DIODE_VPN_PORT_PLAN.md](./DIODE_VPN_PORT_PLAN.md) §10 for step-by-step execution.  
**Live progress:** [DIODE_VPN_IMPLEMENTATION_PROGRESS.md](./DIODE_VPN_IMPLEMENTATION_PROGRESS.md)

## Completed

### Phase 1 — Crypto & TicketV2 (`libraries/Shared/DiodeVPN/`)
- [x] `DiodeCrypto` — RLP, hex, Keccak-256, secp256k1 signing, `DeviceKeyStore` (Keychain)
- [x] `DiodeTicket` — TicketV2, TicketCommitment, network constants
- [x] `DiodeTicketTests` — `TicketV2SignatureSelfTest` (Android parity)

### Phase 2 — Network & RPC
- [x] `DiodeNetwork` — `NetworkConfig`, `VpnNode`, `DiodeNetworkApi`, geo API client
- [x] `DiodeRPC` — `DiodeRpcClient` (WebSocket JSON-RPC, `too_low`, notifications)
- [x] `DiodeConsoleFleetRegistrar` — `fleet.member.add`
- [x] `DiodeRPCTests` — 10/10 lean unit tests pass (`scripts/test-diode-lean.sh`)
- [x] §10.1 — GRDB cache (**G2-4: Option A**), `DiodeVpnNodeRepository`, app-layer `DiodeVpnNodeCache` wiring
- [ ] §10.1 — geo persist on refresh, TLS policy, integration test

### Phase 3 — Entitlement & startup
- [x] `DiodeVpnEntitlement` — DEBUG bypass + `DiodeSubscriptionStatus`
- [x] `DiodeSubscriptionService` — StoreKit 2 observer, purchase, restore
- [x] `DiodePaymentsPlanServiceV2` — Payments shim (**G2-2: Option B**)
- [x] `DiodeBackendConfig` — ObfuscatedConstants injection
- [x] `DiodeAppLifecycle` — fleet register + server list warm-up on launch
- [x] iOS/macOS `AppDelegate` + `AppDependencies+Live` wiring
- [x] §10.2 — login bypass (**G2-5: Option A**)

### Phase 4 — Connection stack (partial)
- [x] `DiodeConnectionCoordinator` — ticket → RPC → WG tunnel → `NETunnelProviderManager`
- [x] `DiodeTunnelController` — `StoredWireguardConfig` v2 keychain blob
- [x] `ConnectToVPNKey` routes to `DiodeConnectBridge` when `DIODE_BACKEND`
- [x] `StoredWireguardConfig` v2 + extension cert-refresh skip on Diode path
- [x] §10.3 — connection status via `connectionBridge` (**G2-6: Option A**)
- [ ] §10.3 — WG preflight (**G2-3: Option A**), `dio_ticket_request` refresh, auto-reconnect

### Phase 5 — UI adapter (partial)
- [x] Connect plumbing via `ConnectToVPNKey` (no UI edits)
- [x] §10.4 — `DiodeVpnNodeAdapter` + `LogicalsClient` swap (**G2-1: Option A**)
- [ ] §10.4 — `DiodeNodeSelector` logical-ID mapping; `VpnApiClient` refresh guard

## Next execution order

1. **Initialize `external/protoncore`** — unblock full builds/tests
2. **VpnApiClient shim** — stop Proton server refresh overwriting Diode list
3. **§10.3** WG preflight + session hardening on device
4. **§10.6** Device gate checklist
5. **§10.5 / §10.7 / §10.8** Cleanup (**G2-7:** WireGuard-only Diode schemes), TestFlight

## Build notes

- **Lean unit tests:** `./scripts/test-diode-lean.sh` (10/10, no protoncore)
- **Full DiodeVPN tests:** `cd libraries/Shared/DiodeVPN && swift test` (needs protoncore)
- **Full Xcode build:** requires `external/protoncore` submodule + signing
- **Enable backend:** `SWIFT_ACTIVE_COMPILATION_CONDITIONS = DIODE_BACKEND` on app + WireGuard extension

## Reference

- Plan: [DIODE_VPN_PORT_PLAN.md](./DIODE_VPN_PORT_PLAN.md)
- Progress: [DIODE_VPN_IMPLEMENTATION_PROGRESS.md](./DIODE_VPN_IMPLEMENTATION_PROGRESS.md)
- Android: `/Users/dominicletz/projects/diode/diode_vpn_android`
