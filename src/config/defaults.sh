#!/bin/bash

init_defaults() {
	FFMPEG_VERSION=8.1
	SCRIPT_VERSION=1.59

	CWD=$(pwd)
	PACKAGES="$CWD/packages"
	WORKSPACE="$CWD/workspace"
	CFLAGS="-I$WORKSPACE/include -Wno-int-conversion"
	LDFLAGS="-L$WORKSPACE/lib"
	LDEXEFLAGS=""
	EXTRALIBS="-ldl -lpthread -lm -lz"

	MACOS_SILICON=false
	FULL_STATIC=true
	CONFIGURE_OPTIONS=()
	NONFREE_AND_GPL=true
	DISABLE_LV2=false
	LATEST=false
	MANPAGES=1
	SKIPRAV1E=${SKIPRAV1E:-yes}
	CURRENT_PACKAGE_VERSION=0
}
