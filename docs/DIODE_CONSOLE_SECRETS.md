# Diode Console secrets (Apple)

The Console organization API key is **not** committed. Inject it at build time into
`ObfuscatedConstants.swift` (gitignored), same pattern as Android `BuildConfig.DIODE_CONSOLE_API_KEY`.

## Resolution order

1. Environment variable `DIODE_CONSOLE_API_KEY`
2. Repo-root `local.properties` or `.diode-secrets` entry `DIODE_CONSOLE_API_KEY=…`
3. Empty string — `DiodeConsoleFleetRegistrar` skips `fleet.member.add`

Optional: `DIODE_CONSOLE_FLEET_UUID` (defaults to the public fleet UUID in `NetworkConfig`).

## Local setup

```bash
# Option A — env
export DIODE_CONSOLE_API_KEY=dck_…
./scripts/inject-diode-console-secrets.sh

# Option B — local file (gitignored)
echo 'DIODE_CONSOLE_API_KEY=dck_…' >> local.properties
./scripts/inject-diode-console-secrets.sh
```

Then build `DiodeVPN-macOS` / `Debug-Diode` in Xcode or via `xcodebuild`.

## CI

Store the key as GitHub Actions secret `DIODE_CONSOLE_API_KEY`.

Workflow [`.github/workflows/diode-macos-build.yml`](../.github/workflows/diode-macos-build.yml):

1. Fail fast if the secret is missing or does not start with `dck_`
2. Run `./scripts/inject-diode-console-secrets.sh`
3. Run `DiodeConsoleApiKeySmokeTests` (`fleet.info`)
4. Build `DiodeVPN-macOS` `Debug-Diode`

Required scopes on the CI key: **`fleet_read`** (smoke) and **`fleet_add_device`** (app `fleet.member.add`).

Note: the value still ends up in the built app binary via `ObfuscatedConstants`. For stronger protection, register fleet membership from a backend after Store entitlement checks.
