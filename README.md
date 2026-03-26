# FFmpeg Static Build Script

This repository builds FFmpeg with a static-first policy on Linux and a best-effort static policy on macOS.

The project is modularized, while keeping the same top-level entry command:

```bash
./build-ffmpeg --build
```

## Migration Status

This section is intentionally log-free and focused on progress visibility.

- Overall migration: 92%  [##################--]
- Phase A (core modularization): 100%  [####################]
- Phase B (mandatory libs + dependency split): 100%  [####################]
- Final orchestration polish: 80%  [################----]
- Documentation sync: 95%  [###################-]

### Module Coverage

- Config modules: 2/2
- Utility modules: 5/5
- Component modules: 10/10
- Thin wrapper: done
- Monolith usage in runtime path: removed

### What Is Done

- Thin wrapper entrypoint: `build-ffmpeg` -> `src/main.sh`
- Dependency pipeline split into themed modules
- Mandatory dependency stage isolated and enforced
- Final FFmpeg stage split into atomic functions
- Platform/version/defaults extraction completed

### What Remains

- Minor cleanup and consistency pass
- Optional deprecation messaging cleanup for compatibility flags

## Current Build Policy

- GPL and non-free are always enabled.
- Mandatory libraries: libfdk-aac, libvmaf, libsoxr.
- Hardware acceleration is enabled where platform/toolchain support is available.
- Vulkan is enabled.
- OpenCL is enabled.
- Apple VideoToolbox is enabled on macOS.
- AMF is removed.

The option `--enable-gpl-and-non-free` is kept only for CLI compatibility and acts as a no-op because these flags are always enabled.

## Requirements

### Linux (typical)

```bash
sudo apt install build-essential curl
```

Optional but recommended for broader codec/hwaccel coverage:

- python3, pip3
- meson, ninja
- cargo
- pkg-config

### macOS

- Xcode Command Line Tools
- curl
- python3
- meson and ninja (required for mandatory libvmaf)

## Quick Start

```bash
git clone https://github.com/possible947/ffmpeg-static-build.git
cd ffmpeg-static-build
./build-ffmpeg --build
```

Output folders:

- packages
- workspace

Built binaries:

- workspace/bin/ffmpeg
- workspace/bin/ffprobe
- workspace/bin/ffplay

## CLI

```text
Usage: build-ffmpeg [OPTIONS]
Options:
  -h, --help                     Display usage information
      --version                  Display version information
  -b, --build                    Starts the build process
      --enable-gpl-and-non-free  Compatibility option (GPL/non-free are already always enabled)
      --disable-lv2              Disable LV2 libraries
  -c, --cleanup                  Remove all working dirs
      --latest                   Build latest version of dependencies if newer available
      --small                    Prioritize small size; disable docs/manpages
      --full-static              Compatibility option (static-first is already the default)
      --skip-install             Do not install binaries to system paths
      --auto-install             Install binaries to system paths without prompt
```

## Hardware Acceleration Notes

- NVIDIA NVENC/NVDEC/CUVID is enabled when CUDA toolchain is detected.
- VAAPI is enabled when libva is available.
- Vulkan support is enabled, including glslang integration where available.
- OpenCL support is enabled through OpenCL headers and ICD loader.
- VideoToolbox is enabled on macOS.

## Mandatory Dependency Behavior

Build fails early if mandatory dependencies cannot be satisfied.

For libvmaf specifically, python3, meson, and ninja are required.

## Project Structure

For a detailed architecture and per-module responsibilities, see:

- DEVELOPER_README.md
