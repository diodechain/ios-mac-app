# Proton VPN iOS/macOS — Refactoring Guide

This document maps four critical areas of the codebase: where they live, how they interact, and what to watch for when refactoring. It is intended for engineers who need to change VPN connectivity, billing, authentication, or secret handling without re-discovering the architecture.

**Repository layout (relevant layers):**

| Layer | Path | Role |
|-------|------|------|
| App targets | `apps/ios/`, `apps/macos/` | Thin shells: Xcode projects, entitlements, `ObfuscatedConstants.swift`, app delegates |
| Features | `libraries/Features/` | UI flows (login, payments, settings, countries, …) |
| Shared | `libraries/Shared/` | Cross-platform logic (`Connection`, `CommonNetworking`, `VPNNetworking`, …) |
| Core | `libraries/Core/` | Network extensions, legacy bridge (`LegacyCommon`, `NEHelper`, `NEProviders`) |
| Foundations | `libraries/Foundations/` | Domain models, strings, theme, ergonomics |
| External | `external/protoncore` | Proton account, login, payments, networking SDKs |

The project README explicitly discourages adding new code to `LegacyCommon` and `NEHelper`; new work should land in Shared/Features/Foundations, with legacy code gradually migrated.

---

## 1. VPN Protocol Implementation

### 1.1 High-level architecture

VPN connectivity is in **active migration** from a legacy imperative stack to a TCA (The Composable Architecture) stack. Both paths coexist behind feature flags and bridge code.

```
User action (connect / profile / widget)
        │
        ▼
┌───────────────────────────────────────────────────────────┐
│  ConnectToVPN (LegacyCommon/NewToOldAppBridge)            │
│  Feature flag: FeatureFlagsRepository.isConnectionFeature   │
└───────────────┬─────────────────────────┬─────────────────┘
                │ enabled                 │ disabled
                ▼                         ▼
   ConnectionFeature (TCA)          VpnGateway → VpnManager
                │                         │
                ▼                         ▼
   CoreConnectionFeature            IkeProtocolFactory /
   ├─ ExtensionFeature              WireguardProtocolFactory
   ├─ CertificateAuthentication     + LocalAgent (legacy)
   └─ LocalAgentFeature
                │
                ▼
   NEPacketTunnelProvider / NEVPNProtocolIKEv2
   (Network Extension process)
```

**Primary packages:**

| Package | Path | Responsibility |
|---------|------|----------------|
| `Connection` | `libraries/Shared/Connection/` | App-side VPN logic (TCA). See `README.md` in that package. |
| `VPNNetworking` | `libraries/Shared/VPNNetworking/` | Smart Protocol selection, port probing |
| `ExtensionIPC` | `libraries/Shared/ExtensionIPC/` | IPC messages between app and extension |
| `NEProviders` | `libraries/Core/NEProviders/` | `PacketTunnelProvider` implementations |
| `NEHelper` | `libraries/Core/NEHelper/` | Extension-side certificate refresh, shared auth |
| `LegacyCommon` | `libraries/Core/LegacyCommon/` | `VpnManager`, `VpnGateway`, protocol factories, Local Agent bridge |
| `Domain` | `libraries/Foundations/Domain/` | `VpnProtocol`, `WireGuardTransport`, connection intents |

### 1.2 Supported protocols

Defined in `libraries/Foundations/Domain/Sources/Domain/Features/VpnProtocol.swift`:

| Protocol | Platforms | Notes |
|----------|-----------|-------|
| **WireGuard UDP** | iOS, macOS, tvOS | Default on iOS/tvOS |
| **WireGuard TCP** | All | |
| **WireGuard TLS** | All | |
| **IKEv2** | macOS (primary legacy default), deprecated on iOS/tvOS | Uses `NEVPNProtocolIKEv2` |

`SmartProtocol` (`VPNNetworking/SmartProtocols/SmartProtocol.swift`) probes server reachability per protocol and picks the best available port set. macOS may include IKEv2 in checks; iOS focuses on WireGuard transports.

Client config from the API (`SmartProtocolConfig`, `WireguardConfig` in Domain) gates which protocols participate in Smart selection.

### 1.3 New connection stack (TCA) — recommended target for refactors

