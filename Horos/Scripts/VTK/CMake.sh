#!/bin/sh

export PATH="$PATH:/opt/local/bin:/opt/local/sbin"

path="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )/$(basename "${BASH_SOURCE[0]}")"
cd "$TARGET_NAME"; pwd

env="arch=$ARCHS config=$CONFIGURATION sdk=$SDKROOT deployment=$MACOSX_DEPLOYMENT_TARGET cxx=$CLANG_CXX_LANGUAGE_STANDARD cflags=$OTHER_CFLAGS cxxflags=$OTHER_CPLUSPLUSFLAGS"
hash="$(shasum -a 256 "$PROJECT_DIR/DEPENDENCIES.lock.json" | cut -d " " -f1) $(md5 -q "$path")-$(md5 -qs "$env")"

set -e; set -o xtrace

cmake_dir="$TARGET_TEMP_DIR/CMake"
install_dir="$TARGET_TEMP_DIR/Install"

mkdir -p "$cmake_dir"; cd "$cmake_dir"
if [ -e Makefile -a -f .cmakehash ] && [ "$(cat '.cmakehash')" = "$hash" ]; then
    exit 0
fi

if [ -e ".cmakeenv" ]; then
echo "Rebuilding.."
cat '.cmakeenv'
echo "$env"
fi


command -v cmake >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires CMake. Please install CMake. Aborting."; exit 1; }
command -v pkg-config >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires pkg-config. Please install pkg-config. Aborting."; exit 1; }
if [ "$SKIP_SUBMODULES" != "1" ]; then
    command -v git-lfs >/dev/null 2>&1 || { echo >&2 "error: building $TARGET_NAME requires git-lfs. Please install git-lfs. Aborting."; exit 1; }
fi


mv "$cmake_dir" "$cmake_dir.tmp"
[ -d "$install_dir" ] && mv "$install_dir" "$install_dir.tmp"
rm -Rf "$cmake_dir.tmp" "$install_dir.tmp"
mkdir -p "$cmake_dir"; cd "$cmake_dir"

args=("$PROJECT_DIR/$TARGET_NAME") # -G Xcode
cxxfs=( -w -fvisibility=default )
args+=(-DVTK_USE_X:BOOL=OFF)
args+=(-DVTK_USE_COCOA:BOOL=ON)
#args+=(-DVTK_USE_64BITS_IDS=ON) 
args+=(-DBUILD_DOCUMENTATION=OFF)
args+=(-DBUILD_EXAMPLES=OFF)
args+=(-DBUILD_SHARED_LIBS=OFF)
args+=(-DBUILD_TESTING=OFF -DVTK_BUILD_TESTING=OFF -DVTK_BUILD_EXAMPLES=OFF)
args+=(-DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET")
args+=(-DCMAKE_OSX_ARCHITECTURES="$ARCHS")
args+=(-DCMAKE_POLICY_VERSION_MINIMUM=3.5)

args+=(-DVTK_USE_SYSTEM_ZLIB:BOOL=ON)
args+=(-DVTK_USE_SYSTEM_EXPAT=ON)
args+=(-DVTK_USE_SYSTEM_LIBXML2=ON)

# args+=(-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON)

[ "$CONFIGURATION" == 'Release' ] && args+=( -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS_RELEASE=-O3 )

args+=(-DVTK_GROUP_ENABLE_StandAlone=DONT_WANT -DVTK_GROUP_ENABLE_Rendering=DONT_WANT) # disable the default groups
args+=(-DVTK_MODULE_ENABLE_VTK_IOImage=YES)
args+=(-DVTK_MODULE_ENABLE_VTK_FiltersGeneral=YES)
args+=(-DVTK_MODULE_ENABLE_VTK_ImagingMorphological=YES)
args+=(-DVTK_MODULE_ENABLE_VTK_ImagingStencil=YES)
args+=(-DVTK_MODULE_ENABLE_VTK_RenderingOpenGL2=YES)
args+=(-DVTK_MODULE_ENABLE_VTK_RenderingVolumeOpenGL2=YES)
args+=(-DVTK_MODULE_ENABLE_VTK_RenderingAnnotation=YES)
args+=(-DVTK_MODULE_ENABLE_VTK_InteractionWidgets=YES)
args+=(-DVTK_MODULE_ENABLE_VTK_IOGeometry=YES)
args+=(-DVTK_MODULE_ENABLE_VTK_IOExport=YES)
args+=(-DVTK_MODULE_ENABLE_VTK_FiltersTexture=YES)
args+=(-DVTK_MODULE_ENABLE_VTK_tiff=YES)

args+=(-DCMAKE_INSTALL_PREFIX="$install_dir")
args+=(-DVTK_INSTALL_INCLUDE_DIR="include")

args+=(-DCMAKE_IGNORE_PATH="/opt/local/include;/opt/local/lib")

if [ ! -z "$CLANG_CXX_LIBRARY" ] && [ "$CLANG_CXX_LIBRARY" != 'compiler-default' ]; then
#    args+=(-DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LIBRARY="$CLANG_CXX_LIBRARY")
    cxxfs+=(-stdlib="$CLANG_CXX_LIBRARY")
fi
if [ ! -z "$CLANG_CXX_LANGUAGE_STANDARD" ]; then
#    args+=(-DCMAKE_XCODE_ATTRIBUTE_CLANG_CXX_LANGUAGE_STANDARD="$CLANG_CXX_LANGUAGE_STANDARD")
    cxxfs+=(-std="$CLANG_CXX_LANGUAGE_STANDARD")
fi

if [ ${#cxxfs[@]} -ne 0 ]; then
    cxxfss="${cxxfs[@]}"
    args+=(-DCMAKE_CXX_FLAGS="$cxxfss")
fi

cmake "${args[@]}"

echo "$hash" > "$cmake_dir/.cmakehash"
echo "$env" > "$cmake_dir/.cmakeenv"

exit 0
