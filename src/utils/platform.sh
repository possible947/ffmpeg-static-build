#!/bin/bash

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

init_platform_and_jobs() {
  if [[ ("$(uname -m)" == "arm64") && ("$OSTYPE" == "darwin"*) ]]; then
    export ARCH=arm64
    export MACOSX_DEPLOYMENT_TARGET=11.0
    export CXX=$(which clang++)
    MACOS_SILICON=true
    echo "Apple Silicon detected."

    MACOS_VERSION=$(sw_vers -productVersion)
    echo "macOS Version: $MACOS_VERSION"

    if command_exists "clang++"; then
      echo "clang++ is installed. Version: $(clang++ --version | head -n 1)"
    else
      echo "clang++ is not installed. Please install Xcode."
      exit 1
    fi
  fi

  if [[ -n "$NUMJOBS" ]]; then
    MJOBS="$NUMJOBS"
  elif [[ -f /proc/cpuinfo ]]; then
    MJOBS=$(grep -c processor /proc/cpuinfo)
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    MJOBS=$(sysctl -n machdep.cpu.thread_count)
    MACOS_LIBTOOL="$(which libtool)"
  else
    MJOBS=4
  fi
}