**Entry:** `ConnectionFeature` (`Connection/Sources/Connection/ConnectionFeature.swift`)

Responsibilities:
- **Connection preparation** — protocol/port selection while disconnected (pings endpoints)
- **User-facing state** — maps internal states to UI-friendly `ConnectionState`
- **Authorization** — tier checks via `connectionIntentResolver`

**Core orchestration:** `CoreConnectionFeature` (`Connection/Sources/Connection/CoreConnectionFeature.swift`)

Coordinates three leaf reducers:

1. **`ExtensionFeature`** (`ExtensionManager/Extensions+Reducer/ExtensionManagerFeature.swift`)
   - Starts/stops `NETunnelProviderManager` / tunnel
   - Observes `NEVPNStatus`
   - IPC via `tunnelManager.sendMessage`
   - Configures tunnel via `WireguardConfigurator`

2. **`CertificateAuthenticationFeature`** (`CertificateAuthentication/CertificateAuthenticationFeature.swift`)
   - Loads/regenerates Ed25519 keys
   - Fetches/refreshes X.509 client certificates from Proton API
   - Pushes session selector to extension for cert refresh in NE process

3. **`LocalAgentFeature`** (`LocalAgent/LocalAgentFeature.swift`)
   - Go-based Local Agent client (`LocalAgent/GoLibs/`)
   - Applies NetShield, NAT-PMP, split tunneling, 2FA notices, etc.
   - Connects only after tunnel is up and certificate is loaded

**Typical connect sequence:**

1. `ConnectionFeature` receives `ConnectionPreparationIntent`, runs Smart Protocol / port selection
2. `CoreConnectionFeature.connect(ServerConnectionIntent)` starts tunnel configuration
3. `WireguardConfigurator` builds `NETunnelProviderProtocol`, stores encrypted config in tunnel keychain
4. `ExtensionFeature` calls `startTunnel`; extension reports connected logical server via IPC
5. `CertificateAuthenticationFeature` loads/refreshes cert; may fork session for extension API
6. `LocalAgentFeature` connects to server-side agent with `VPNAuthenticationData`
7. Parent features emit `ConnectionState` / errors to UI

**Bridge from legacy UI:** `libraries/Core/LegacyCommon/Sources/LegacyCommon/NewToOldAppBridge/ConnectToVPN.swift` pushes intents into `connectionBridge` when the feature flag is on.

### 1.4 Legacy connection stack

Still used when `isConnectionFeatureEnabled` is false, and partially for macOS IKEv2 / Plutonium paths.

| Component | Path | Role |
|-----------|------|------|
| `VpnGateway` | `LegacyCommon/Core/VpnGateway.swift` | High-level connect/disconnect, profile handling |
| `VpnManager` | `LegacyCommon/Core/VpnManager.swift` | `NEVPNManager` lifecycle, on-demand rules |
| `IkeProtocolFactory` | `LegacyCommon/Core/VpnProtocolFactory/IkeProtocolFactory.swift` | Builds `NEVPNProtocolIKEv2` (cert auth on macOS) |
| `WireguardProtocolFactory` | `LegacyCommon/Core/VpnProtocolFactory/WireguardProtocolFactory.swift` | Builds `NETunnelProviderProtocol` |
| `VpnCredentialsConfigurator` | `LegacyCommon/Core/VpnCredentials/` | IKEv2 username/password keychain refs |

Platform-specific credential configurators also exist under `libraries/Features/ios_app/.../VPN/`.

### 1.5 Network Extension (packet tunnel)

| Target | Path | Notes |
|--------|------|-------|
| WireGuard | `libraries/Core/NEProviders/Sources/WireGuardExtension/PacketTunnelProvider.swift` | `WireGuardPacketTunnelProvider` + WireGuardKit adapter |
| ProTUN | `libraries/Core/NEProviders/Sources/ProTUNExtension/` | Feature-flagged alternative tunnel |
| tvOS | Uses shared `WireGuardExtension` package (per Connection README) |
| iOS/macOS app targets | Still host some `NEPacketTunnelProvider` subclasses; migration to `NEProviders` ongoing |

