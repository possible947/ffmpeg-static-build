#!/bin/bash

build_image_components() {
  ##
  ## image library
  ##
  
  if build "libtiff" "4.7.1"; then
    download "https://download.osgeo.org/libtiff/tiff-$CURRENT_PACKAGE_VERSION.tar.xz"
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}" --disable-dependency-tracking --disable-lzma --disable-webp --disable-zstd --without-x
    execute make -j "$MJOBS"
    execute make install
    build_done "libtiff" $CURRENT_PACKAGE_VERSION
  fi
  if build "libpng" "1.6.55"; then
    download "https://sourceforge.net/projects/libpng/files/libpng16/$CURRENT_PACKAGE_VERSION/libpng-$CURRENT_PACKAGE_VERSION.tar.gz" "libpng-$CURRENT_PACKAGE_VERSION.tar.gz"
    export LDFLAGS="${LDFLAGS}"
    export CPPFLAGS="${CFLAGS}"
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
    execute make -j "$MJOBS"
    execute make install
    build_done "libpng" $CURRENT_PACKAGE_VERSION
  fi
  
  if build "lcms2" "2.18"; then
    download "https://github.com/mm2/Little-CMS/releases/download/lcms$CURRENT_PACKAGE_VERSION/lcms2-$CURRENT_PACKAGE_VERSION.tar.gz"
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
    execute make -j "$MJOBS"
    execute make install
    build_done "lcms2" $CURRENT_PACKAGE_VERSION
  fi
  
  if build "libjxl" "0.11.2"; then
    download "https://github.com/libjxl/libjxl/archive/refs/tags/v$CURRENT_PACKAGE_VERSION.tar.gz" "libjxl-$CURRENT_PACKAGE_VERSION.tar.gz"
  # currently needed to fix linking of static builds in non-C++ applications
    sed "s/-ljxl_threads/-ljxl_threads @JPEGXL_THREADS_PUBLIC_LIBS@/g" lib/threads/libjxl_threads.pc.in >lib/threads/libjxl_threads.pc.in.patched
    rm lib/threads/libjxl_threads.pc.in
    mv lib/threads/libjxl_threads.pc.in.patched lib/threads/libjxl_threads.pc.in
    sed 's/set(JPEGXL_REQUIRES_TYPE "Requires")/set(JPEGXL_REQUIRES_TYPE "Requires")\'$'\n''  set(JPEGXL_THREADS_PUBLIC_LIBS "-lm ${PKGCONFIG_CXX_LIB}")/g' lib/jxl_threads.cmake >lib/jxl_threads.cmake.patched
    rm lib/jxl_threads.cmake
    mv lib/jxl_threads.cmake.patched lib/jxl_threads.cmake
    execute ./deps.sh
    execute cmake "$CMAKE_BUILD_SHARED_LIBS" -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_BINDIR=bin -DCMAKE_INSTALL_INCLUDEDIR=include "$CMAKE_ENABLE_SHARED" "$CMAKE_ENABLE_STATIC" -DCMAKE_BUILD_TYPE=Release -DJPEGXL_ENABLE_BENCHMARK=OFF -DJPEGXL_ENABLE_DOXYGEN=OFF -DJPEGXL_ENABLE_MANPAGES=OFF -DJPEGXL_ENABLE_JPEGLI_LIBJPEG=OFF -DJPEGXL_ENABLE_JPEGLI=ON -DJPEGXL_TEST_TOOLS=OFF -DJPEGXL_ENABLE_JNI=OFF -DBUILD_TESTING=OFF -DJPEGXL_ENABLE_SKCMS=OFF .
    execute make -j "$MJOBS"
    execute make install
    build_done "libjxl" $CURRENT_PACKAGE_VERSION
  fi
  CONFIGURE_OPTIONS+=("--enable-libjxl")
  EXTRALIBS="${EXTRALIBS} -llcms2"
  
  if build "libwebp" "1.6.0"; then
    # libwebp can fail to compile on Ubuntu if these flags were left set to CFLAGS
    CPPFLAGS=
    download "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$CURRENT_PACKAGE_VERSION.tar.gz" "libwebp-$CURRENT_PACKAGE_VERSION.tar.gz"
    make_dir build
    cd build || exit
    execute cmake -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_BINDIR=bin -DCMAKE_INSTALL_INCLUDEDIR=include "$CMAKE_ENABLE_SHARED" "$CMAKE_ENABLE_STATIC" -DWEBP_BUILD_CWEBP=OFF -DWEBP_BUILD_DWEBP=OFF -DWEBP_BUILD_GIF2WEBP=OFF -DWEBP_BUILD_IMG2WEBP=OFF -DWEBP_BUILD_VWEBP=OFF ../
    execute make -j "$MJOBS"
    execute make install
  
    build_done "libwebp" $CURRENT_PACKAGE_VERSION
  fi
  
  # In some environments libwebp may be present only as a static archive.
  # FFmpeg's libwebp check then needs libsharpyuv explicitly.
  if [[ -f "${WORKSPACE}/lib/libwebp.a" && ! -f "${WORKSPACE}/lib/libwebp.so" ]]; then
    EXTRALIBS+=" -lsharpyuv"
  fi
  
  CONFIGURE_OPTIONS+=("--enable-libwebp")
  
}
