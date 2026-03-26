#!/bin/bash

ffmpeg_require_option() {
  local required="$1"
  local found=false

  for opt in "${CONFIGURE_OPTIONS[@]}"; do
    if [ "$opt" = "$required" ]; then
      found=true
      break
    fi
  done

  if ! $found; then
    echo "Error: required FFmpeg configure option is missing: $required"
    exit 1
  fi
}

verify_required_ffmpeg_options() {
  ffmpeg_require_option "--enable-gpl"
  ffmpeg_require_option "--enable-nonfree"
  ffmpeg_require_option "--enable-libfdk-aac"
  ffmpeg_require_option "--enable-libvmaf"
  ffmpeg_require_option "--enable-libsoxr"
  ffmpeg_require_option "--enable-vulkan"
  ffmpeg_require_option "--enable-opencl"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    ffmpeg_require_option "--enable-videotoolbox"
  fi
}

prepare_ffmpeg_source() {
  if [ -d "$CWD/.git" ]; then
    echo -e "\nTemporarily moving .git dir to .git.bak to workaround ffmpeg build bug"
    mv "$CWD/.git" "$CWD/.git.bak"
  fi

  build "ffmpeg" "$FFMPEG_VERSION"
  download "https://github.com/FFmpeg/FFmpeg/archive/refs/tags/n$FFMPEG_VERSION.tar.gz" "FFmpeg-release-$FFMPEG_VERSION.tar.gz"
}

configure_ffmpeg() {
  local extra_version=""

  if [[ "$OSTYPE" == "darwin"* ]]; then
    extra_version="${FFMPEG_VERSION}"
  fi

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
      --extra-version="${extra_version}"
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
      --extra-version="${extra_version}"
  fi
}

install_ffmpeg_to_system() {
  local install_folder="/usr"
  local install_now=0

  if [[ "$OSTYPE" == "darwin"* ]]; then
    install_folder="/usr/local"
  else
    if [ -d "$HOME/.local" ]; then
      install_folder="$HOME/.local"
    elif [ -d "/usr/local" ]; then
      install_folder="/usr/local"
    fi
  fi

  if [[ "$AUTOINSTALL" == "yes" ]]; then
    install_now=1
    echo "Automatically installing these binaries because the --auto-install option was used or AUTOINSTALL=yes was run."
  elif [[ ! "$SKIPINSTALL" == "yes" ]]; then
    read -r -p "Install these binaries to your $install_folder folder? Existing binaries will be replaced. [Y/n] " response
    case $response in
      "" | [yY][eE][sS] | [yY])
        install_now=1
      ;;
    esac
  else
    echo "Skipping install of these binaries because the --skip-install option was used or SKIPINSTALL=yes was run."
  fi

  if [ "$install_now" = 1 ]; then
    if command_exists "sudo" && [[ $install_folder == /usr* ]]; then
      SUDO=sudo
    fi
    $SUDO cp "$WORKSPACE/bin/ffmpeg" "$install_folder/bin/ffmpeg"
    $SUDO cp "$WORKSPACE/bin/ffprobe" "$install_folder/bin/ffprobe"
    $SUDO cp "$WORKSPACE/bin/ffplay" "$install_folder/bin/ffplay"
    if [ $MANPAGES = 1 ]; then
      $SUDO mkdir -p "$install_folder/share/man/man1"
      $SUDO cp "$WORKSPACE/share/man/man1"/ff* "$install_folder/share/man/man1"
      if command_exists "mandb"; then
        $SUDO mandb -q
      fi
    fi
    echo "Done. FFmpeg is now installed to your system."
  fi
}

build_ffmpeg_and_install() {
  verify_required_ffmpeg_options
  prepare_ffmpeg_source
  configure_ffmpeg

  execute make -j "$MJOBS"
  execute make install

  if [ -d "$CWD/.git.bak" ]; then
    mv "$CWD/.git.bak" "$CWD/.git"
  fi

  verify_binary_type

  echo ""
  echo "Building done. The following binaries can be found here:"
  echo "- ffmpeg: $WORKSPACE/bin/ffmpeg"
  echo "- ffprobe: $WORKSPACE/bin/ffprobe"
  echo "- ffplay: $WORKSPACE/bin/ffplay"
  echo ""

  install_ffmpeg_to_system

  return 0
}
