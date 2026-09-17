#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
BUILD_DATA="${BUILD_DATA:-DerivedData}"
BUILD_ARCH="${BUILD_ARCH:-$(uname -m)}"
LIBROOT="$PWD/$BUILD_DATA/Build/Intermediates.noindex/Unsething.build/Debug"
TEST_DIR="$(mktemp -d /tmp/unsething-libraries.XXXXXX)"
trap 'rm -rf "$TEST_DIR"' EXIT
CXX=(xcrun clang++ -arch "$BUILD_ARCH" -std=c++17)
"${CXX[@]}" script/tests/test_openjpeg_roundtrip.cpp -I "$LIBROOT/OpenJPEG.build/Install/include" "$LIBROOT/OpenJPEG.build/Install/lib/libopenjp2.a" -o "$TEST_DIR/openjpeg"
"$TEST_DIR/openjpeg"
"$LIBROOT/DCMTK.build/Install/bin/dump2dcm" +te script/tests/library_fixture.dump "$TEST_DIR/fixture.dcm"
"${CXX[@]}" script/tests/test_image_libraries.cpp -I "$LIBROOT/ITK.build/Install/include" -I "$LIBROOT/GDCM.build/Install/include" "$LIBROOT/ITK.build/Install/wlib/libITK.a" "$LIBROOT/GDCM.build/Install/wlib/libGDCM.a" "$LIBROOT/OpenJPEG.build/Install/lib/libopenjp2.a" -lz -lexpat -liconv -framework CoreFoundation -o "$TEST_DIR/imaging"
"$TEST_DIR/imaging" "$TEST_DIR/fixture.dcm"
"${CXX[@]}" script/tests/test_vtk_pipeline.cpp -I "$LIBROOT/VTK.build/Install/include/vtk-9.7" "$LIBROOT/VTK.build/Install/wlib/libVTK.a" -framework CoreFoundation -lz -lpthread -o "$TEST_DIR/vtk"
"$TEST_DIR/vtk"
"${CXX[@]}" script/tests/test_dcmtk_sr.cpp -I "$LIBROOT/DCMTK.build/Install/include" "$LIBROOT/DCMTK.build/Install/wlib/libDCMTK.a" -lz -liconv -lxml2 -o "$TEST_DIR/sr"
"$TEST_DIR/sr"
"${CXX[@]}" script/tests/test_dcmtk_ct_rescale.cpp -I "$LIBROOT/DCMTK.build/Install/include" "$LIBROOT/DCMTK.build/Install/wlib/libDCMTK.a" -lz -liconv -lxml2 -o "$TEST_DIR/ct-rescale"
"$TEST_DIR/ct-rescale"
(cd CharLS && "$LIBROOT/CharLS.build/CMake/test/charlstest" -unittest)
"$LIBROOT/OpenSSL.build/Install/bin/openssl" version
printf 'PASS dependency checks (%s)\n' "$BUILD_ARCH"
