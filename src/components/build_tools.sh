#!/bin/bash

build_build_tools() {
  ##
  ## build tools
  ##
  
  if build "giflib" "5.2.2"; then
    download "https://sf-eu-introserv-1.dl.sourceforge.net/project/giflib/giflib-5.x/giflib-$CURRENT_PACKAGE_VERSION.tar.gz"
    cd "${PACKAGES}"/giflib-$CURRENT_PACKAGE_VERSION || exit
    #building docs fails if the tools needed are not installed
    #there is no option to not build the docs on Linux, we need to modify the Makefile
    sed 's/$(MAKE) -C doc//g' Makefile >Makefile.patched
    rm Makefile
    sed 's/install: all install-bin install-include install-lib install-man/install: all install-bin install-include install-lib/g' Makefile.patched >Makefile
    #multicore build disabled for this library
    execute make
    execute make PREFIX="${WORKSPACE}" install
    build_done "giflib" $CURRENT_PACKAGE_VERSION
  fi
  
  if build "pkg-config" "0.29.2"; then
    download "https://pkgconfig.freedesktop.org/releases/pkg-config-$CURRENT_PACKAGE_VERSION.tar.gz"
    if [[ "$OSTYPE" == "darwin"* ]]; then
    	CFLAGS+=" -Wno-int-conversion" # pkg-config 0.29.2 has a warning that is treated as an error
    	CFLAGS+=" -Wno-error=int-conversion"
    	export CFLAGS
    fi
    execute ./configure --silent --prefix="${WORKSPACE}" --with-pc-path="${WORKSPACE}"/lib/pkgconfig --with-internal-glib
    execute make -j "$MJOBS"
    execute make install
    build_done "pkg-config" $CURRENT_PACKAGE_VERSION
  fi
  
  if build "yasm" "1.3.0"; then
    download "https://github.com/yasm/yasm/releases/download/v$CURRENT_PACKAGE_VERSION/yasm-$CURRENT_PACKAGE_VERSION.tar.gz"
    execute ./configure --prefix="${WORKSPACE}"
    execute make -j "$MJOBS"
    execute make install
    build_done "yasm" $CURRENT_PACKAGE_VERSION
  fi
  
  if build "nasm" "3.01"; then
    download "https://www.nasm.us/pub/nasm/releasebuilds/$CURRENT_PACKAGE_VERSION/nasm-$CURRENT_PACKAGE_VERSION.tar.xz"
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
    execute make -j "$MJOBS"
    execute make install
    build_done "nasm" $CURRENT_PACKAGE_VERSION
  fi
  
  if build "zlib" "1.3.2"; then
    download "https://github.com/madler/zlib/releases/download/v$CURRENT_PACKAGE_VERSION/zlib-$CURRENT_PACKAGE_VERSION.tar.gz"
    if $FULL_STATIC; then
      execute ./configure --static --prefix="${WORKSPACE}"
    else
      execute ./configure --prefix="${WORKSPACE}"
    fi
    execute make -j "$MJOBS"
    execute make install
    build_done "zlib" $CURRENT_PACKAGE_VERSION
  fi
  
  if build "m4" "1.4.20"; then
    download "https://ftpmirror.gnu.org/gnu/m4/m4-$CURRENT_PACKAGE_VERSION.tar.gz"
    execute ./configure --prefix="${WORKSPACE}"
    execute make -j "$MJOBS"
    execute make install
    build_done "m4" $CURRENT_PACKAGE_VERSION
  fi
  
  if build "autoconf" "2.72"; then
    download "https://ftpmirror.gnu.org/gnu/autoconf/autoconf-$CURRENT_PACKAGE_VERSION.tar.gz"
    execute ./configure --prefix="${WORKSPACE}"
    execute make -j "$MJOBS"
    execute make install
    build_done "autoconf" $CURRENT_PACKAGE_VERSION
  fi
  
  if build "automake" "1.18.1"; then
    download "https://ftpmirror.gnu.org/gnu/automake/automake-$CURRENT_PACKAGE_VERSION.tar.gz"
    execute ./configure --prefix="${WORKSPACE}"
    execute make -j "$MJOBS"
    execute make install
    build_done "automake" $CURRENT_PACKAGE_VERSION
  fi
  
  if build "libtool" "2.5.4"; then
    download "https://ftpmirror.gnu.org/libtool/libtool-$CURRENT_PACKAGE_VERSION.tar.gz"
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
    execute make -j "$MJOBS"
    execute make install
    build_done "libtool" $CURRENT_PACKAGE_VERSION
  fi
  
  if $NONFREE_AND_GPL; then
    if build "gettext" "1.0"; then
      download "https://ftpmirror.gnu.org/gettext/gettext-$CURRENT_PACKAGE_VERSION.tar.gz"
      execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
      execute make -j "$MJOBS"
      execute make install
      build_done "gettext" $CURRENT_PACKAGE_VERSION
    fi
  
    if build "openssl" "3.6.1"; then
      download "https://github.com/openssl/openssl/archive/refs/tags/openssl-$CURRENT_PACKAGE_VERSION.tar.gz" "openssl-$CURRENT_PACKAGE_VERSION.tar.gz"
      execute ./Configure --prefix="${WORKSPACE}" --openssldir="${WORKSPACE}" --libdir="lib" --with-zlib-include="${WORKSPACE}"/include/ --with-zlib-lib="${WORKSPACE}"/lib "$OPENSSL_LINK_FLAG" zlib
      execute make -j "$MJOBS"
      execute make install_sw
      build_done "openssl" $CURRENT_PACKAGE_VERSION
    fi
    CONFIGURE_OPTIONS+=("--enable-openssl")
  else
    if build "gmp" "6.3.0"; then
      download "https://ftpmirror.gnu.org/gnu/gmp/gmp-$CURRENT_PACKAGE_VERSION.tar.xz"
      execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
      execute make -j "$MJOBS"
      execute make install
      build_done "gmp" $CURRENT_PACKAGE_VERSION
    fi
  
    if build "nettle" "3.10.2"; then
      download "https://ftpmirror.gnu.org/gnu/nettle/nettle-$CURRENT_PACKAGE_VERSION.tar.gz"
      execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}" --disable-openssl --disable-documentation --libdir="${WORKSPACE}"/lib CPPFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
      execute make -j "$MJOBS"
      execute make install
      build_done "nettle" $CURRENT_PACKAGE_VERSION
    fi
  
    if [[ ! $ARCH == 'arm64' ]]; then
      if build "gnutls" "3.8.12"; then
        download "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-$CURRENT_PACKAGE_VERSION.tar.xz"
        execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}" --disable-doc --disable-tools --disable-cxx --disable-tests --disable-gtk-doc-html --disable-libdane --disable-nls --enable-local-libopts --disable-guile --with-included-libtasn1 --with-included-unistring --without-p11-kit CPPFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
        execute make -j "$MJOBS"
        execute make install
        build_done "gnutls" $CURRENT_PACKAGE_VERSION
      fi
      # CONFIGURE_OPTIONS+=("--enable-gmp" "--enable-gnutls")
    fi
  fi
  
  if build "cmake" "4.2.3"; then
    CXXFLAGS_BACKUP=$CXXFLAGS
    export CXXFLAGS+=" -std=c++11"
    download "https://github.com/Kitware/CMake/releases/download/v$CURRENT_PACKAGE_VERSION/cmake-$CURRENT_PACKAGE_VERSION.tar.gz"
    execute ./configure --prefix="${WORKSPACE}" --parallel="${MJOBS}" -- -DCMAKE_USE_OPENSSL=OFF
    execute make -j "$MJOBS"
    execute make install
    build_done "cmake" $CURRENT_PACKAGE_VERSION
    export CXXFLAGS=$CXXFLAGS_BACKUP
  fi

  # Phase B: mandatory libraries are built before optional groups.
  build_mandatory_components
}
