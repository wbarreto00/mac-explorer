#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
OS_MAJOR="$(sw_vers -productVersion | cut -d. -f1)"
SDK_PATH="$(xcrun --show-sdk-path)"
LOCAL_SDK="$(xcode-select -p)/SDKs/MacOSX${OS_MAJOR}.sdk"
if [[ -d "$LOCAL_SDK" ]]; then SDK_PATH="$LOCAL_SDK"; fi
swift run --build-system native --sdk "$SDK_PATH" --arch arm64 MacExplorerCoreChecks
