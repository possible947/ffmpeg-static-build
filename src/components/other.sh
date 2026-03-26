#!/bin/bash

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
  
  if build "FreeType2" "2.14.2"; then
    download "https://downloads.sourceforge.net/freetype/freetype-$CURRENT_PACKAGE_VERSION.tar.xz"
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
    execute make -j "$MJOBS"
    execute make install
    build_done "FreeType2" $CURRENT_PACKAGE_VERSION
  fi
  
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
