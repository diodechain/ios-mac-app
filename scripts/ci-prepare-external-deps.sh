#!/usr/bin/env bash
# Prepare gitignored / private-path external deps for CI (and local clean checkouts).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

clone_if_missing() {
  local path="$1"
  local url="$2"
  local ref="$3"
  if [[ -f "$path/Package.swift" ]]; then
    echo "OK: $path already present"
    return 0
  fi
  echo "Cloning $url ($ref) → $path"
  rm -rf "$path"
  mkdir -p "$(dirname "$path")"
  git clone --depth 1 --branch "$ref" "$url" "$path"
}

# Proton GitLab-relative submodule URLs are not reachable from GitHub Actions.
clone_if_missing \
  external/wireguard-apple \
  https://github.com/diodechain/wireguard-apple.git \
  release/ios

clone_if_missing \
  external/apple-fusion \
  https://github.com/ProtonMail/apple-fusion.git \
  2.1.2

# protunFFI is gitignored; macOS Diode builds do not link it, but SPM still resolves the binary target.
FFI_ROOT="libraries/Core/NEProviders/Frameworks/protunFFI.xcframework"
if [[ ! -f "$FFI_ROOT/Info.plist" ]]; then
  echo "Creating stub protunFFI.xcframework for package resolution"
  mkdir -p \
    "$FFI_ROOT/ios-arm64/Headers" \
    "$FFI_ROOT/ios-arm64-simulator/Headers"

  cat >"$FFI_ROOT/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>AvailableLibraries</key>
	<array>
		<dict>
			<key>BinaryPath</key>
			<string>libprotun-ios.a</string>
			<key>HeadersPath</key>
			<string>Headers</string>
			<key>LibraryIdentifier</key>
			<string>ios-arm64</string>
			<key>LibraryPath</key>
			<string>libprotun-ios.a</string>
			<key>SupportedArchitectures</key>
			<array>
				<string>arm64</string>
			</array>
			<key>SupportedPlatform</key>
			<string>ios</string>
		</dict>
		<dict>
			<key>BinaryPath</key>
			<string>libprotun-sim.a</string>
			<key>HeadersPath</key>
			<string>Headers</string>
			<key>LibraryIdentifier</key>
			<string>ios-arm64-simulator</string>
			<key>LibraryPath</key>
			<string>libprotun-sim.a</string>
			<key>SupportedArchitectures</key>
			<array>
				<string>arm64</string>
			</array>
			<key>SupportedPlatform</key>
			<string>ios</string>
			<key>SupportedPlatformVariant</key>
			<string>simulator</string>
		</dict>
	</array>
	<key>CFBundlePackageType</key>
	<string>XFWK</string>
	<key>XCFrameworkFormatVersion</key>
	<string>1.0</string>
</dict>
</plist>
PLIST

  printf '%s\n' '// Stub header for CI package resolution.' >"$FFI_ROOT/ios-arm64/Headers/protunFFI.h"
  printf '%s\n' '// Stub header for CI package resolution.' >"$FFI_ROOT/ios-arm64-simulator/Headers/protunFFI.h"

  # Empty static archives satisfy SPM binaryTarget path validation.
  TMPDIR_AR="$(mktemp -d)"
  echo 'int protun_ffi_stub = 0;' >"$TMPDIR_AR/stub.c"
  cc -c "$TMPDIR_AR/stub.c" -o "$TMPDIR_AR/stub.o"
  ar rcs "$FFI_ROOT/ios-arm64/libprotun-ios.a" "$TMPDIR_AR/stub.o"
  ar rcs "$FFI_ROOT/ios-arm64-simulator/libprotun-sim.a" "$TMPDIR_AR/stub.o"
  rm -rf "$TMPDIR_AR"
else
  echo "OK: protunFFI.xcframework present"
fi

echo "External deps ready."
