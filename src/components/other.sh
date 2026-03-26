#!/bin/bash

sanitize_freetype2_pkgconfig() {
  local pc_file="${WORKSPACE}/lib/pkgconfig/freetype2.pc"

  if [ ! -f "$pc_file" ]; then
    return
  fi

  # In static mode, distro harfbuzz/brotli static libs are often unavailable.
  # Keep freetype enabled while avoiding optional transitive link failures.
  sed -i.backup \
    -e 's/, harfbuzz >= 2.0.0//g' \
    -e 's/harfbuzz >= 2.0.0, //g' \
    -e 's/, libbrotlidec//g' \
    -e 's/libbrotlidec, //g' \
    -e 's/-lharfbuzz//g' \
    -e 's/-lgraphite2//g' \
    -e 's/-lglib-2.0//g' \
    -e 's/-lpcre2-8//g' \
    -e 's/-lbrotlidec//g' \
    -e 's/-lbrotlicommon//g' \
    "$pc_file"
}

freetype_requires_unwanted_static_deps() {
  local pc_file="${WORKSPACE}/lib/pkgconfig/freetype2.pc"

  if [ ! -f "$pc_file" ]; then
    return 1
  fi

  if grep -Eq 'harfbuzz|libbrotli' "$pc_file"; then
    return 0
  fi

  return 1
}

build_other_components() {
  ##
  ## other library
  ##
  
  if build "libsdl" "2.30.12"; then
    download "https://github.com/libsdl-org/SDL/releases/download/release-$CURRENT_PACKAGE_VERSION/SDL2-$CURRENT_PACKAGE_VERSION.tar.gz"
  
    SDL_X11_ARGS=()
    if [[ ! -f "/usr/include/X11/extensions/Xext.h" && ! -f "/usr/local/include/X11/extensions/Xext.h" ]]; then
      echo "X11 headers not found (Xext.h). Building SDL2 without X11 backend."
      SDL_X11_ARGS+=("--disable-video-x11")
    fi
  
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}" "${SDL_X11_ARGS[@]}"
    execute make -j "$MJOBS"
    execute make install
  
    build_done "libsdl" $CURRENT_PACKAGE_VERSION
  fi
  
  if freetype_requires_unwanted_static_deps; then
    echo "FreeType2 in workspace references HarfBuzz/Brotli. Rebuilding FreeType2 for static compatibility."
    rm -f "$PACKAGES/FreeType2.done"
  fi

  if build "FreeType2" "2.14.2"; then
    download "https://downloads.sourceforge.net/freetype/freetype-$CURRENT_PACKAGE_VERSION.tar.xz"
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}" --with-harfbuzz=no --with-brotli=no
    execute make -j "$MJOBS"
    execute make install
    build_done "FreeType2" $CURRENT_PACKAGE_VERSION
  fi

  sanitize_freetype2_pkgconfig
  
  CONFIGURE_OPTIONS+=("--enable-libfreetype")
  
  if build "VapourSynth" "73"; then
    # VapourSynth library is loaded dynamically by ffmpeg if a VapourSynth script is opened
    # no need to build it at compile team, only headers need to be installed
    download "https://github.com/vapoursynth/vapoursynth/archive/R$CURRENT_PACKAGE_VERSION.tar.gz"
    execute mkdir -p "${WORKSPACE}/include/vapoursynth"
    execute cp -r "include/." "${WORKSPACE}/include/vapoursynth/"
    build_done "VapourSynth" $CURRENT_PACKAGE_VERSION
  fi
  
  CONFIGURE_OPTIONS+=("--enable-vapoursynth")
  
  if $NONFREE_AND_GPL; then
    if build "srt" "1.5.4"; then
      download "https://github.com/Haivision/srt/archive/v$CURRENT_PACKAGE_VERSION.tar.gz" "srt-$CURRENT_PACKAGE_VERSION.tar.gz"
      export OPENSSL_ROOT_DIR="${WORKSPACE}"
      export OPENSSL_LIB_DIR="${WORKSPACE}"/lib
      export OPENSSL_INCLUDE_DIR="${WORKSPACE}"/include/
      execute cmake . -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_BINDIR=bin -DCMAKE_INSTALL_INCLUDEDIR=include "$CMAKE_ENABLE_SHARED" "$CMAKE_ENABLE_STATIC" -DENABLE_APPS=OFF -DUSE_STATIC_LIBSTDCXX=ON
      execute make install
  
      if [ -n "$LDEXEFLAGS" ]; then
        sed -i.backup 's/-lgcc_s/-lgcc_eh/g' "${WORKSPACE}"/lib/pkgconfig/srt.pc # The -i.backup is intended and required on MacOS: https://stackoverflow.com/questions/5694228/sed-in-place-flag-that-works-both-on-mac-bsd-and-linux
      fi
  
      build_done "srt" $CURRENT_PACKAGE_VERSION
    fi
    CONFIGURE_OPTIONS+=("--enable-libsrt")
  
    if build "zvbi" "0.2.44"; then
      download "https://github.com/zapping-vbi/zvbi/archive/refs/tags/v$CURRENT_PACKAGE_VERSION.tar.gz" "zvbi-$CURRENT_PACKAGE_VERSION.tar.gz"
      execute ./autogen.sh --prefix="${WORKSPACE}"
      execute ./configure CFLAGS="-I${WORKSPACE}/include/libpng16 ${CFLAGS}" --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
      execute make -j "$MJOBS"
      execute make install
      build_done "zvbi" $CURRENT_PACKAGE_VERSION
    fi
    CONFIGURE_OPTIONS+=("--enable-libzvbi")
  fi
  
}
