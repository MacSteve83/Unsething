#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
BUILD_DATA="${BUILD_DATA:-DerivedData}"
SMOKE_ROOT="$PWD/DerivedData/LibrarySmoke"
SMOKE_APP="$SMOKE_ROOT/UnsethingLibraryTest.app"
if pgrep -f "$SMOKE_APP/Contents/MacOS/Unsething" >/dev/null; then
    echo 'Close the running Unsething Library Test before restaging.' >&2
    exit 1
fi
mkdir -p "$SMOKE_ROOT/database"
SOURCE_APP="${SOURCE_APP:-$BUILD_DATA/Build/Products/Debug/Unsething.app}"
ditto "$SOURCE_APP" "$SMOKE_APP"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier it.unsething.librarytest' "$SMOKE_APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleName Unsething Library Test' "$SMOKE_APP/Contents/Info.plist"
codesign --force --deep --sign - "$SMOKE_APP"
open -n -g --stdout /tmp/unsething-library-smoke.out --stderr /tmp/unsething-library-smoke.err "$SMOKE_APP" --args \
    -DEFAULT_DATABASELOCATION 1 -DATABASELOCATION 1 \
    -DEFAULT_DATABASELOCATIONURL "$SMOKE_ROOT/database" -DATABASELOCATIONURL "$SMOKE_ROOT/database" \
    -AETITLE UNSETTEST -AEPORT 49193 -publishDICOMBonjour NO -searchDICOMBonjour NO \
    -AUTOCLEANINGSPACE NO -AUTOCLEANINGDATE NO -httpXMLRPCServer NO -STORESCPTLS NO
