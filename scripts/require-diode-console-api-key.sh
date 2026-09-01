#!/usr/bin/env bash
# Fail when DIODE_CONSOLE_API_KEY is missing or malformed (Android CI parity).
set -euo pipefail

if [[ -z "${DIODE_CONSOLE_API_KEY:-}" ]]; then
  echo "::error title=Missing DIODE_CONSOLE_API_KEY::GitHub Actions secret DIODE_CONSOLE_API_KEY is not set or empty."
  echo "Add an organization API key (dck_…) under Settings → Secrets and variables → Actions."
  echo "Required scopes: fleet_read (CI smoke via fleet.info) and fleet_add_device (app fleet.member.add)."
  echo "See docs/DIODE_CONSOLE_SECRETS.md."
  exit 1
fi

if [[ ! "$DIODE_CONSOLE_API_KEY" =~ ^dck_ ]]; then
  echo "::error title=Invalid DIODE_CONSOLE_API_KEY::Secret does not look like a Diode Console org key (expected prefix dck_)."
  exit 1
fi

echo "DIODE_CONSOLE_API_KEY secret is present."
