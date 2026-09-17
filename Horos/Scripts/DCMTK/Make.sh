#!/bin/sh

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"
install_dir="$TARGET_TEMP_DIR/Install"
copy_dir="$BUILT_PRODUCTS_DIR/DCMTK"

source_dir="$PROJECT_DIR/$TARGET_NAME"
# A completed install is reusable only while its source tree and build script are unchanged.
if [ -f "$install_dir/.completed" ] && [ ! -f "$install_dir/.incomplete" ] &&
   [ ! "$0" -nt "$install_dir/.completed" ] &&
   [ -z "$(find "$source_dir" -newer "$install_dir/.completed" -print -quit)" ]; then
    exit 0
fi

mkdir -p "$install_dir"
mkdir -p "${copy_dir}"
touch "${copy_dir}/.incomplete"

args=()
export MAKEFLAGS="-j $(getconf _NPROCESSORS_ONLN)"

echo "${cmake_dir}"
cd "$cmake_dir"
make "${args[@]}" install

# Copy subset of applications to build directory
#
cp "${install_dir}/bin/dcmdump" "${copy_dir}"
cp "${install_dir}/bin/dcmpsprt" "${copy_dir}"
cp "${install_dir}/bin/dcmprscu" "${copy_dir}"
cp "${install_dir}/bin/dsr2html" "${copy_dir}"
cp "${install_dir}/bin/echoscu" "${copy_dir}"
cp "${install_dir}"/share/dcmtk*/dicom.dic "${copy_dir}"

mkdir -p "$install_dir/wlib"
libtool -static -o "$install_dir/wlib/libDCMTK.a" "$install_dir"/lib/*.a
rm -f "$copy_dir/.incomplete"
touch "$install_dir/.completed"

exit 0
