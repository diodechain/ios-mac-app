#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PKG_DIR="$ROOT/libraries/Shared/DiodeVPN"
MANIFEST="$PKG_DIR/Package.swift"
LEAN="$PKG_DIR/Package.lean.swift"
BACKUP="$PKG_DIR/Package.full.swift.bak"

if [[ ! -f "$LEAN" ]]; then
  echo "Missing $LEAN" >&2
  exit 1
fi

restore() {
  if [[ -f "$BACKUP" ]]; then
    mv "$BACKUP" "$MANIFEST"
  fi
}
trap restore EXIT

cp "$MANIFEST" "$BACKUP"
cp "$LEAN" "$MANIFEST"

cd "$PKG_DIR"
swift test "$@"
