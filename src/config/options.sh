#!/bin/bash

parse_cli_options() {
  while (($# > 0)); do
    case $1 in
    -h | --help)
      usage
      exit 0
      ;;
    --version)
      echo "$SCRIPT_VERSION"
      exit 0
      ;;
    -*)
      if [[ "$1" == "--build" || "$1" =~ '-b' ]]; then
        bflag='-b'
      fi
      if [[ "$1" == "--enable-gpl-and-non-free" ]]; then
        echo "Info: GPL/non-free is always enabled; option retained for compatibility."
      fi
      if [[ "$1" == "--disable-lv2" ]]; then
        DISABLE_LV2=true
      fi
      if [[ "$1" == "--cleanup" || "$1" =~ '-c' && ! "$1" =~ '--' ]]; then
        cflag='-c'
        cleanup
      fi
      if [[ "$1" == "--full-static" ]]; then
        echo "Info: static-first mode is the default."
      fi
      if [[ "$1" == "--latest" ]]; then
        LATEST=true
      fi
      if [[ "$1" == "--small" ]]; then
        CONFIGURE_OPTIONS+=("--enable-small" "--disable-doc")
        MANPAGES=0
      fi
      if [[ "$1" == "--skip-install" ]]; then
        SKIPINSTALL=yes
        if [[ "$AUTOINSTALL" == "yes" ]]; then
          echo "Error: The option --skip-install cannot be used with --auto-install"
          exit 1
        fi
      fi
      if [[ "$1" == "--auto-install" ]]; then
        AUTOINSTALL=yes
        if [[ "$SKIPINSTALL" == "yes" ]]; then
          echo "Error: The option --auto-install cannot be used with --skip-install"
          exit 1
        fi
      fi
      shift
      ;;
    *)
      usage
      exit 1
      ;;
    esac
  done

  if [ -z "$bflag" ]; then
    if [ -z "$cflag" ]; then
      usage
      exit 1
    fi
    exit 0
  fi
}
