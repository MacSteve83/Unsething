#!/bin/sh

set -e; set -o xtrace

source_dir="$PROJECT_DIR/$TARGET_NAME"
cmake_dir="$TARGET_TEMP_DIR/CMake"
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

cd "$cmake_dir"
make "${args[@]}"
make install

rsync "$cmake_dir/bin/libopenjp2.a" "$install_dir/lib/" # retain the static library for Xcode linking
mkdir -p "$install_dir/include/OpenJPEG"
cp "$install_dir"/include/openjpeg-*/*.h "$install_dir/include/OpenJPEG/"
rsync "$source_dir/src/bin/common/format_defs.h" "$install_dir/include/OpenJPEG/" # we need this header

rm -f "$install_dir/.incomplete"
touch "$install_dir/.completed"

exit 0
