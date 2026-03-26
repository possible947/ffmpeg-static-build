#!/bin/bash

source "$ROOT_DIR/src/components/build_tools.sh"
source "$ROOT_DIR/src/components/video.sh"
source "$ROOT_DIR/src/components/audio.sh"
source "$ROOT_DIR/src/components/image.sh"
source "$ROOT_DIR/src/components/other.sh"
source "$ROOT_DIR/src/components/zmq.sh"
source "$ROOT_DIR/src/components/hwaccel.sh"

build_dependencies() {
  build_build_tools

  # Phase B: mandatory libraries are built before optional groups.
  build_mandatory_components

  build_video_components
  build_audio_components
  build_image_components
  build_other_components
  build_zmq_components
  build_hwaccel_components
}
