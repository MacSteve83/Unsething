#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
export PATH="$ROOT_DIR/.build-tools/bin:/opt/homebrew/bin:/opt/local/bin:$PATH"
MODE="${1:-run}"
if [[ "$MODE" == --universal ]]; then
    exec "$ROOT_DIR/script/build_universal.sh"
fi
BUILD_ARCH="${BUILD_ARCH:-$(uname -m)}"
BUILD_DATA="${BUILD_DATA:-DerivedData}"
case "$MODE" in run|--verify|--build-only) ;; *) echo "Usage: $0 [--verify|--build-only]" >&2; exit 2 ;; esac
if [[ "$MODE" != --build-only ]] && pgrep -x Unsething >/dev/null; then
    osascript -e 'tell application "Unsething" to quit'
    for ((i=0; i<30; i++)); do
        pgrep -x Unsething >/dev/null || break
        sleep 1
    done
    if pgrep -x Unsething >/dev/null; then
        echo "Unsething is still running. Finish any pending dialog before retrying." >&2
        exit 1
    fi
fi
python3 "$ROOT_DIR/script/fetch_dependencies.py"
BUILD_STARTED_AT=$SECONDS
echo "Build started: $(date '+%Y-%m-%d %H:%M:%S %Z')"
xcodebuild -project Unsething.xcodeproj -scheme Unsething -configuration Debug \
    -destination "platform=macOS,arch=$BUILD_ARCH" -derivedDataPath "$BUILD_DATA" \
    ARCHS="$BUILD_ARCH" ONLY_ACTIVE_ARCH=YES \
    build SKIP_SUBMODULES=1 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY= DEVELOPMENT_TEAM=
echo "Build completed in $((SECONDS - BUILD_STARTED_AT)) seconds."
APP="$ROOT_DIR/$BUILD_DATA/Build/Products/Debug/Unsething.app"
codesign --force --deep --sign - "$APP"
if [[ "$MODE" != --build-only ]]; then
    open -n "$APP"
    if [[ "$MODE" == --verify ]]; then
        sleep 3
        pgrep -x Unsething
    fi
fi
