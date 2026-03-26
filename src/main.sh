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
source "$ROOT_DIR/src/utils/download.sh"
source "$ROOT_DIR/src/utils/state.sh"
source "$ROOT_DIR/src/config/options.sh"
source "$ROOT_DIR/src/components/dependencies.sh"
source "$ROOT_DIR/src/components/ffmpeg.sh"
source "$ROOT_DIR/src/components/mandatory.sh"


# Version comparison function
# Returns: 0 if v1 >= v2, 1 otherwise
version_gte() {
    local ver1="$1"
    local ver2="$2"

    # Handle empty/invalid inputs
    if [[ -z "$ver1" || -z "$ver2" ]]; then
        return 1
    fi

    # Split versions into components
    local IFS='.'
    read -ra V1 <<< "$ver1"
    read -ra V2 <<< "$ver2"

    local max_len=${#V1[@]}
    [[ ${#V2[@]} -gt $max_len ]] && max_len=${#V2[@]}

    for ((i=0; i<max_len; i++)); do
        local n1="${V1[i]:-0}"
        local n2="${V2[i]:-0}"

        # Strip pre-release suffixes for comparison (e.g., "a1", "rc1")
        n1="${n1%%[a-z]*}"
        n2="${n2%%[a-z]*}"

        # Compare numeric portions
        if (( n1 > n2 )); then
            return 0
        elif (( n1 < n2 )); then
            return 1
        fi

        # Handle suffixes (release candidates, pre-releases)
        if [[ "$n1" == *[a-z]* && "$n2" != *[a-z]* ]]; then
            return 1  # n1 has suffix, so it's less than stable n2
        elif [[ "$n2" == *[a-z]* && "$n1" != *[a-z]* ]]; then
            return 0  # n2 has suffix, so n1 is greater
        fi

        # Strip leading zeros and compare remaining parts
        n1="${n1#0}" || n1=0
        n2="${n2#0}" || n2=0
    done

    return 0  # Versions are equal or unknown
}

# Check if version meets minimum requirement (v >= min)
version_satisfies() {
    local current="$1"
    local minimum="$2"

    if ! version_gte "$current" "$minimum"; then
        return 1
    fi

    return 0
}

can_link_lilv() {
  if ! command_exists "gcc"; then
    return 1
  fi

  local test_c
  local test_bin
  test_c="$(mktemp /tmp/lilv-link-test-XXXXXX.c)"
  test_bin="${test_c%.c}"

  cat >"$test_c" <<'EOF'
#include <lilv/lilv.h>
int main(void) {
  LilvWorld *w = lilv_world_new();
  if (w) {
    lilv_world_free(w);
  }
  return 0;
}
EOF

  if gcc "$test_c" -o "$test_bin" $(pkg-config --cflags --libs lilv-0) >/dev/null 2>&1; then
    rm -f "$test_c" "$test_bin"
    return 0
  fi

  rm -f "$test_c" "$test_bin"
  return 1
}

# Check for Apple Silicon
if [[ ("$(uname -m)" == "arm64") && ("$OSTYPE" == "darwin"*) ]]; then
  # If arm64 AND darwin (macOS)
  export ARCH=arm64
  export MACOSX_DEPLOYMENT_TARGET=11.0
  export CXX=$(which clang++)
  MACOS_SILICON=true
  echo "Apple Silicon detected."

  # get macos version
  MACOS_VERSION=$(sw_vers -productVersion)
  echo "macOS Version: $MACOS_VERSION"

  #check if clang++ is installed and print version. Otherwise exit with an error message
  if command_exists "clang++"; then
    echo "clang++ is installed. Version: $(clang++ --version | head -n 1)"
  else
    echo "clang++ is not installed. Please install Xcode."
    exit 1
  fi
fi

# Speed up the process
# Env Var NUMJOBS overrides automatic detection
if [[ -n "$NUMJOBS" ]]; then
  MJOBS="$NUMJOBS"
elif [[ -f /proc/cpuinfo ]]; then
  MJOBS=$(grep -c processor /proc/cpuinfo)
elif [[ "$OSTYPE" == "darwin"* ]]; then
  MJOBS=$(sysctl -n machdep.cpu.thread_count)
  MACOS_LIBTOOL="$(which libtool)" # gnu libtool is installed in this script and need to avoid name conflict
else
  MJOBS=4
fi

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
