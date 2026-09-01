#!/usr/bin/env bash
# Inject Diode Console secrets into ObfuscatedConstants.swift at build time.
#
# Resolution order (Android parity):
#   1. Environment variable DIODE_CONSOLE_API_KEY
#   2. local.properties or .diode-secrets (repo root, gitignored)
#   3. Empty string — fleet registration no-ops
#
# Optional: DIODE_CONSOLE_FLEET_UUID (defaults to NetworkConfig public UUID when empty).
#
# Usage:
#   ./scripts/inject-diode-console-secrets.sh
#   DIODE_CONSOLE_API_KEY=dck_… ./scripts/inject-diode-console-secrets.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

read_local_property() {
  local key="$1"
  local file
  for file in "$ROOT/local.properties" "$ROOT/.diode-secrets"; do
    if [[ -f "$file" ]]; then
      local value
      value="$(grep -E "^[[:space:]]*${key}=" "$file" | tail -n1 | cut -d= -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      if [[ -n "${value:-}" ]]; then
        printf '%s' "$value"
        return 0
      fi
    fi
  done
  printf ''
}

API_KEY="${DIODE_CONSOLE_API_KEY:-}"
if [[ -z "$API_KEY" ]]; then
  API_KEY="$(read_local_property DIODE_CONSOLE_API_KEY)"
fi

FLEET_UUID="${DIODE_CONSOLE_FLEET_UUID:-}"
if [[ -z "$FLEET_UUID" ]]; then
  FLEET_UUID="$(read_local_property DIODE_CONSOLE_FLEET_UUID)"
fi

# Escape for Swift string literal.
swift_escape() {
  python3 -c 'import sys; print(sys.stdin.read().replace("\\", "\\\\").replace("\"", "\\\""), end="")' <<<"$1"
}

API_KEY_ESCAPED="$(swift_escape "$API_KEY")"
FLEET_UUID_ESCAPED="$(swift_escape "$FLEET_UUID")"

inject_file() {
  local example="$1"
  local target="$2"
  if [[ ! -f "$example" ]]; then
    echo "error: missing $example" >&2
    exit 1
  fi
  if [[ ! -f "$target" ]]; then
    cp "$example" "$target"
    echo "Created $target from example"
  fi

  python3 - "$target" "$API_KEY_ESCAPED" "$FLEET_UUID_ESCAPED" <<'PY'
import re
import sys
path, api_key, fleet = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path, encoding="utf-8").read()
text2, n1 = re.subn(
    r'(static let diodeConsoleApiKey:\s*String\s*=\s*")[^"]*(")',
    rf'\1{api_key}\2',
    text,
    count=1,
)
if n1 != 1:
    raise SystemExit(f"error: diodeConsoleApiKey not found in {path}")
if fleet:
    text2, n2 = re.subn(
        r'(static let diodeConsoleFleetUuid:\s*String\s*=\s*")[^"]*(")',
        rf'\1{fleet}\2',
        text2,
        count=1,
    )
    if n2 != 1:
        raise SystemExit(f"error: diodeConsoleFleetUuid not found in {path}")
open(path, "w", encoding="utf-8").write(text2)
PY
  echo "Injected Diode Console secrets into $target"
}

inject_file \
  "$ROOT/apps/macos/ProtonVPN/ObfuscatedConstants.example.swift" \
  "$ROOT/apps/macos/ProtonVPN/ObfuscatedConstants.swift"

inject_file \
  "$ROOT/apps/ios/ProtonVPN/ObfuscatedConstants.example.swift" \
  "$ROOT/apps/ios/ProtonVPN/ObfuscatedConstants.swift"

if [[ -n "$API_KEY" ]]; then
  if [[ "$API_KEY" != dck_* ]]; then
    echo "warning: DIODE_CONSOLE_API_KEY does not start with dck_" >&2
  else
    echo "DIODE_CONSOLE_API_KEY is set (${#API_KEY} chars)."
  fi
else
  echo "DIODE_CONSOLE_API_KEY is empty — fleet registration will no-op."
fi
