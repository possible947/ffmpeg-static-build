# FFmpeg Build Script Migration Plan (Updated Requirements)

## 1. Scope
Current `build-ffmpeg` is a monolithic Bash script and must be split into modules.

This migration is no longer a pure "behavior-preserving" refactor. It must enforce the following product requirements:
1. Modular architecture (script split into maintainable parts).
2. Build the most static FFmpeg possible for the current platform.
3. Always include `libfdk-aac`, `libvmaf`, `libsoxr`.
4. Enable all hardware decoders/encoders available on the platform.
5. Always enable Vulkan support.
6. Always enable OpenCL support.
7. Always enable GPL and non-free components.

## 2. Hard Requirements
1. `--enable-gpl` and `--enable-nonfree` are always active.
2. `libfdk-aac`, `libvmaf`, and `libsoxr` are mandatory dependencies.
3. Hardware acceleration is auto-enabled by platform capability detection (CUDA/NVENC/NVDEC/CUVID, VAAPI, Apple VideoToolbox, etc.).
4. Vulkan is mandatory (`--enable-vulkan`).
5. OpenCL is mandatory (`--enable-opencl`).
6. Build mode target is "maximally static for platform":
	- Linux: prefer full static where technically possible.
	- macOS: static where possible, but allow required dynamic/system linkage.
7. Missing mandatory dependency is a hard error (build must fail with clear message).
8. Shared build mode is not a target path. Build logic is static-first only.
9. No "built-mode" validation is needed (no static vs shared cache split checks).

## 3. Non-Goals
1. Do not keep legacy behavior where it conflicts with hard requirements above.
2. Do not keep optional switches for now-mandatory features (`gpl/nonfree`, required libs).

## 4. Target Structure
```
├── src/
│   ├── config/
│   │   ├── defaults.sh        # versions, defaults, global constants
│   │   ├── flags.sh           # derived static-first/toolchain flags
│   │   └── options.sh         # CLI parsing (reduced: no optional gpl/nonfree)
│   ├── utils/
│   │   ├── exec.sh            # execute(), logging of command output
│   │   ├── download.sh        # download(), extract(), retry handling
│   │   ├── state.sh           # rebuild policy and lightweight lock handling
│   │   ├── platform.sh        # platform detection and capability checks
│   │   └── output.sh          # usage(), summary, error formatting
│   ├── components/
│   │   ├── mandatory/
│   │   │   ├── libfdk_aac.sh
│   │   │   ├── libvmaf.sh
│   │   │   └── libsoxr.sh
│   │   ├── hwaccel/
│   │   │   ├── vulkan.sh
│   │   │   ├── opencl.sh
│   │   │   ├── cuda.sh
│   │   │   ├── vaapi.sh
│   │   │   └── videotoolbox.sh
│   │   ├── codecs/            # x264, x265, svtav1, dav1d, etc.
│   │   ├── audio/
│   │   ├── video/
│   │   ├── image/
│   │   └── ffmpeg.sh          # final FFmpeg configure/build/install
│   └── main.sh                # full orchestration order
├── build-ffmpeg               # thin compatibility wrapper
└── plan.md
```

## 5. Design Rules
1. Preserve build order semantics explicitly in `main.sh`.
2. Components expose one function each: `build_<component_name>`.
3. Components are responsible for appending their own FFmpeg flags only on success.
4. Mandatory components must call `fail` on any unavailable dependency.
5. Hardware components are best-effort only if platform does not provide toolchain/device SDK.
6. Apple VideoToolbox is explicitly enabled on macOS targets.
7. Centralize configure flags in arrays to avoid quoting regressions.
8. Remove mode-based cache logic; do not check "built as shared/static" state.
9. FFmpeg final target is always rebuilt after dependency stage completion.

## 6. Migration Phases
1. Phase A: Extract utilities and configuration without changing build order.
2. Phase B: Move mandatory libs first (`libfdk-aac`, `libvmaf`, `libsoxr`) and enforce hard-fail behavior.
3. Phase C: Move hardware stack modules and capability detection.
4. Phase D: Move remaining codec/audio/video/image modules.
5. Phase E: Final FFmpeg module + wrapper conversion.

## 7. Validation Matrix
1. Linux static target:
	- FFmpeg configure includes nonfree/gpl, vulkan, opencl, and mandatory libs.
	- Hardware flags are enabled when dependencies are detected.
2. Linux fallback target:
	- If full static is impossible for a platform library, build continues in most-static valid mode and reports fallback.
3. macOS target:
	- Build succeeds with best possible static linkage and required features.
	- VideoToolbox is explicitly enabled in FFmpeg configure on supported Apple platforms.
4. Rebuild behavior:
	- Re-run after a clean state must rebuild mandatory dependencies and FFmpeg without any mode comparison checks.

## 8. Acceptance Criteria
1. Monolith is replaced by modular structure under `src/`.
2. Wrapper `build-ffmpeg` delegates to `src/main.sh`.
3. Final FFmpeg configure always contains:
	- `--enable-gpl`
	- `--enable-nonfree`
	- `--enable-libfdk-aac`
	- `--enable-libvmaf`
	- `--enable-libsoxr`
	- `--enable-vulkan`
	- `--enable-opencl`
4. Build fails if mandatory libs cannot be built.
5. Platform-available hardware encoder/decoder support is enabled automatically.
6. Apple VideoToolbox support is explicitly enabled on macOS.
7. No shared/static mode check exists in build-state logic.
8. FFmpeg build stage always executes after dependency resolution.

## 9. Immediate Implementation Notes
1. Remove optional behavior for GPL/non-free from CLI parsing.
2. Keep `--full-static` intent but make static-first behavior default.
3. Keep backward-compatible entry command (`./build-ffmpeg ...`).
4. Add concise failure diagnostics for mandatory component failures.
5. Replace lock-file format and checks that depend on build mode.
6. Keep cache policy simple: rebuild what is required, then always build FFmpeg.
7. Add explicit macOS branch for `--enable-videotoolbox` in final FFmpeg configure options.
