#!/bin/bash

# HOMEPAGE: https://github.com/markus-perl/ffmpeg-build-script
# LICENSE: https://github.com/markus-perl/ffmpeg-build-script/blob/master/LICENSE

PROGNAME=${PROGNAME_OVERRIDE:-$(basename "$0")}
FFMPEG_VERSION=8.1
SCRIPT_VERSION=1.59

CWD=$(pwd)
PACKAGES="$CWD/packages"
WORKSPACE="$CWD/workspace"
CFLAGS="-I$WORKSPACE/include -Wno-int-conversion"
LDFLAGS="-L$WORKSPACE/lib"
LDEXEFLAGS=""
EXTRALIBS="-ldl -lpthread -lm -lz"
MACOS_SILICON=false
FULL_STATIC=true
CONFIGURE_OPTIONS=()
NONFREE_AND_GPL=true
DISABLE_LV2=false
LATEST=false
MANPAGES=1
SKIPRAV1E=${SKIPRAV1E:-yes}
CURRENT_PACKAGE_VERSION=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# Phase A modularization: shared utility/state/download functions live under src/utils.
source "$ROOT_DIR/src/utils/common.sh"
source "$ROOT_DIR/src/utils/version.sh"
source "$ROOT_DIR/src/utils/platform.sh"
source "$ROOT_DIR/src/utils/download.sh"
source "$ROOT_DIR/src/utils/state.sh"
source "$ROOT_DIR/src/config/options.sh"
source "$ROOT_DIR/src/components/dependencies.sh"
source "$ROOT_DIR/src/components/ffmpeg.sh"
source "$ROOT_DIR/src/components/mandatory.sh"

init_platform_and_jobs

verify_binary_type() {
  if ! command_exists "file"; then
    return
  fi

  BINARY_TYPE=$(file "$WORKSPACE/bin/ffmpeg" | sed -n 's/^.*\:\ \(.*$\)/\1/p')
  echo ""
  case $BINARY_TYPE in
  "Mach-O 64-bit executable arm64")
    echo "Successfully built Apple Silicon for ${OSTYPE}: ${BINARY_TYPE}"
    ;;
  *)
    echo "Successfully built binary for ${OSTYPE}: ${BINARY_TYPE}"
    ;;
  esac
}

echo "ffmpeg-build-script v$SCRIPT_VERSION"
echo "========================="
echo ""

parse_cli_options "$@"

LIB_LINK_FLAGS=("--disable-shared" "--enable-static")
MESON_LIBRARY_MODE="static"
CMAKE_ENABLE_SHARED="-DENABLE_SHARED=OFF"
CMAKE_BUILD_SHARED_LIBS="-DBUILD_SHARED_LIBS=OFF"
CMAKE_ENABLE_STATIC="-DENABLE_STATIC=ON"
OPENSSL_LINK_FLAG="no-shared"
RAV1E_LIBRARY_TYPE="staticlib"

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  LDEXEFLAGS="-static -fPIC"
  CFLAGS+=" -fPIC"
  CXXFLAGS+=" -fPIC"
fi

CONFIGURE_OPTIONS+=("--enable-gpl" "--enable-nonfree")
if [[ "$OSTYPE" == "darwin"* ]]; then
  CONFIGURE_OPTIONS+=("--enable-videotoolbox")
fi

echo "Using $MJOBS make jobs simultaneously."

echo "With GPL and non-free codecs"


if [ -n "$LDEXEFLAGS" ]; then
  echo "Start the build in full static mode."
fi

mkdir -p "$PACKAGES"
mkdir -p "$WORKSPACE"

export PATH="${WORKSPACE}/bin:$PATH"
PKG_CONFIG_PATH="$WORKSPACE/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/local/lib/pkgconfig"
PKG_CONFIG_PATH+=":/usr/local/share/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig:/usr/lib64/pkgconfig"
export PKG_CONFIG_PATH

if ! command_exists "make"; then
  echo "make not installed."
  exit 1
fi

if ! command_exists "g++"; then
  echo "g++ not installed."
  exit 1
fi

if ! command_exists "curl"; then
  echo "curl not installed."
  exit 1
fi

if ! command_exists "cargo"; then
  echo "cargo not installed. rav1e encoder will not be available."
fi

if ! command_exists "python3"; then
  echo "python3 command not found. Lv2 filter and dav1d decoder will not be available."
fi

build_dependencies
build_ffmpeg_and_install
