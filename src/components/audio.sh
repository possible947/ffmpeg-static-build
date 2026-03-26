#!/bin/bash

build_audio_components() {
  ##
  ## audio library
  ##
  if ! $DISABLE_LV2 ; then
  
    if command_exists "python3"; then
    
      if command_exists "meson"; then
    
        if build "lv2" "1.18.10"; then
          download "https://lv2plug.in/spec/lv2-$CURRENT_PACKAGE_VERSION.tar.xz" "lv2-$CURRENT_PACKAGE_VERSION.tar.xz"
          execute meson build --prefix="${WORKSPACE}" --buildtype=release --default-library="$MESON_LIBRARY_MODE" --libdir="${WORKSPACE}"/lib
          execute ninja -C build
          execute ninja -C build install
          build_done "lv2" $CURRENT_PACKAGE_VERSION
        fi
        if build "waflib" "b600c92"; then
          download "https://gitlab.com/drobilla/autowaf/-/archive/$CURRENT_PACKAGE_VERSION/autowaf-$CURRENT_PACKAGE_VERSION.tar.gz" "autowaf.tar.gz"
          build_done "waflib" $CURRENT_PACKAGE_VERSION
        fi
        if build "serd" "0.32.8"; then
          download "https://gitlab.com/drobilla/serd/-/archive/v$CURRENT_PACKAGE_VERSION/serd-v$CURRENT_PACKAGE_VERSION.tar.gz" "serd-v$CURRENT_PACKAGE_VERSION.tar.gz"
          execute meson build --prefix="${WORKSPACE}" --buildtype=release --default-library="$MESON_LIBRARY_MODE" --libdir="${WORKSPACE}"/lib
          execute ninja -C build
          execute ninja -C build install
          build_done "serd" $CURRENT_PACKAGE_VERSION
        fi
        if build "pcre" "8.45"; then
          download "https://altushost-swe.dl.sourceforge.net/project/pcre/pcre/$CURRENT_PACKAGE_VERSION/pcre-$CURRENT_PACKAGE_VERSION.tar.gz" "pcre-$CURRENT_PACKAGE_VERSION.tar.gz"
          execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
          execute make -j "$MJOBS"
          execute make install
          build_done "pcre" $CURRENT_PACKAGE_VERSION
        fi
        if build "zix" "0.8.0"; then
          download "https://gitlab.com/drobilla/zix/-/archive/v$CURRENT_PACKAGE_VERSION/zix-v$CURRENT_PACKAGE_VERSION.tar.gz" "zix-v$CURRENT_PACKAGE_VERSION.tar.gz"
          execute meson setup build --prefix="${WORKSPACE}" --buildtype=release --default-library="$MESON_LIBRARY_MODE" --libdir="${WORKSPACE}"/lib
          cd build || exit
          execute meson configure -Dc_args="-march=native" -Dprefix="${WORKSPACE}" -Dlibdir="${WORKSPACE}"/lib
          execute meson compile
          execute meson install
          build_done "zix" $CURRENT_PACKAGE_VERSION
        fi
        if build "sord" "0.16.22"; then
          download "https://gitlab.com/drobilla/sord/-/archive/v$CURRENT_PACKAGE_VERSION/sord-v$CURRENT_PACKAGE_VERSION.tar.gz" "sord-v$CURRENT_PACKAGE_VERSION.tar.gz"
          execute meson build --prefix="${WORKSPACE}" --buildtype=release --default-library="$MESON_LIBRARY_MODE" --libdir="${WORKSPACE}"/lib
          execute ninja -C build
          execute ninja -C build install
          build_done "sord" $CURRENT_PACKAGE_VERSION
        fi
        if build "sratom" "0.6.22"; then
          download "https://gitlab.com/lv2/sratom/-/archive/v$CURRENT_PACKAGE_VERSION/sratom-v$CURRENT_PACKAGE_VERSION.tar.gz" "sratom-v$CURRENT_PACKAGE_VERSION.tar.gz"
          execute meson build --prefix="${WORKSPACE}" -Ddocs=disabled --buildtype=release --default-library="$MESON_LIBRARY_MODE" --libdir="${WORKSPACE}"/lib
          execute ninja -C build
          execute ninja -C build install
          build_done "sratom" $CURRENT_PACKAGE_VERSION
        fi
        if build "lilv" "0.26.4"; then
          download "https://gitlab.com/lv2/lilv/-/archive/v$CURRENT_PACKAGE_VERSION/lilv-v$CURRENT_PACKAGE_VERSION.tar.gz" "lilv-v$CURRENT_PACKAGE_VERSION.tar.gz"
          execute meson build --prefix="${WORKSPACE}" -Ddocs=disabled --buildtype=release --default-library="$MESON_LIBRARY_MODE" --libdir="${WORKSPACE}"/lib -Dcpp_std=c++11
          execute ninja -C build
          execute ninja -C build install
          build_done "lilv" $CURRENT_PACKAGE_VERSION
        fi
        CFLAGS+=" -I$WORKSPACE/include/lilv-0"
  
        if can_link_lilv; then
          CONFIGURE_OPTIONS+=("--enable-lv2")
        else
          echo "LV2 dependency check failed: lilv-0 is present but not linkable. Building FFmpeg without --enable-lv2."
        fi
    
      fi
    fi
  fi
  
  if build "opencore" "0.1.6"; then
    download "https://deac-ams.dl.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-$CURRENT_PACKAGE_VERSION.tar.gz" "opencore-amr-$CURRENT_PACKAGE_VERSION.tar.gz"
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
    execute make -j "$MJOBS"
    execute make install
  
    build_done "opencore" $CURRENT_PACKAGE_VERSION
  fi
  CONFIGURE_OPTIONS+=("--enable-libopencore_amrnb" "--enable-libopencore_amrwb")
  
  if build "lame" "3.100"; then
    download "https://sourceforge.net/projects/lame/files/lame/$CURRENT_PACKAGE_VERSION/lame-$CURRENT_PACKAGE_VERSION.tar.gz/download?use_mirror=gigenet" "lame-$CURRENT_PACKAGE_VERSION.tar.gz"
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
    execute make -j "$MJOBS"
    execute make install
  
    build_done "lame" $CURRENT_PACKAGE_VERSION
  fi
  CONFIGURE_OPTIONS+=("--enable-libmp3lame")
  
  if build "opus" "1.6.1"; then
    download "https://downloads.xiph.org/releases/opus/opus-$CURRENT_PACKAGE_VERSION.tar.gz"
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
    execute make -j "$MJOBS"
    execute make install
  
    build_done "opus" $CURRENT_PACKAGE_VERSION
  fi
  CONFIGURE_OPTIONS+=("--enable-libopus")
  
  if build "libogg" "1.3.6"; then
    download "https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-$CURRENT_PACKAGE_VERSION.tar.xz"
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
    execute make -j "$MJOBS"
    execute make install
    build_done "libogg" $CURRENT_PACKAGE_VERSION
  fi
  
  if build "libvorbis" "1.3.7"; then
    download "https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-$CURRENT_PACKAGE_VERSION.tar.gz"
    sed 's/-force_cpusubtype_ALL//g' configure.ac >configure.ac.patched
    rm configure.ac
    mv configure.ac.patched configure.ac
    execute ./autogen.sh --prefix="${WORKSPACE}"
    execute ./configure --prefix="${WORKSPACE}" --with-ogg-libraries="${WORKSPACE}"/lib --with-ogg-includes="${WORKSPACE}"/include/ "${LIB_LINK_FLAGS[@]}" --disable-oggtest
    execute make -j "$MJOBS"
    execute make install
  
    build_done "libvorbis" $CURRENT_PACKAGE_VERSION
  fi
  CONFIGURE_OPTIONS+=("--enable-libvorbis")
  
  if build "libtheora" "1.2.0"; then
    download "https://ftp.osuosl.org/pub/xiph/releases/theora/libtheora-$CURRENT_PACKAGE_VERSION.tar.gz"
    execute ./configure --prefix="${WORKSPACE}" --with-ogg-libraries="${WORKSPACE}"/lib --with-ogg-includes="${WORKSPACE}"/include/ --with-vorbis-libraries="${WORKSPACE}"/lib --with-vorbis-includes="${WORKSPACE}"/include/ "${LIB_LINK_FLAGS[@]}" --disable-oggtest --disable-vorbistest --disable-examples --disable-spec
    execute make -j "$MJOBS"
    execute make install
  
    build_done "libtheora" $CURRENT_PACKAGE_VERSION
  fi
  CONFIGURE_OPTIONS+=("--enable-libtheora")
  
}
