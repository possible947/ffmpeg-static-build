#!/bin/bash

build() {
  echo ""
  echo "building $1 - version $2"
  echo "======================="
  CURRENT_PACKAGE_VERSION=$2

  # Always rebuild FFmpeg itself at the final stage.
  if [ "$1" = "ffmpeg" ]; then
    return 0
  fi

  if [ -f "$PACKAGES/$1.done" ]; then
    existing_ver="$(cat "$PACKAGES/$1.done" | awk '{print $1}')"

    if [ "$existing_ver" = "$2" ] && ! $LATEST; then
      echo "$1 version $2 already built."
      return 1
    fi

    if $LATEST; then
      echo "$1 will be rebuilt with latest mode enabled."
      return 0
    fi
  fi

  return 0
}

library_exists() {
  if ! [[ -x $(pkg-config --exists --print-errors "$1" 2>&1 >/dev/null) ]]; then
    return 1
  fi

  return 0
}

build_done() {
  echo "$2" >"$PACKAGES/$1.done"
}
