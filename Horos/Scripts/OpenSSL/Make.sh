#!/bin/sh

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/Config"
install_dir="$TARGET_TEMP_DIR/Install"

source_dir="$PROJECT_DIR/$TARGET_NAME"
# A completed install is reusable only while its source tree and build script are unchanged.
if [ -f "$install_dir/.completed" ] && [ ! -f "$install_dir/.incomplete" ] &&
   [ ! "$0" -nt "$install_dir/.completed" ] &&
   [ -z "$(find "$source_dir" -newer "$install_dir/.completed" -print -quit)" ]; then
    exit 0
fi

mkdir -p "$install_dir"
touch "$install_dir/.incomplete"

args=()
export MAKEFLAGS="-j $(getconf _NPROCESSORS_ONLN)"
export CC=clang
export CXX=clang
export COMMAND_MODE=unix2003

cd "$cmake_dir"
make "${args[@]}"
make install_sw

rm -f "$install_dir/.incomplete"
touch "$install_dir/.completed"

exit 0
