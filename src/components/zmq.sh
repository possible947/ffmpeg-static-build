#!/bin/bash

build_zmq_components() {
  ##
  ## zmq library
  ##
  
  if build "libzmq" "4.3.5"; then
    download "https://github.com/zeromq/libzmq/releases/download/v$CURRENT_PACKAGE_VERSION/zeromq-$CURRENT_PACKAGE_VERSION.tar.gz"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      export XML_CATALOG_FILES=/usr/local/etc/xml/catalog 
    fi
    execute ./configure --prefix="${WORKSPACE}" "${LIB_LINK_FLAGS[@]}"
    sed "s/stats_proxy stats = {0}/stats_proxy stats = {{{0, 0}, {0, 0}}, {{0, 0}, {0, 0}}}/g" src/proxy.cpp >src/proxy.cpp.patched
    rm src/proxy.cpp
    mv src/proxy.cpp.patched src/proxy.cpp
    execute make -j "$MJOBS"
    execute make install
    build_done "libzmq" $CURRENT_PACKAGE_VERSION
    CONFIGURE_OPTIONS+=("--enable-libzmq")
  fi
  
}
