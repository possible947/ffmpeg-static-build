#!/bin/bash

build_ffmpeg_and_install() {
  ## FFmpeg
  ##
  
  EXTRA_VERSION=""
  if [[ "$OSTYPE" == "darwin"* ]]; then
    EXTRA_VERSION="${FFMPEG_VERSION}"
  fi
  
  if [ -d "$CWD/.git" ]; then
    echo -e "\nTemporarily moving .git dir to .git.bak to workaround ffmpeg build bug" #causing ffmpeg version number to be wrong
    mv "$CWD/.git" "$CWD/.git.bak"
    # if build fails below, .git will remain in the wrong place...
  fi
  
  build "ffmpeg" "$FFMPEG_VERSION"
  download "https://github.com/FFmpeg/FFmpeg/archive/refs/tags/n$FFMPEG_VERSION.tar.gz" "FFmpeg-release-$FFMPEG_VERSION.tar.gz"
  # shellcheck disable=SC2086
  
  if $FULL_STATIC; then
    execute ./configure "${CONFIGURE_OPTIONS[@]}" \
      --disable-debug \
      --disable-shared \
      --enable-pthreads \
      --enable-static \
      --enable-version3 \
      --extra-cflags="${CFLAGS}" \
      --extra-ldexeflags="${LDEXEFLAGS}" \
      --extra-ldflags="${LDFLAGS}" \
      --extra-libs="${EXTRALIBS}" \
      --pkgconfigdir="$WORKSPACE/lib/pkgconfig" \
      --pkg-config-flags="--static" \
      --prefix="${WORKSPACE}" \
      --extra-version="${EXTRA_VERSION}"
  else
    execute ./configure "${CONFIGURE_OPTIONS[@]}" \
      --disable-debug \
      --enable-shared \
      --enable-pthreads \
      --disable-static \
      --enable-version3 \
      --extra-cflags="${CFLAGS}" \
      --extra-ldflags="${LDFLAGS}" \
      --extra-libs="${EXTRALIBS}" \
      --pkgconfigdir="$WORKSPACE/lib/pkgconfig" \
      --prefix="${WORKSPACE}" \
      --extra-version="${EXTRA_VERSION}"
  fi
  
  execute make -j "$MJOBS"
  execute make install
  
  if [ -d "$CWD/.git.bak" ]; then
    mv "$CWD/.git.bak" "$CWD/.git"
  fi
  
  INSTALL_FOLDER="/usr"  # not recommended, overwrites system ffmpeg package
  if [[ "$OSTYPE" == "darwin"* ]]; then
    INSTALL_FOLDER="/usr/local"
  else
    if [ -d "$HOME/.local" ]; then  # systemd-standard user path
      INSTALL_FOLDER="$HOME/.local"
    elif [ -d "/usr/local" ]; then
      INSTALL_FOLDER="/usr/local"
    fi
  fi
  
  verify_binary_type
  
  echo ""
  echo "Building done. The following binaries can be found here:"
  echo "- ffmpeg: $WORKSPACE/bin/ffmpeg"
  echo "- ffprobe: $WORKSPACE/bin/ffprobe"
  echo "- ffplay: $WORKSPACE/bin/ffplay"
  echo ""
  
  INSTALL_NOW=0
  if [[ "$AUTOINSTALL" == "yes" ]]; then
    INSTALL_NOW=1
    echo "Automatically installing these binaries because the --auto-install option was used or AUTOINSTALL=yes was run."
  elif [[ ! "$SKIPINSTALL" == "yes" ]]; then
    read -r -p "Install these binaries to your $INSTALL_FOLDER folder? Existing binaries will be replaced. [Y/n] " response
    case $response in
      "" | [yY][eE][sS] | [yY])
        INSTALL_NOW=1
      ;;
    esac
  else
    echo "Skipping install of these binaries because the --skip-install option was used or SKIPINSTALL=yes was run."
  fi
  
  if [ "$INSTALL_NOW" = 1 ]; then
    if command_exists "sudo" && [[ $INSTALL_FOLDER == /usr* ]]; then
      SUDO=sudo
    fi
    $SUDO cp "$WORKSPACE/bin/ffmpeg" "$INSTALL_FOLDER/bin/ffmpeg"
    $SUDO cp "$WORKSPACE/bin/ffprobe" "$INSTALL_FOLDER/bin/ffprobe"
    $SUDO cp "$WORKSPACE/bin/ffplay" "$INSTALL_FOLDER/bin/ffplay"
    if [ $MANPAGES = 1 ]; then
      $SUDO mkdir -p "$INSTALL_FOLDER/share/man/man1"
      $SUDO cp "$WORKSPACE/share/man/man1"/ff* "$INSTALL_FOLDER/share/man/man1"
      if command_exists "mandb"; then
        $SUDO mandb -q
      fi
    fi
    echo "Done. FFmpeg is now installed to your system."
  fi
  
  return 0
}
