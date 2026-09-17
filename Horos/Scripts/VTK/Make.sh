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

cd "$cmake_dir"
make "${args[@]}" install

# missing tiff headers
mkdir -p "$install_dir/include/vtk-9.7/vtktiff/libtiff"
find "$source_dir/ThirdParty/tiff/vtktiff/libtiff"  -name '*.h' -exec rsync {} "$install_dir/include/vtk-9.7/vtktiff/libtiff/" \;
rsync "$cmake_dir/ThirdParty/tiff/vtktiff/libtiff/tiffconf.h" "$install_dir/include/vtk-9.7/vtktiff/libtiff/"

# wrap the libs into one
mkdir -p "$install_dir/wlib"
ars=$(find "$install_dir/lib" -name '*.a' -type f)
libtool -static -o "$install_dir/wlib/lib$PRODUCT_NAME.a" $ars

rm -f "$install_dir/.incomplete"
touch "$install_dir/.completed"

exit 0
