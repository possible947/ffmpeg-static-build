#!/bin/bash

build_hwaccel_components() {
  ##
  ## HWaccel library
  ##
  
  if build "vulkan-headers" "1.4.341.0"; then
    download "https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/vulkan-sdk-$CURRENT_PACKAGE_VERSION.tar.gz" "Vulkan-Headers-$CURRENT_PACKAGE_VERSION.tar.gz"
    execute cmake -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" -B build/
    cd build/ || exit
    execute make install
    build_done "vulkan-headers" $CURRENT_PACKAGE_VERSION
  fi
  CONFIGURE_OPTIONS+=("--enable-vulkan")
  
  # vulkan filters and some encoders/decorders are implemented using shaders, for those we need a shader compiler
  if command_exists "python3"; then
    if build "glslang" "16.2.0"; then
      download "https://github.com/KhronosGroup/glslang/archive/refs/tags/$CURRENT_PACKAGE_VERSION.tar.gz" "glslang-$CURRENT_PACKAGE_VERSION.tar.gz"
      execute ./update_glslang_sources.py
      # FFmpeg's libglslang check links against component libs like
      # MachineIndependent/GenericCodeGen/SPIRV, which are reliably available
      # when glslang is built as static libraries.
      execute cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_SHARED=OFF -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" .
      execute make -j "$MJOBS"
      execute make install
      build_done "glslang" $CURRENT_PACKAGE_VERSION
    fi
    if [[ -f "${WORKSPACE}/lib/libMachineIndependent.a" && -f "${WORKSPACE}/lib/libGenericCodeGen.a" && -f "${WORKSPACE}/lib/libSPIRV.a" ]]; then
      CONFIGURE_OPTIONS+=("--enable-libglslang")
    else
      echo "glslang component libraries required by FFmpeg were not found. Building FFmpeg without --enable-libglslang."
    fi
  fi
  
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if command_exists "nvcc"; then
      if build "nv-codec" "13.0.19.0"; then
        download "https://github.com/FFmpeg/nv-codec-headers/releases/download/n$CURRENT_PACKAGE_VERSION/nv-codec-headers-$CURRENT_PACKAGE_VERSION.tar.gz"
        execute make PREFIX="${WORKSPACE}"
        execute make PREFIX="${WORKSPACE}" install
        build_done "nv-codec" $CURRENT_PACKAGE_VERSION
      fi
      CFLAGS+=" -I/usr/local/cuda/include"
      LDFLAGS+=" -L/usr/local/cuda/lib64"
      CONFIGURE_OPTIONS+=("--enable-cuda-nvcc" "--enable-cuvid" "--enable-nvdec" "--enable-nvenc" "--enable-cuda-llvm" "--enable-ffnvcodec")
  
      # if [ -z "$LDEXEFLAGS" ]; then
      #   CONFIGURE_OPTIONS+=("--enable-libnpp") # Only libnpp cannot be statically linked.
      # fi
  
      if [ -z "$CUDA_COMPUTE_CAPABILITY" ]; then
        # Set default value if no compute capability was found
        # Note that multi-architecture builds are not supported in ffmpeg
        # see https://patchwork.ffmpeg.org/comment/62905/
        export CUDA_COMPUTE_CAPABILITY=52
      fi
      CONFIGURE_OPTIONS+=("--nvccflags=-gencode arch=compute_$CUDA_COMPUTE_CAPABILITY,code=sm_$CUDA_COMPUTE_CAPABILITY -O2")
    else
      CONFIGURE_OPTIONS+=("--disable-ffnvcodec")
    fi
  
    # Vaapi doesn't work well with static links FFmpeg.
    if [ -z "$LDEXEFLAGS" ]; then
      # If the libva development SDK is installed, enable vaapi.
      if library_exists "libva"; then
        if build "vaapi" "1"; then
          build_done "vaapi" "1"
        fi
        CONFIGURE_OPTIONS+=("--enable-vaapi")
      fi
    fi
  
    if build "opencl-headers" "2025.07.22"; then
      download "https://github.com/KhronosGroup/OpenCL-Headers/archive/refs/tags/v$CURRENT_PACKAGE_VERSION.tar.gz" "OpenCL-Headers-$CURRENT_PACKAGE_VERSION.tar.gz"
      execute cmake -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" -B build/
      execute cmake --build build --target install
      build_done "opencl-headers" $CURRENT_PACKAGE_VERSION
    fi
    if build "opencl-icd-loader" "2025.07.22"; then
      download "https://github.com/KhronosGroup/OpenCL-ICD-Loader/archive/refs/tags/v$CURRENT_PACKAGE_VERSION.tar.gz" "OpenCL-ICD-Loader-$CURRENT_PACKAGE_VERSION.tar.gz"
      execute cmake -DCMAKE_PREFIX_PATH="${WORKSPACE}" -DCMAKE_INSTALL_PREFIX="${WORKSPACE}" "$CMAKE_ENABLE_SHARED" "$CMAKE_BUILD_SHARED_LIBS" -B build/
      execute cmake --build build --target install
      build_done "opencl-icd-loader" $CURRENT_PACKAGE_VERSION
    fi
  fi
  
  CONFIGURE_OPTIONS+=("--enable-opencl")
}