Extension responsibilities:
- Read tunnel config from keychain (`tunnelProviderProtocol.keychainConfigData()`)
- Start WireGuard adapter with server keys/IPs
- Certificate refresh via `ExtensionCertificateRefreshManager` + `ExtensionAPIService` (NEHelper)
- IPC: respond to `WireguardProviderRequest` messages from the app

### 1.6 Certificate-based VPN authentication

Distinct from **account login** (OAuth/session tokens). VPN connections use **Ed25519 key pairs + short-lived X.509 certificates**.

| Layer | Path |
|-------|------|
| App (TCA) | `CertificateAuthenticationFeature`, `CertificateRefreshClient` |
| App (legacy) | `CommonNetworking/VpnAuthentication/`, platform `+iOS` / `+MacOS` |
| Storage | `VpnAuthenticationStorage`, `TunnelKeychain` (`ConnectionShared/`) |
| Extension | `NEHelper/ExtensionCertificateRefreshManager`, `VPNShared/Authentication/` |
| API | `CommonNetworking/ApiServices/Requests/VPN/CertificateRequest.swift` |

`AppSessionManager.refreshVpnAuthCertificate()` triggers refresh on login when cert auth is the active authentication type.

### 1.7 Local Agent

Go library wrapper providing server-side feature enforcement (NetShield stats, jailing, 2FA, server change, etc.).

- TCA: `LocalAgentFeature` + `LocalAgentClient+Implementation.swift`
- Legacy: `LegacyCommon/Management/LocalAgent/LocalAgent.swift`, `VpnManager+LocalAgent.swift`

Local Agent connects **after** the tunnel is established and certificate auth succeeds.

### 1.8 Refactoring notes (VPN)

| Concern | Guidance |
|---------|----------|
| **Dual stacks** | Any connect/disconnect change may need updates in both `ConnectionFeature` and `VpnGateway` until the flag is removed. Search for `isConnectionFeatureEnabled` and `connectionBridge`. |
| **Protocol addition** | Extend `VpnProtocol` (Domain), Smart Protocol checkers (`VPNNetworking`), both protocol factories (LegacyCommon), `WireguardConfigurator`, and server `ProtocolSupport` filters. |
| **Extension IPC** | Message contracts live in `ExtensionIPC`; changing them requires app + extension + tests (`ExtensionManagerTests`). |
| **Key material** | Tunnel config in tunnel keychain; VPN keys/certs in `VpnAuthenticationStorage`. Logout clears via `CoreConnectionFeature.handleLogout` and `AppSessionManager.logOut`. |
| **Tests** | `Connection` package has extensive TCA tests; `ConnectionTestSupport` provides `ConnectionEnvironment`. Legacy tests under `LegacyCommonTests`. |
| **macOS IKEv2 + Plutonium** | Special conflict handling in `PlutoniumIKEv2ConflictIntercept`, `VpnManager` includeAllNetworks checks. |

---

## 2. Billing Backend Implementation

### 2.1 Overview

Billing is **not implemented locally** — the app integrates **Proton's account/payments backend** via:

1. **StoreKit 2 / In-App Purchase** (iOS, tvOS) through `ProtonCorePaymentsV2`
2. **Web checkout** (account portal) via session forking + `WKWebView`
3. **Remote plan/subscription API** via `RemoteManager` (ProtonCore)

There is no standalone "billing server" in this repo; backend logic lives in Proton Core and Proton account services.

### 2.2 Package structure

| Module | Path | Role |
|--------|------|------|
| `PaymentsShared` | `libraries/Features/Payments/Sources/PaymentsShared/` | Core service, models, dependency keys |
| `Payments-iOS` | `.../Payments-iOS/` | Upsell UI (legacy + V2 plan pickers) |
| `Payments-macOS` | `.../Payments-macOS/` | macOS upsell views |
| `ProtonCorePaymentsV2` | `external/protoncore` | IAP, plan composition, transaction observer |
| `ProtonCorePaymentsUIV2` | `external/protoncore` (iOS only) | Native payments UI sheet |

**Central service:** `CorePaymentsPlanServiceV2` in `PaymentsShared/PlanServiceV2Dependency.swift`

