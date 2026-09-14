#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
MODE="${1:-run}"
case "$MODE" in
  run|--build-only|--verify|--debug|--logs|--telemetry) ;;
  *) echo "Usage: $0 [run|--build-only|--verify|--debug|--logs|--telemetry]" >&2; exit 2 ;;
esac
if [[ "$(uname -m)" != "arm64" ]]; then
  echo "Mac Explorer requires a Mac with Apple Silicon. Run Terminal without Rosetta." >&2
  exit 1
fi
CONFIGURATION="${CONFIGURATION:-release}"
OUTPUT_BUNDLE="$ROOT_DIR/outputs/Mac Explorer.app"
STAGE_DIR="$(mktemp -d /tmp/mac-explorer-build.XXXXXX)"
trap 'rm -rf "$STAGE_DIR"' EXIT
APP_BUNDLE="$STAGE_DIR/Mac Explorer.app"
OS_MAJOR="$(sw_vers -productVersion | cut -d. -f1)"
SDK_PATH="$(xcrun --show-sdk-path)"
LOCAL_SDK="$(xcode-select -p)/SDKs/MacOSX${OS_MAJOR}.sdk"
if [[ -d "$LOCAL_SDK" ]]; then SDK_PATH="$LOCAL_SDK"; fi
SWIFT_FLAGS=(--build-system native --sdk "$SDK_PATH" --arch arm64 --configuration "$CONFIGURATION" -Xswiftc -file-prefix-map -Xswiftc "$ROOT_DIR=." -Xswiftc -debug-prefix-map -Xswiftc "$ROOT_DIR=.")
swift build "${SWIFT_FLAGS[@]}"
BUILD_DIR="$(swift build "${SWIFT_FLAGS[@]}" --show-bin-path)"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BUILD_DIR/MacExplorer" "$APP_BUNDLE/Contents/MacOS/MacExplorer"
if [[ "$CONFIGURATION" == "release" ]]; then strip -S "$APP_BUNDLE/Contents/MacOS/MacExplorer"; fi
cp "$ROOT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
if [[ ! -f "$ROOT_DIR/Resources/MacExplorer.icns" || "$ROOT_DIR/script/make_icon.swift" -nt "$ROOT_DIR/Resources/MacExplorer.icns" ]]; then
  mkdir -p "$ROOT_DIR/work/MacExplorer.iconset"
  swift -sdk "$SDK_PATH" "$ROOT_DIR/script/make_icon.swift" "$ROOT_DIR/work/MacExplorer.iconset"
  iconutil -c icns "$ROOT_DIR/work/MacExplorer.iconset" -o "$ROOT_DIR/Resources/MacExplorer.icns"
fi
cp "$ROOT_DIR/Resources/MacExplorer.icns" "$APP_BUNDLE/Contents/Resources/MacExplorer.icns"
ditto --norsrc --noextattr "$BUILD_DIR/MacExplorer_ExplorerCore.bundle" "$APP_BUNDLE/Contents/Resources/MacExplorer_ExplorerCore.bundle"
for LANGUAGE in en pt-BR es; do
  mkdir -p "$APP_BUNDLE/Contents/Resources/$LANGUAGE.lproj"
  cp "$ROOT_DIR/Resources/$LANGUAGE.lproj/InfoPlist.strings" "$APP_BUNDLE/Contents/Resources/$LANGUAGE.lproj/InfoPlist.strings"
done
chmod +x "$APP_BUNDLE/Contents/MacOS/MacExplorer"
xattr -cr "$APP_BUNDLE"
codesign --force --sign - "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"
mkdir -p "$ROOT_DIR/outputs"
ditto --norsrc --noextattr "$APP_BUNDLE" "$OUTPUT_BUNDLE"
ditto -c -k --norsrc --noextattr --keepParent "$APP_BUNDLE" "$ROOT_DIR/outputs/Mac-Explorer-Apple-Silicon.zip"
if [[ "$MODE" != "--build-only" ]]; then pkill -x MacExplorer >/dev/null 2>&1 || true; fi
case "$MODE" in
  --build-only) ;;
  run) /usr/bin/open -n "$OUTPUT_BUNDLE" ;;
  --verify) /usr/bin/open -n "$OUTPUT_BUNDLE"; sleep 1; pgrep -x MacExplorer >/dev/null ;;
  --debug) lldb -- "$OUTPUT_BUNDLE/Contents/MacOS/MacExplorer" ;;
  --logs) /usr/bin/open -n "$OUTPUT_BUNDLE"; /usr/bin/log stream --info --predicate 'process == "MacExplorer"' ;;
  --telemetry) /usr/bin/open -n "$OUTPUT_BUNDLE"; /usr/bin/log stream --info --predicate 'subsystem == "io.wellington.trilha"' ;;
esac
