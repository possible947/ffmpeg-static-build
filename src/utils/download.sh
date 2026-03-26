#!/bin/bash

download() {
  # download url [filename[dirname]]

  DOWNLOAD_PATH="$PACKAGES"
  DOWNLOAD_FILE="${2:-"${1##*/}"}"

  if [[ "$DOWNLOAD_FILE" =~ tar. ]]; then
    TARGETDIR="${DOWNLOAD_FILE%.*}"
    TARGETDIR="${3:-"${TARGETDIR%.*}"}"
  else
    TARGETDIR="${3:-"${DOWNLOAD_FILE%.*}"}"
  fi

  if [ ! -f "$DOWNLOAD_PATH/$DOWNLOAD_FILE" ] || [ ! -s "$DOWNLOAD_PATH/$DOWNLOAD_FILE" ]; then
    echo "Downloading $1 as $DOWNLOAD_FILE"

    MAX_RETRIES=2
    RETRY_COUNT=0
    SUCCESS=false

    while [ $RETRY_COUNT -le $MAX_RETRIES ]; do
      if [ $RETRY_COUNT -gt 0 ]; then
        echo "Retrying download (attempt $((RETRY_COUNT + 1))/$((MAX_RETRIES + 1))) in 10 seconds..."
        sleep 10
      fi

      curl -L --silent -o "$DOWNLOAD_PATH/$DOWNLOAD_FILE" "$1"
      EXITCODE=$?

      if [ $EXITCODE -eq 0 ] && [ -s "$DOWNLOAD_PATH/$DOWNLOAD_FILE" ]; then
        SUCCESS=true
        break
      fi

      echo "Failed to download $1 (Exitcode $EXITCODE or empty file)"
      RETRY_COUNT=$((RETRY_COUNT + 1))
    done

    if [ "$SUCCESS" = false ]; then
      echo "Failed to download $1 after $((MAX_RETRIES + 1)) attempts."
      exit 1
    fi

    echo "... Done"
  else
    echo "$DOWNLOAD_FILE has already been downloaded and is not empty."
  fi

  make_dir "$DOWNLOAD_PATH/$TARGETDIR"

  if [[ "$DOWNLOAD_FILE" == *"patch"* ]]; then
    return
  fi

  if [ -n "$3" ]; then
    if ! tar -xvf "$DOWNLOAD_PATH/$DOWNLOAD_FILE" -C "$DOWNLOAD_PATH/$TARGETDIR" 2>/dev/null >/dev/null; then
      echo "Failed to extract $DOWNLOAD_FILE"
      exit 1
    fi
  else
    if ! tar -xvf "$DOWNLOAD_PATH/$DOWNLOAD_FILE" -C "$DOWNLOAD_PATH/$TARGETDIR" --strip-components 1 2>/dev/null >/dev/null; then
      echo "Failed to extract $DOWNLOAD_FILE"
      exit 1
    fi
  fi

  echo "Extracted $DOWNLOAD_FILE"

  cd "$DOWNLOAD_PATH/$TARGETDIR" || (
    echo "Error has occurred."
    exit 1
  )
}
