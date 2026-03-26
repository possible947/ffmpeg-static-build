#!/bin/bash

# Shared utility functions for the modularized build flow.

command_exists() {
  if ! [[ -x $(command -v "$1") ]]; then
    return 1
  fi

  return 0
}

remove_dir() {
  if [ -d "$1" ]; then
    rm -rf "$1"
  fi
}

make_dir() {
  remove_dir "$1"
  if ! mkdir "$1"; then
    printf "\n Failed to create dir %s" "$1"
    exit 1
  fi
}

print_flags() {
  echo "Flags: CFLAGS \"$CFLAGS\", CXXFLAGS \"$CXXFLAGS\", LDFLAGS \"$LDFLAGS\", LDEXEFLAGS \"$LDEXEFLAGS\""
}

execute() {
  if [[ "$1" == *configure* ]]; then
    print_flags
  fi

  echo "$ $*"

  OUTPUT=$("$@" 2>&1)

  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    echo "$OUTPUT"
    echo ""
    echo "Failed to Execute $*" >&2
    exit 1
  fi
}

cmake() {
  if [[ "$1" == "--build" ]]; then
    command cmake "$@"
  else
    command cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 "$@"
  fi
}

cleanup() {
  remove_dir "$PACKAGES"
  remove_dir "$WORKSPACE"
  echo "Cleanup done."
  echo ""
}

usage() {
  echo "Usage: $PROGNAME [OPTIONS]"
  echo "Options:"
  echo "  -h, --help                     Display usage information"
  echo "      --version                  Display version information"
  echo "  -b, --build                    Starts the build process"
  echo "      --enable-gpl-and-non-free  Enable GPL and non-free codecs  - https://ffmpeg.org/legal.html"
  echo "      --disable-lv2              Disable LV2 libraries"
  echo "  -c, --cleanup                  Remove all working dirs"
  echo "      --latest                   Build latest version of dependencies if newer available"
  echo "      --small                    Prioritize small size over speed and usability; don't build manpages"
  echo "      --full-static              Build a full static FFmpeg binary (eg. glibc, pthreads etc...) **only Linux**"
  echo "                                 Note: Because of the NSS (Name Service Switch), glibc does not recommend static links."
  echo "      --skip-install             Don't install FFmpeg, FFprobe, and FFplay binaries to your system"
  echo "      --auto-install             Install FFmpeg, FFprobe, and FFplay binaries to your system"
  echo "                                 Note: Without --skip-install or --auto-install the script will prompt you to install."
  echo ""
}
