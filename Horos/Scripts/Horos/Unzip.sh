#!/bin/sh
set -eu
cd "$SRCROOT/Binaries"
unzip -uoq DB_Previous_Models.zip
unzip -uoq PAGES.zip
unzip -uoq OsiriXReport.template.zip
unzip -uoq dciodvfy.zip
unzip -uoq weasis-portable*.zip -d weasis
chmod -R 755 weasis
find "$SRCROOT/Binaries/weasis" -name __MACOSX -type d -prune -exec rm -rf {} +
# Remove the empty legacy macOS launcher from the media-viewer resources.
rm -rf "$SRCROOT/Binaries/weasis/viewer-mac.app"
find "$SRCROOT/Binaries/PAGES" -name '._*' -type f -delete
