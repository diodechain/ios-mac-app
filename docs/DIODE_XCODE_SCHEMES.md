# DiodeVPN Xcode schemes (§9.12)

Backend builds use **`DiodeVPN-iOS`** and **`DiodeVPN-macOS`** schemes with build configuration **`Debug-Diode`**, which sets `SWIFT_ACTIVE_COMPILATION_CONDITIONS` to include **`DIODE_BACKEND`** on:

- Main app target (`ProtonVPN` / `ProtonVPN-mac`)
- WireGuard network extension target only

Proton schemes (`ProtonVPN-iOS`, `ProtonVPN-macOS`) are unchanged and do **not** define `DIODE_BACKEND`.

## xcconfig files

| File | Target |
|------|--------|
| `apps/ios/DiodeBackend-Debug.xcconfig` | iOS app |
| `apps/ios/DiodeBackend-WireGuard-Debug.xcconfig` | `WireGuardiOS Extension` |
| `apps/macos/DiodeBackend-Debug.xcconfig` | macOS app |
| `apps/macos/DiodeBackend-WireGuard-Debug.xcconfig` | `ProtonVPN WireGuard` |

Build configuration **`Debug-Diode`** duplicates **`Debug`** for all targets; app and WireGuard targets reference the xcconfig files above.

## Build commands

```bash
cd /Users/dominicletz/projects/diode/ios-mac-vpn-app

# List schemes
xcodebuild -workspace ProtonVPN.xcworkspace -list

# iOS simulator (Diode backend)
xcodebuild -workspace ProtonVPN.xcworkspace \
  -scheme DiodeVPN-iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -configuration Debug-Diode \
  build

# macOS (Diode backend)
xcodebuild -workspace ProtonVPN.xcworkspace \
  -scheme DiodeVPN-macOS \
  -configuration Debug-Diode \
  build
```

## Manual steps (if build configuration is missing)

1. Open `apps/ios/iOS.xcodeproj` → Project → Info → Configurations.
2. Duplicate **Debug** → name **`Debug-Diode`** (all targets).
3. For **ProtonVPN** target → **Debug-Diode** → set **Based on Configuration File** to `DiodeBackend-Debug.xcconfig`.
4. For **WireGuardiOS Extension** → **Debug-Diode** → set to `DiodeBackend-WireGuard-Debug.xcconfig`.
5. Repeat for `apps/macos/macOS.xcodeproj` with macOS xcconfig paths.
6. Product → Scheme → Manage Schemes → Duplicate **ProtonVPN-iOS** → **DiodeVPN-iOS**; set Run/Test/Analyze to **Debug-Diode**.
7. In **DiodeVPN-iOS** scheme → Build → disable **ProTUN-Extension-Mobile** (IKEv2) if present; keep app + WireGuard + WireGuardGoBridge.
8. Duplicate **ProtonVPN-macOS** → **DiodeVPN-macOS**; disable **ProTUN-Extension-Desktop**, **ProtonVPN Split Tunneling** (Plutonium), and **Transparent-Proxy** in Build; keep app + WireGuard + WireGuardGoBridge.

## ObfuscatedConstants

Ensure generated `ObfuscatedConstants.swift` (from `.example`) includes:

- `diodeConsoleApiKey`
- `diodeConsoleFleetUuid`
- `diodeVpnYearlyProductId` (default `"diode_vpn_yearly"` in `.example`)

## Known limitations

- **ProTUN / Plutonium / OpenVPN** targets may still build as app dependencies even when disabled in the scheme Build list; Diode connect path uses WireGuard only (§9.18).
- **Release-Diode** / TestFlight archives: duplicate **Release** → **Release-Diode** with `DIODE_BACKEND` in app + WireGuard xcconfig variants (not yet added).
- Full build requires `external/protoncore` submodule, secrets generation script, and code signing.