Implements `PaymentsPlanServiceV2`:
- `fetchIAPStatus()` — asks backend whether IAP is enabled for this user/region
- `getAvailablePlans()` — fetches `ComposedPlan` list (StoreKit products + Proton plan metadata)
- `purchase(_:)` — StoreKit purchase + backend subscription creation
- `recoverTransaction()` / `restorePurchase()` — receipt recovery
- `presentSubscriptionManagement()` — opens ProtonCore `PaymentsV2` modal (iOS)
- `pushCantUpgradeAlert()` — fallback to web upgrade URL

Registered as `@Dependency(\.paymentsPlanServiceV2)`.

### 2.3 Purchase flow (IAP)

```
UI (Upsell / Settings / Onboarding)
        │
        ▼
paymentsPlanServiceV2.purchase(Product)  or  presentSubscriptionManagement()
        │
        ▼
ProtonPlansManager / PaymentsV2 (ProtonCore)
        │
        ├── StoreKit 2 transaction
        ├── TransactionsObserver (background receipt/token handling)
        └── RemoteManager → Proton API (create subscription, validate receipt)
        │
        ▼
TransactionHandlerState events → CorePaymentsPlanServiceV2.handleTransactionProgress
        │
        ▼
AppEvent.userDidCompletePurchase → AppSessionManager refreshes user/subscription state
```

**Transaction observer lifecycle:**
- Started in `CorePaymentsPlanServiceV2.init()` via `createTransactionSubscription()`
- Stopped on logout via `planServiceV2.clear()` (called from `AppSessionManager`)
- Lazily restarted before next purchase via `ensureTransactionsObserverIsActive()`

### 2.4 Web billing flow

Used when IAP is disabled, on TestFlight (unless `allowSandboxPurchases` flag), macOS upsell, or explicit "manage subscription" flows.

**Session forking:** `SessionService` (`CommonNetworking/Dependencies/SessionService.swift`)

1. `POST /auth/v4/sessions/forks` with `ChildClientID` (e.g. `web-account-lite`)
2. Receives `selector` token
3. Builds URL: `https://account.proton.me/lite#selector=<selector>&action=subscribe-account&...`

**Web view:** `PaymentsWebViewController` (iOS) loads forked URL with DoH cookie/header interception for captive portal / alternative routing.

Plan session modes: `.upgrade`, `.manageSubscription`, `.promo2yPlan` (hardcoded promo query params).

### 2.5 Platform differences

| Platform | Primary billing path | Key files |
|----------|---------------------|-----------|
| **iOS** | StoreKit 2 + `PaymentsV2` UI + web fallback | `Payments-iOS/`, `ios_app/Scenes/Payments/`, `OneClickPaymentV2.swift` |
| **macOS** | Web upsell (lighter IAP integration) | `Payments-macOS/`, `macos/ProtonVPN/Scenes/Upsell & Onboarding/` |
| **tvOS** | StoreKit via thinner wrapper | `tvos_app/Features/Upsell/PaymentsClient.swift`, `PlanService.swift` |

### 2.6 Integration with login/session

`AppSessionManager.retrievePropertiesAndLogIn()` (iOS implementation):
- Calls `planServiceV2.fetchIAPStatus()` in parallel with `vpnApiClient.vpnProperties()`
- Starts `startListeningToPaymentTransactionEvents()` after successful login
- On logout: `planServiceV2.clear()` stops transaction observer

User tier/plan comes from `VpnCredentials` (via `vpnKeychain`) returned by VPN properties API — billing state and VPN entitlements are coupled at the API layer.

### 2.7 Refactoring notes (billing)

| Concern | Guidance |
|---------|----------|
| **ProtonCore boundary** | Most IAP logic is in `external/protoncore`. App code should stay thin; extend `PaymentsPlanServiceV2` rather than duplicating StoreKit calls. |
| **Logout/login** | Always pair observer lifecycle with session lifecycle (`clear()` on logout). |
| **TestFlight** | `arePaymentsAllowed` checks `Bundle.isTestflight` + feature flag. |
| **Web vs IAP** | `IAPSupportStatusV2` from backend drives which path is shown; don't hardcode platform alone. |
| **Telemetry** | Upsell/conversion events in `libraries/Shared/Telemetry/` (`TelemetryUpsellReporter`, `TelemetryConversionReporter`). |
| **macOS gap** | `restorePurchase()` throws `unsupportedPlatform` on non-iOS — intentional. |

