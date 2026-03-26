#!/bin/bash

verify_pkg_config_module() {
  local module="$1"
  local label="$2"

  if ! pkg-config --exists "$module"; then
    echo "Error: mandatory dependency '$label' is not discoverable via pkg-config module '$module'."
    exit 1
  fi
}

build_mandatory_components() {
  if ! command_exists "python3"; then
    echo "Error: python3 is required to build mandatory libvmaf."
    exit 1
  fi

  if ! command_exists "meson"; then
    echo "Error: meson is required to build mandatory libvmaf."
    exit 1
  fi

  if ! command_exists "ninja"; then
    echo "Error: ninja is required to build mandatory libvmaf."
    exit 1
  fi

  if build "libvmaf" "3.0.0"; then
    download "https://github.com/Netflix/vmaf/archive/refs/tags/v$CURRENT_PACKAGE_VERSION.tar.gz" "libvmaf-$CURRENT_PACKAGE_VERSION.tar.gz"
    cd libvmaf || exit
    make_dir build
    cd build || exit
    execute meson setup .. --prefix="${WORKSPACE}" --buildtype=release --libdir="${WORKSPACE}"/lib --default-library="$MESON_LIBRARY_MODE"
    execute ninja
    execute ninja install
    build_done "libvmaf" $CURRENT_PACKAGE_VERSION
  fi
  verify_pkg_config_module "libvmaf" "libvmaf"
  CONFIGURE_OPTIONS+=("--enable-libvmaf")

  if build "fdk_aac" "2.0.3"; then
    download "https://sourceforge.net/projects/opencore-amr/files/fdk-aac/fdk-aac-$CURRENT_PACKAGE_VERSION.tar.gz/download?use_mirror=gigenet" "fdk-aac-$CURRENT_PACKAGE_VERSION.tar.gz"
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}" --enable-pic
    execute make -j "$MJOBS"
    execute make install
    build_done "fdk_aac" $CURRENT_PACKAGE_VERSION
  fi
  verify_pkg_config_module "fdk-aac" "libfdk-aac"
  CONFIGURE_OPTIONS+=("--enable-libfdk-aac")

  if build "soxr" "0.1.3"; then
    download "https://sourceforge.net/projects/soxr/files/soxr-$CURRENT_PACKAGE_VERSION-Source.tar.xz/download?use_mirror=gigenet" "soxr-$CURRENT_PACKAGE_VERSION.tar.xz"

    mkdir build && cd build
    execute cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" "$CMAKE_BUILD_SHARED_LIBS" -DWITH_OPENMP:bool=off -DBUILD_TESTS:bool=off -Wno-dev ..
    execute make -j "$MJOBS"
    execute make install

    build_done "soxr" $CURRENT_PACKAGE_VERSION
  fi
  verify_pkg_config_module "soxr" "libsoxr"
  CONFIGURE_OPTIONS+=("--enable-libsoxr")
}
