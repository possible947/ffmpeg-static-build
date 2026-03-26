#!/bin/bash

build_video_components() {
  ##
  ## video library
  ##
  
  if command_exists "python3"; then
    # dav1d needs meson and ninja along with nasm to be built
  
    #set variable meson and ninja installed to false
    MESON_INSTALLED=false
  
    if command_exists "meson"; then
      if command_exists "ninja"; then
        MESON_INSTALLED=true
      fi
    fi
  
    if ! $MESON_INSTALLED; then
      #check if macOS and brew is available
      if [[ "$OSTYPE" == "darwin"* ]]; then
        if command_exists "brew"; then
          brew install python-setuptools meson ninja
          MESON_INSTALLED=true
        fi
      else
        if command_exists "pip3"; then
          echo "Try to install meson and ninja using pip3."
          echo "If you get an error (like externally-managed-environment), try to install meson using your system package manager"
          # meson and ninja can be installed via pip3
          execute pip3 install pip setuptools --quiet --upgrade --no-cache-dir --disable-pip-version-check
          for r in meson ninja; do
            if ! command_exists ${r}; then
              execute pip3 install ${r} --quiet --upgrade --no-cache-dir --disable-pip-version-check
            fi
            export PATH=$PATH:~/Library/Python/3.9/bin
          done
        else
          echo "Try to install meson using your system package manager to be able to compile ffmpeg with dav1d."
        fi
      fi
    fi
    if command_exists "meson"; then
      if build "dav1d" "1.5.3"; then
        download "https://code.videolan.org/videolan/dav1d/-/archive/$CURRENT_PACKAGE_VERSION/dav1d-$CURRENT_PACKAGE_VERSION.tar.gz"
        make_dir build
  
        CFLAGSBACKUP=$CFLAGS
        if $MACOS_SILICON; then
          export CFLAGS="-arch arm64"
        fi
  
        execute meson build --prefix="${WORKSPACE}" --buildtype=release --default-library="$MESON_LIBRARY_MODE" --libdir="${WORKSPACE}"/lib
        execute ninja -C build
        execute ninja -C build install
  
        if $MACOS_SILICON; then
          export CFLAGS=$CFLAGSBACKUP
        fi
  
        build_done "dav1d" $CURRENT_PACKAGE_VERSION
      fi
      CONFIGURE_OPTIONS+=("--enable-libdav1d")
    fi
  fi
  
  if build "svtav1" "4.0.1"; then
    # Last known working commit which passed CI Tests from HEAD branch
    download "https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v$CURRENT_PACKAGE_VERSION/SVT-AV1-v$CURRENT_PACKAGE_VERSION.tar.gz" "svtav1-$CURRENT_PACKAGE_VERSION.tar.gz"
    cd "${PACKAGES}"/svtav1-$CURRENT_PACKAGE_VERSION//Build/linux || exit
    execute cmake -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" "$CMAKE_ENABLE_SHARED" "$CMAKE_BUILD_SHARED_LIBS" ../.. -G"Unix Makefiles" -DCMAKE_BUILD_TYPE=Release
    execute make -j "$MJOBS"
    execute make install
    execute cp SvtAv1Enc.pc "${WORKSPACE}/lib/pkgconfig/"
    build_done "svtav1" $CURRENT_PACKAGE_VERSION
  fi
  CONFIGURE_OPTIONS+=("--enable-libsvtav1")
  
  
  if command_exists "cargo"; then
    if [[ ! "$SKIPRAV1E" == "yes" ]]; then
      if build "rav1e" "0.8.1"; then
        echo "if you get the message 'cannot be built because it requires rustc x.xx or newer, try to run 'rustup update'"
        execute cargo install cargo-c
        download "https://github.com/xiph/rav1e/archive/refs/tags/v$CURRENT_PACKAGE_VERSION.tar.gz"
        export RUSTFLAGS="-C target-cpu=native"  
        execute cargo cinstall --prefix="${WORKSPACE}" --libdir=lib --library-type="$RAV1E_LIBRARY_TYPE" --release
        build_done "rav1e" $CURRENT_PACKAGE_VERSION
      fi
      CONFIGURE_OPTIONS+=("--enable-librav1e")
    fi
  fi
  
  if $NONFREE_AND_GPL; then
  
    if build "x264" "0480cb05"; then
      download "https://code.videolan.org/videolan/x264/-/archive/$CURRENT_PACKAGE_VERSION/x264-$CURRENT_PACKAGE_VERSION.tar.gz" "x264-$CURRENT_PACKAGE_VERSION.tar.gz"
      cd "${PACKAGES}"/x264-$CURRENT_PACKAGE_VERSION || exit
  
      if [[ "$OSTYPE" == "linux-gnu" ]]; then
        execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}" --enable-pic CXXFLAGS="-fPIC ${CXXFLAGS}"
      else
        execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}" --enable-pic
      fi
  
      execute make -j "$MJOBS"
      execute make install
      if $FULL_STATIC; then
        execute make install-lib-static
      fi
  
      build_done "x264" $CURRENT_PACKAGE_VERSION
    fi
    CONFIGURE_OPTIONS+=("--enable-libx264")
  fi
  
  if $NONFREE_AND_GPL; then
    if build "x265" "8be7dbf"; then
      download "https://bitbucket.org/multicoreware/x265_git/get/8be7dbf8159ddfceea4115675a6d48e1611b8baa.tar.gz" "x265-8be7dbf.tar.gz"
  
      if $MACOS_SILICON; then
          export CXXFLAGS="-DHAVE_NEON=1 ${CXXFLAGS}"
      fi
  
      cd build/linux || exit
      if $FULL_STATIC; then
        rm -rf 8bit 10bit 12bit 2>/dev/null
        mkdir -p 8bit 10bit 12bit
        cd 12bit || exit
        execute cmake ../../../source -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" -DENABLE_SHARED=OFF -DBUILD_SHARED_LIBS=OFF -DHIGH_BIT_DEPTH=ON -DENABLE_HDR10_PLUS=ON -DEXPORT_C_API=OFF -DENABLE_CLI=OFF -DMAIN12=ON
        execute make -j "$MJOBS"
        cd ../10bit || exit
        execute cmake ../../../source -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" -DENABLE_SHARED=OFF -DBUILD_SHARED_LIBS=OFF -DHIGH_BIT_DEPTH=ON -DENABLE_HDR10_PLUS=ON -DEXPORT_C_API=OFF -DENABLE_CLI=OFF
        execute make -j "$MJOBS"
        cd ../8bit || exit
        ln -sf ../10bit/libx265.a libx265_main10.a
        ln -sf ../12bit/libx265.a libx265_main12.a
        execute cmake ../../../source -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" -DENABLE_SHARED=OFF -DBUILD_SHARED_LIBS=OFF -DEXTRA_LIB="x265_main10.a;x265_main12.a;-ldl" -DEXTRA_LINK_FLAGS=-L. -DLINKED_10BIT=ON -DLINKED_12BIT=ON
        execute make -j "$MJOBS"
  
        mv libx265.a libx265_main.a
  
        if [[ "$OSTYPE" == "darwin"* ]]; then
          execute "${MACOS_LIBTOOL}" -static -o libx265.a libx265_main.a libx265_main10.a libx265_main12.a 2>/dev/null
          else
            if ! ar -M <<'EOF'
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF
            then
              echo "Failed to create static x265 archive"
              exit 1
            fi
          fi
      else
        rm -rf shared 2>/dev/null
        mkdir -p shared
        cd shared || exit
        execute cmake ../../../source -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" -DENABLE_SHARED=ON -DBUILD_SHARED_LIBS=ON -DENABLE_CLI=OFF
        execute make -j "$MJOBS"
      fi
  
      execute make install
  
      if [ -n "$LDEXEFLAGS" ]; then
        sed -i.backup 's/-lgcc_s/-lgcc_eh/g' "${WORKSPACE}/lib/pkgconfig/x265.pc" # The -i.backup is intended and required on MacOS: https://stackoverflow.com/questions/5694228/sed-in-place-flag-that-works-both-on-mac-bsd-and-linux
      fi
  
      build_done "x265" $CURRENT_PACKAGE_VERSION
    fi
    CONFIGURE_OPTIONS+=("--enable-libx265")
  fi
  
  if build "libvpx" "1.16.0"; then
    download "https://github.com/webmproject/libvpx/archive/refs/tags/v$CURRENT_PACKAGE_VERSION.tar.gz" "libvpx-$CURRENT_PACKAGE_VERSION.tar.gz"
  
    if [[ "$OSTYPE" == "darwin"* ]]; then
      echo "Applying Darwin patch"
      sed "s/,--version-script//g" build/make/Makefile >build/make/Makefile.patched
      sed "s/-Wl,--no-undefined -Wl,-soname/-Wl,-undefined,error -Wl,-install_name/g" build/make/Makefile.patched >build/make/Makefile
    fi
  
    execute ./configure --prefix="${WORKSPACE}" --disable-unit-tests "${LIB_LINK_FLAGS[@]}" --disable-examples --as=yasm --enable-vp9-highbitdepth
    execute make -j "$MJOBS"
    execute make install
  
    build_done "libvpx" $CURRENT_PACKAGE_VERSION
  fi
  CONFIGURE_OPTIONS+=("--enable-libvpx")
  
  if $NONFREE_AND_GPL; then
    if build "xvidcore" "1.3.7"; then
      download "https://downloads.xvid.com/downloads/xvidcore-$CURRENT_PACKAGE_VERSION.tar.gz"
      cd build/generic || exit
      execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
      execute make -j "$MJOBS"
      execute make install
  
      if [[ -f ${WORKSPACE}/lib/libxvidcore.4.dylib ]]; then
        execute rm "${WORKSPACE}/lib/libxvidcore.4.dylib"
      fi
  
      if [[ -f ${WORKSPACE}/lib/libxvidcore.so ]]; then
        execute rm "${WORKSPACE}"/lib/libxvidcore.so*
      fi
  
      build_done "xvidcore" $CURRENT_PACKAGE_VERSION
    fi
    CONFIGURE_OPTIONS+=("--enable-libxvid")
  fi
  
  if $NONFREE_AND_GPL; then
    if build "vid_stab" "1.1.1"; then
      download "https://github.com/georgmartius/vid.stab/archive/v$CURRENT_PACKAGE_VERSION.tar.gz" "vid.stab-$CURRENT_PACKAGE_VERSION.tar.gz"
  
      if $MACOS_SILICON; then
        PATCH_URL="https://raw.githubusercontent.com/Homebrew/formula-patches/5bf1a0e0cfe666ee410305cece9c9c755641bfdf/libvidstab/fix_cmake_quoting.patch"
        PATCH_FILE="$PACKAGES/vid.stab-$CURRENT_PACKAGE_VERSION/fix_cmake_quoting.patch"
  
        MAX_RETRIES=2
        RETRY_COUNT=0
        SUCCESS=false
  
        while [ $RETRY_COUNT -le $MAX_RETRIES ]; do
          if [ $RETRY_COUNT -gt 0 ]; then
            echo "Retrying patch download (attempt $((RETRY_COUNT + 1))/$((MAX_RETRIES + 1))) in 10 seconds..."
            sleep 10
          fi
  
          curl -L --silent -o "$PATCH_FILE" "$PATCH_URL"
          if [ $? -eq 0 ] && [ -s "$PATCH_FILE" ]; then
            SUCCESS=true
            break
          fi
          RETRY_COUNT=$((RETRY_COUNT + 1))
        done
  
        if [ "$SUCCESS" = false ]; then
          echo "Failed to download patch from $PATCH_URL"
          exit 1
        fi
  
        patch -p1 <fix_cmake_quoting.patch
      fi
  
      execute cmake "$CMAKE_BUILD_SHARED_LIBS" -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" -DUSE_OMP=OFF "$CMAKE_ENABLE_SHARED" .
      execute make
      execute make install
  
      build_done "vid_stab" $CURRENT_PACKAGE_VERSION
    fi
    CONFIGURE_OPTIONS+=("--enable-libvidstab")
  fi
  
  if build "av1" "3.12.0"; then
    download "https://aomedia.googlesource.com/aom/+archive/refs/tags/v$CURRENT_PACKAGE_VERSION.tar.gz" "av1-$CURRENT_PACKAGE_VERSION.tar.gz" "av1"
    make_dir "$PACKAGES"/aom_build
    cd "$PACKAGES"/aom_build || exit
    if $MACOS_SILICON; then
      execute cmake -DENABLE_TESTS=0 -DENABLE_EXAMPLES=0 -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" -DCMAKE_INSTALL_LIBDIR=lib -DCONFIG_RUNTIME_CPU_DETECT=0 "$PACKAGES"/av1
    else
      execute cmake -DENABLE_TESTS=0 -DENABLE_EXAMPLES=0 -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" -DCMAKE_INSTALL_LIBDIR=lib "$PACKAGES"/av1
    fi
    execute make -j "$MJOBS"
    execute make install
  
    build_done "av1" $CURRENT_PACKAGE_VERSION
  fi
  CONFIGURE_OPTIONS+=("--enable-libaom")
  
  if build "zimg" "3.0.6"; then
    download "https://github.com/sekrit-twc/zimg/archive/refs/tags/release-$CURRENT_PACKAGE_VERSION.tar.gz" "zimg-$CURRENT_PACKAGE_VERSION.tar.gz" "zimg"
    cd zimg-release-$CURRENT_PACKAGE_VERSION || exit
    execute "${WORKSPACE}/bin/libtoolize" -i -f -q
    execute ./autogen.sh --prefix="${WORKSPACE}"
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
    execute make -j "$MJOBS"
    execute make install
    build_done "zimg" $CURRENT_PACKAGE_VERSION
  fi
  CONFIGURE_OPTIONS+=("--enable-libzimg")
  
}