---

## 3. Login and User Account Implementation

### 3.1 Overview

Account authentication uses **ProtonCore Login/Authentication** against Proton's auth API (`/auth/v4/*`). The VPN app stores resulting credentials in the **Keychain** and hydrates VPN-specific state (servers, plan, certificates) after login.

Two session modes exist:
- **Authenticated** — full Proton account (`AuthKeychain`)
- **Unauthenticated / guest** — limited session (`UnauthKeychain`) for previewing servers without login

### 3.2 UI entry points

| Platform | Primary implementation | Path |
|----------|------------------------|------|
| **iOS** | `CoreLoginService` | `libraries/Features/ios_app/.../LoginAndSignup/Services/LoginService.swift` |
| **macOS** | `LoginViewModel` | `apps/macos/ProtonVPN/Scenes/Login/ViewModels/LoginViewModel.swift` |
| **tvOS** | `SignInFeature` (TCA) | `libraries/Features/tvos_app/.../Sign In/` |

**iOS flow:**
- `LoginAndSignup` from ProtonCore (`ProtonCoreLogin`, `ProtonCoreLoginUI`)
- `performBeforeFlow` → `finishFlow()` fetches user settings + calls `appSessionManager.finishLogin(authCredentials:)`
- Supports login, signup, SSO (`ssoCallbackScheme: "protonvpn"`), credentialless accounts, 2FA (handled by ProtonCore)

**macOS flow:**
- Lower-level `Login` service from ProtonCore (not the full `LoginAndSignup` UI bundle)
- Custom AppKit UI in `LoginViewModel` with 2FA state machine

### 3.3 Session orchestration — `AppSessionManager`

**Protocol:** defined in `ios_app/.../AppSessionManager.swift` (macOS has parallel `AppSessionManagerImplementation` in app target).

**Implementation:** `AppSessionManagerImplementation` extends `AppSessionRefresherImplementation`.

Key methods:

| Method | Purpose |
|--------|---------|
| `attemptSilentLogIn()` | Keychain credentials → fetch settings → `retrievePropertiesAndLogIn()` |
| `finishLogin(authCredentials:)` | Store creds, clear unauth/vpn keychains, full property fetch |
| `loadDataWithoutFetching()` | Fast path: servers in DB + keychain present → `.established` |
| `loadDataWithoutLogin()` | Guest mode: VPN properties without auth |
| `logOut(force:reason:)` | Clears keychains, stops VPN, clears payments observer |
| `refreshVpnAuthCertificate()` | Post-login cert refresh for cert-based VPN auth |

**Login side effects** (`retrievePropertiesAndLogIn`):
- `vpnApiClient.vpnProperties()` → servers, location, plan, client config, streaming, feature flags
- `vpnKeychain.storeAndDetectDowngrade()` — detects plan downgrades
- `serverManager.update()` — populates `Persistence` server DB
- `propertiesManager` — caches wireguard config, smart protocol, user info
- `planServiceV2.fetchIAPStatus()`
- `resolveActiveSession()` — handles multi-user VPN profile conflicts
- Announcements, review prompts, telemetry

### 3.4 Credential storage

| Store | Type | Path | Contents |
|-------|------|------|----------|
| `AuthKeychain` | `AuthCredentials` | `NEHelper/VPNShared/Authentication/AuthKeychain.swift` | Access/refresh tokens, session UID, user ID, scopes |
| `UnauthKeychain` | `AuthCredential` (ProtonCore) | `NEHelper/VPNAppCore/Authentication/UnauthKeychain.swift` | Guest session |
| `VpnKeychain` | `VpnCredentials` | `NEHelper/VPNShared/Authentication/VPNKeychain/VpnKeychain.swift` | Plan, tier, OpenVPN password (legacy), server cert, WG config ref |
| `VpnAuthenticationStorage` | Keys + X.509 cert | `NEHelper/.../VpnAuthenticationStorage.swift` | VPN connection certificates |
| `TunnelKeychain` | Encrypted tunnel config | `Connection/ConnectionShared/TunnelKeychainImplementation.swift` | Per-connection WireGuard/ProTUN config |

