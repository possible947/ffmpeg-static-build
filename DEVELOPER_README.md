# Developer README

This document describes the current modular architecture and the responsibility of each module.

## Entry flow

1. build-ffmpeg is a thin wrapper.
2. The wrapper executes src/main.sh.
3. src/main.sh initializes defaults, platform context, CLI options, and shared build flags.
4. src/main.sh runs:
   - build_dependencies
   - build_ffmpeg_and_install

## Top-level layout

- src/main.sh
- src/config/
- src/utils/
- src/components/

## src/main.sh

Purpose:
- Runtime orchestration.
- Source all config, utils, and components.
- Initialize default variables and platform/job settings.
- Apply global configure policy (always gpl/nonfree, static-first, platform switches).
- Run dependency and FFmpeg stages.

Key responsibilities:
- Load modules in a deterministic order.
- Prepare common flags and toolchain configuration.
- Run preflight command checks.

## Configuration modules

### src/config/defaults.sh

Function:
- init_defaults

Purpose:
- Central source of default values for:
  - versions
  - workspace paths
  - build flags
  - global toggles

### src/config/options.sh

Function:
- parse_cli_options

Purpose:
- Parse CLI arguments.
- Keep compatibility options while preserving current policy.
- Set user-intent variables such as:
  - bflag
  - cflag
  - LATEST
  - SKIPINSTALL
  - AUTOINSTALL
  - MANPAGES

## Utility modules

### src/utils/common.sh

Functions:
- command_exists
- remove_dir
- make_dir
- print_flags
- execute
- cmake
- cleanup
- usage

Purpose:
- Common command wrappers and generic helper behavior.
- Uniform command execution and failure handling.

### src/utils/download.sh

Function:
- download

Purpose:
- Download source archives with retry support.
- Extract into deterministic directories.
- Handle special archive naming and optional target dirs.

### src/utils/state.sh

Functions:
- build
- build_done
- library_exists

Purpose:
- Lightweight build-state and lockfile behavior.
- Decide whether to skip/rebuild components.
- Track completed component versions.

### src/utils/platform.sh

Functions:
- init_platform_and_jobs
- can_link_lilv

Purpose:
- Detect platform/runtime specifics.
- Configure Apple Silicon details.
- Compute parallel job count.
- Provide LV2/lilv linkability probe.

### src/utils/version.sh

Functions:
- version_gte
- version_satisfies

Purpose:
- Version comparison helpers for future policy/version gates.

## Component modules

### src/components/dependencies.sh

Function:
- build_dependencies

Purpose:
- Dependency pipeline orchestrator.
- Calls themed component stages in fixed order.
- Triggers mandatory dependency stage before optional groups.

Current call order:
1. build_build_tools
2. build_mandatory_components
3. build_video_components
4. build_audio_components
5. build_image_components
6. build_other_components
7. build_zmq_components
8. build_hwaccel_components

### src/components/mandatory.sh

Function:
- build_mandatory_components

Purpose:
- Build and validate mandatory libraries:
  - libvmaf
  - libfdk-aac
  - libsoxr
- Enforce hard-fail behavior if requirements are not met.

Includes:
- pkg-config validation helper for mandatory modules.

### src/components/build_tools.sh

Function:
- build_build_tools

Purpose:
- Build foundational toolchain and support libraries used by later stages.

### src/components/video.sh

Function:
- build_video_components

Purpose:
- Build video-related codec and processing dependencies.

### src/components/audio.sh

Function:
- build_audio_components

Purpose:
- Build audio codec and related dependencies.

### src/components/image.sh

Function:
- build_image_components

Purpose:
- Build image codec/format dependencies used by FFmpeg.

### src/components/other.sh

Function:
- build_other_components

Purpose:
- Build remaining non-video/non-audio/non-image dependencies.

### src/components/zmq.sh

Function:
- build_zmq_components

Purpose:
- Build ZeroMQ dependency and enable related FFmpeg support.

### src/components/hwaccel.sh

Function:
- build_hwaccel_components

Purpose:
- Build and enable hardware-acceleration related dependencies.
- Includes Vulkan/OpenCL and platform-conditional acceleration features.

### src/components/ffmpeg.sh

Functions:
- build_ffmpeg_and_install
- verify_required_ffmpeg_options
- prepare_ffmpeg_source
- configure_ffmpeg
- install_ffmpeg_to_system

Purpose:
- Final FFmpeg configure/build/install stage.
- Validate required configure options before build.
- Handle optional system installation flow.

## Policy summary reflected in code

- Static-first build defaults.
- GPL/non-free always enabled.
- Mandatory libs enforced with hard-fail checks.
- Vulkan and OpenCL enablement included in final FFmpeg flags.
- VideoToolbox enabled on macOS.
- AMF removed.

## Editing guidelines for contributors

- Keep module responsibilities narrow and explicit.
- Prefer adding a focused function in an existing themed module over expanding main.sh.
- Preserve dependency stage order unless there is a clear technical reason to change it.
- Validate with shell syntax checks before committing:

```bash
bash -n build-ffmpeg
bash -n src/main.sh
bash -n src/config/*.sh
bash -n src/utils/*.sh
bash -n src/components/*.sh
```
