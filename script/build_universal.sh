#!/bin/bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
export PATH="$ROOT_DIR/.build-tools/bin:$PATH"
BUILD_ARCH=arm64 BUILD_DATA=DerivedData ./script/build_and_run.sh --build-only
BUILD_ARCH=x86_64 BUILD_DATA=DerivedData-Intel ./script/build_and_run.sh --build-only
mkdir -p DerivedData/Universal
python3 script/merge_universal.py \
    DerivedData/Build/Products/Debug/Unsething.app \
    DerivedData-Intel/Build/Products/Debug/Unsething.app \
    DerivedData/Universal/Unsething.app
codesign --force --deep --sign - DerivedData/Universal/Unsething.app
codesign --verify --deep --strict DerivedData/Universal/Unsething.app
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" DerivedData/Universal/Unsething.app/Contents/Info.plist)
APP=DerivedData/Universal/Unsething.app \
DMG="DerivedData/Universal/Unsething-${VERSION}-Universal-test.dmg" \
WORK_DIR=DerivedData/DMG-Universal \
VOLUME_NAME="Unsething ${VERSION} Universal" \
    ./scripts/create_distribution_dmg.sh