`AuthCredentials` model: `NEHelper/VPNShared/Authentication/AuthCredentials.swift`

Context-aware storage: extension copies stored under `AppContext.wireGuardExtension` key suffix.

### 3.5 Networking layer

**`CoreNetworking`** (`CommonNetworking/Networking/Networking.swift`):
- Wraps `PMAPIService` (ProtonCore)
- Implements `AuthDelegate` — token refresh, session invalidation
- Initializes with `authKeychain` or `unauthKeychain` session UID
- DoH configuration for API host resolution
- TrustKit SSL pinning (configurable)

**Session forking** (`SessionService`):
- Used for: web billing, extension API access, debug flows
- `ForkSessionRequest` → `POST /auth/v4/sessions/forks`

**`NetworkingDelegate`** (per platform):
- iOS: `iOSNetworkingDelegate.swift`
- macOS: app target equivalent
- tvOS: `TVOSNetworkingDelegate.swift`
- Handles force upgrade, human verification challenges

### 3.6 Credentialless accounts

`CredentiallessHelper` (`VPNAppCore/Authentication/CredentiallessHelper.swift`) detects accounts without full credentials. Affects:
- Login flow branching in `LoginService.processLoginResult`
- Payments UI (`hideCurrentPlan` in `presentSubscriptionManagement`)
- Onboarding paths

### 3.7 Widget / extension login

`WidgetIntents/Intents/LoginIntent.swift` — shortcut to trigger login flow from widgets.

Extensions receive forked session selectors via `SessionService.getExtensionSessionSelector(extensionContext:)`.

### 3.8 Refactoring notes (login)

| Concern | Guidance |
|---------|----------|
| **ProtonCore coupling** | Login UI and token refresh are mostly ProtonCore. VPN-specific post-login work belongs in `AppSessionManager.finishLogin` / `retrievePropertiesAndLogIn`. |
| **Keychain clears** | Login must clear `unauthKeychain` + `vpnKeychain`; logout must clear all stores + `planServiceV2.clear()` + connection state. |
| **Session UID** | After login data available, `networking.apiService.setSessionUID(uid:)` must be called (see `LoginService.processLoginResult`). |
| **Dual implementations** | iOS uses `LoginService`; macOS uses `LoginViewModel` — behavior should stay aligned for silent login, 2FA, error mapping. |
| **Guest mode** | `loadDataWithoutLogin` is a separate path; don't assume `authKeychain` is populated. |
| **Legacy bridge** | `AuthCredentials+Legacy.swift`, `AuthCredentials+Login.swift` adapt ProtonCore types. |

---

## 4. Secret Management

### 4.1 Categories of secrets

| Category | Storage | Examples |
|----------|---------|----------|
| **Build-time obfuscated constants** | `ObfuscatedConstants.swift` (generated) | API hosts, Sentry DSNs, IAP product IDs, staging "black" hosts, test 2FA keys |
| **Debug/runtime overrides** | `Info.plist` args, `PropertiesManager`, Environment Selector | `ATLAS_SECRET`, `DYNAMIC_DOMAIN`, custom API endpoint |
| **User/session secrets** | Keychain | OAuth tokens, VPN private keys, certificates |
| **Extension-shared secrets** | App Group + Keychain | Tunnel config, extension auth copies |

### 4.2 ObfuscatedConstants (build secrets)

**Not in this repository.** Values live in a separate credentials repo, synced via:

```bash
./Integration/Scripts/credentials.sh setup -p <path> -r <remote>
./Integration/Scripts/credentials.sh checkout
```

CI/bootstrap: `Integration/Scripts/bootstrap.sh`, `pipeline_setup.sh`

**Per-target files** (generated at build time from example templates):

| Target | Example template |
|--------|------------------|
| iOS | `apps/ios/ProtonVPN/ObfuscatedConstants.example.swift` |
| macOS | `apps/macos/ProtonVPN/ObfuscatedConstants.example.swift` |
| tvOS | `libraries/Features/tvos_app/.../ObfuscatedConstants.example.swift` |

**iOS/macOS constants** (from example):
- `sentryDsnmacOS`, `sentryDsniOS`
- `apiHost`, `humanVerificationV3Host`
- `vpnIAPIdentifiers`, `planNames`, `specialCoupons`
- `internalUrls`
- **Black/staging environment hosts:** `blackDefaultHost`, `blackApiHost`, `blackAccountHost`, `blackCaptchaHost`, …
- **UI test keys:** `twoFASecurityKey`, `twoFAandTwoPassSecurityKey`

**tvOS constants** (smaller set): `apiHost`, `atlasSecret`, `humanVerificationV3Host`, `sentryDsntvOS`

Variables with the same name across targets can be overwritten uniformly via environment variables during the Generate Obfuscated Constants build phase (see comments in example files).

### 4.3 How constants are consumed

| Constant | Consumer | Purpose |
|----------|----------|---------|
| `apiHost` | `DoHVPN` init in `AppDependencies+Live.swift` | DoH custom API host header |
| `humanVerificationV3Host` | `DoHVPN` | HV3 endpoint when not on production |
| `sentryDsn*` | `AppDelegateService` / `ProtonVPNApp` | Crash reporting |
| `vpnIAPIdentifiers` | Payments / StoreKit product matching | IAP product IDs |
| `planNames` | Plan validation | |
| `black*Host` | Staging/black environment switching | Debug/staging builds |

**Wiring (iOS/macOS):** `libraries/Features/ios_app/.../AppDependencies+Live.swift`

```swift
DoHVPN(
    apiHost: ObfuscatedConstants.apiHost,
    verifyHost: ObfuscatedConstants.humanVerificationV3Host,
    customHost: Bundle.dynamicDomain ?? propertiesManager.apiEndpoint,
    atlasSecret: Bundle.atlasSecret ?? propertiesManager.atlasSecret,
    ...
)
```

### 4.4 Debug-only runtime secrets

`libraries/Foundations/Ergonomics/.../Bundle+main.swift`:

| Key | Source (DEBUG only) | Purpose |
|-----|---------------------|---------|
| `ATLAS_SECRET` | Process args or Info.plist | `x-atlas-secret` header for staging API (Atlas) |
| `DYNAMIC_DOMAIN` | Process args or Info.plist | Override API base URL |

In **RELEASE**, both return `nil` — production relies on obfuscated constants and live URLs only.

`CoreNetworking` adds `x-atlas-secret` header when `doh.isAtlasRequest` and secret is set.

**Environment Selector** (debug builds): `Settings/.../EnvironmentSelectorFeature.swift`
- UI to set custom API endpoint, fetch/generate atlas secret, override feature flags
- Persists via `PropertiesManager` / `@Shared` alternative routing

### 4.5 Keychain secret storage

| Keychain | Service name | Library |
|----------|--------------|---------|
| App auth | `ProtonVPN` (`KeychainConstants.appKeychain`) | KeychainAccess via `KeychainActor` |
| Extension | Same service, context-specific keys | `AuthKeychain`, `VpnKeychain` |
| Tunnel | Per-tunnel encrypted blob | `TunnelKeychainImplementation` |

**Debug tooling:** `KeychainDebugFeature` / `KeychainDebugView` in Settings (inspect stored items).

**Storage keys:** `NEHelper/VPNShared/Constants/StorageKeys.swift` (UserDefaults for non-sensitive prefs like atlas secret in DEBUG extension).

### 4.6 Atlas secret in Network Extension

`PacketTunnelProvider` reads `StorageKeys.atlasSecret` from shared storage (DEBUG) for `ExtensionAPIService` certificate refresh against staging.

### 4.7 Refactoring notes (secrets)

| Concern | Guidance |
|---------|----------|
| **Never commit real secrets** | Only `.example.swift` templates are in git. Real `ObfuscatedConstants.swift` is generated/ignored. |
| **Adding a new constant** | Add to all platform example files + push to secrets repo + document in credentials workflow. |
| **Staging vs prod** | `DoHVPN.defaultHost` validates custom hosts via `customHostValidator` in release. |
| **Token vs build secret** | User tokens → Keychain only. API environment keys → ObfuscatedConstants or debug overrides. |
| **Extension access** | Extensions cannot read app-only keychain items; use forked sessions or app-group shared storage. |
| **SwiftLint** | ObfuscatedConstants paths may be excluded (see `.swiftlint.yml`). |

---

## 5. Cross-cutting dependency map

```
                    ┌─────────────────┐
                    │  ProtonCore     │
                    │  (external)     │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
  ProtonCoreLogin    ProtonCorePaymentsV2   PMAPIService
         │                   │                   │
         ▼                   ▼                   ▼
   LoginService         PaymentsShared      CoreNetworking
         │                   │                   │
         └─────────┬─────────┴─────────┬─────────┘
                   ▼                   ▼
            AppSessionManager    SessionService
                   │                   │
         ┌─────────┴─────────┐         │
         ▼                   ▼         ▼
   AuthKeychain/VpnKeychain  ConnectionFeature / VpnGateway
         │                   │
         ▼                   ▼
   CertificateAuth         PacketTunnelProvider
```

**Shared dependencies (swift-dependencies):** Most services register via `DependencyKey` — search `@Dependency(\.` to find injection points before refactoring.

---

## 6. Suggested refactoring order

If tackling these areas independently:

1. **Secrets** — Lowest coupling. Centralize constant access behind a small `AppSecrets` protocol; keep ObfuscatedConstants generation as-is.
2. **Login** — Extract `AppSessionManager` post-login pipeline into explicit phases (credentials → VPN properties → servers → payments → connection).
3. **Billing** — Isolate `PaymentsPlanServiceV2`; ensure single observer lifecycle owner.
4. **VPN** — Migrate remaining `VpnGateway` callers to `ConnectionFeature`; delete legacy path only when feature flag is removed.

---

## 7. Key file index

### VPN
- `libraries/Shared/Connection/Sources/Connection/ConnectionFeature.swift`
- `libraries/Shared/Connection/Sources/Connection/CoreConnectionFeature.swift`
- `libraries/Shared/Connection/Sources/ExtensionManager/Dependencies/WireguardConfigurator.swift`
- `libraries/Core/NEProviders/Sources/WireGuardExtension/PacketTunnelProvider.swift`
- `libraries/Core/LegacyCommon/Sources/LegacyCommon/Core/VpnGateway.swift`
- `libraries/Core/LegacyCommon/Sources/LegacyCommon/Core/VpnManager.swift`
- `libraries/Foundations/Domain/Sources/Domain/Features/VpnProtocol.swift`
- `libraries/Shared/VPNNetworking/Sources/VPNNetworking/SmartProtocols/SmartProtocol.swift`

### Billing
- `libraries/Features/Payments/Sources/PaymentsShared/PlanServiceV2Dependency.swift`
- `libraries/Shared/CommonNetworking/Sources/CommonNetworking/Dependencies/SessionService.swift`
- `libraries/Features/ios_app/Sources/ios_app/Scenes/Payments/PaymentsWebViewController.swift`
- `libraries/Features/tvos_app/Sources/tvos_app/Features/Upsell/PaymentsClient.swift`

### Login / account
- `libraries/Features/ios_app/Sources/ios_app/Scenes/LoginAndSignup/Services/LoginService.swift`
- `libraries/Features/ios_app/Sources/ios_app/Scenes/Common/Services/AppSessionManager.swift`
- `apps/macos/ProtonVPN/Scenes/Login/ViewModels/LoginViewModel.swift`
- `libraries/Shared/CommonNetworking/Sources/CommonNetworking/Networking/Networking.swift`
- `libraries/Core/NEHelper/Sources/VPNShared/Authentication/AuthKeychain.swift`
- `libraries/Core/NEHelper/Sources/VPNShared/Authentication/AuthCredentials.swift`

### Secrets
- `apps/ios/ProtonVPN/ObfuscatedConstants.example.swift`
- `Integration/Scripts/credentials.sh`
- `libraries/Features/ios_app/Sources/ios_app/Scenes/Common/Supporting Files/AppDependencies+Live.swift`
- `libraries/Foundations/Ergonomics/Sources/Ergonomics/Extension/Bundle+main.swift`
- `libraries/Features/Settings/Sources/SettingsShared/Features/AppDebugConfig/EnvironmentSelectorFeature.swift`

---

*Generated from codebase review of the Proton VPN iOS/macOS repository. For build setup of secrets, see root `README.md`.*
