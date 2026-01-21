#!/bin/sh
set -euf

# shellcheck disable=SC2154
echo "
=============
build-llvm.sh
=============
.
------
Inputs
------
CMAKE_EXE=${CMAKE_EXE:-}
FILTER_TARGETS=${FILTER_TARGETS:-0}
TARGET_LLD=${TARGET_LLD:-0}
TARGET_LLVMLIBS=${TARGET_LLVMLIBS:-0}
DKSDK_LLVM_BUILD_TYPE=${DKSDK_LLVM_BUILD_TYPE:-Release}
LLVM_USE_LINKER=${LLVM_USE_LINKER:-}
ZLIB_LIBRARY=${ZLIB_LIBRARY:-}
ZSTD_LIBRARY=${ZSTD_LIBRARY:-}
ZSTD_INCLUDE_DIR=${ZSTD_INCLUDE_DIR:-}
LIBXML2_LIBRARY=${LIBXML2_LIBRARY:-}
LIBXML2_INCLUDE_DIR=${LIBXML2_INCLUDE_DIR:-}
LibXml2_ROOT=${LibXml2_ROOT:-}
zstd_DIR=${zstd_DIR:-}
.
------
Matrix
------
DKML_TARGET_ABI=$DKML_TARGET_ABI
.
"

if [ -z "${CMAKE_EXE:-}" ] || [ ! -x "$CMAKE_EXE" ]; then
      echo "CMAKE_EXE is required and must be executable" >&2
      exit 3
fi

CMAKE_C_FLAGS=
CMAKE_CXX_FLAGS=
LLVM_BUILD_32_BITS=OFF
CMAKE_CUSTOM_ARGS= # Use for arguments where LLVM interprets an empty string as different from the default
case "$DKML_TARGET_ABI" in
      linux_x86)
            # Avoid the following:
            #   [3/7] Performing configure step for 'runtimes'
            #   Not searching for unused variables given on the command line.
            #   -- Building with -fPIC
            #   -- Building 32 bits executables and libraries.
            #   -- LLVM host triple: x86_64-unknown-linux-gnu
            #   -- LLVM default target triple: x86_64-unknown-linux-gnu
            #   CMake Error at /builds/diskuv/distributions/1.0/dksdk-llvm/build/llvm-project-19.1.3.src/libunwind/CMakeLists.txt:36 (message):
            #     LIBUNWIND_BUILD_32_BITS is not supported anymore when building the
            #     runtimes, please specify a full triple instead.
            #   CMake Error at /builds/diskuv/distributions/1.0/dksdk-llvm/build/llvm-project-19.1.3.src/libcxxabi/CMakeLists.txt:75 (message):
            #     LIBCXXABI_BUILD_32_BITS is not supported anymore when building the
            #     runtimes, please specify a full triple instead.            
            #   CMake Error at /builds/diskuv/distributions/1.0/dksdk-llvm/build/llvm-project-19.1.3.src/libcxx/CMakeLists.txt:75 (message):
            #     LIBCXX_BUILD_32_BITS is not supported anymore when building the
            #     runtimes, please specify a full triple instead.            
            CMAKE_CUSTOM_ARGS="$CMAKE_CUSTOM_ARGS -DLLVM_HOST_TRIPLE=i386-linux-gnu -DLLVM_DEFAULT_TARGET_TRIPLE=i386-linux-gnu -DLIBUNWIND_BUILD_32_BITS=OFF -DLIBCXXABI_BUILD_32_BITS=OFF -DLIBCXX_BUILD_32_BITS=OFF"
            # The correct LLVM way to inject -m32 compiler flags to all LLVM subprojects
            LLVM_BUILD_32_BITS=ON
            # But non-LLVM code that is compiled inside LLVM ... like try_compile() for LibXml2
            # to search for the `xmlReadMemory` symbol ... need the -m32 flag.
            CMAKE_C_FLAGS=-m32
            CMAKE_CXX_FLAGS=-m32
            ;;
      darwin_arm64)
            export CMAKE_APPLE_SILICON_PROCESSOR=arm64 ;;
      darwin_x86_64)
            export CMAKE_APPLE_SILICON_PROCESSOR=x86_64 ;;
esac

# Settings for the LLD binary or the LLVM libraries
LLVM_STATIC_LINK_CXX_STDLIB=OFF
LLVM_USE_STATIC_ZSTD=ON
LLVM_ENABLE_RUNTIMES=
CMAKE_EXE_LINKER_FLAGS=
CMAKE_FIND_LIBRARY_SUFFIXES=
BUILDING_LLD=0
case "${FILTER_TARGETS:-0},${TARGET_LLD:-0}" in
    1,1)
      BUILDING_LLD=1
      BUILD_DIR="build/lld-$DKML_TARGET_ABI"
      INSTALL_DIR="$PWD/build/lld-install"
      LLVM_ENABLE_PROJECTS="lld"
      if [ -e /lib/ld-musl-x86_64.so.1 ] || [ -e /lib/ld-musl-i386.so.1 ]; then
            LLVM_STATIC_LINK_CXX_STDLIB=ON
            CMAKE_EXE_LINKER_FLAGS=-static
            CMAKE_FIND_LIBRARY_SUFFIXES=.a
            echo "Building fully-static LLD using the musl C library"
      fi ;;
    *)
      BUILD_DIR="build/llvm-$DKML_TARGET_ABI"
      INSTALL_DIR="$PWD/build/llvm-install"
      LLVM_ENABLE_PROJECTS="clang" # clang is required to build the runtimes below
      LLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;compiler-rt"
esac

#     libxml2 does not get found in standard paths in llvm as empty variables
if [ -n "${LIBXML2_INCLUDE_DIR:-}" ]; then
      CMAKE_CUSTOM_ARGS="$CMAKE_CUSTOM_ARGS -DLIBXML2_INCLUDE_DIR=$LIBXML2_INCLUDE_DIR"
fi
if [ -n "${LIBXML2_LIBRARY:-}" ]; then
      CMAKE_CUSTOM_ARGS="$CMAKE_CUSTOM_ARGS -DLIBXML2_LIBRARY=$LIBXML2_LIBRARY"
fi

if [ -n "${NINJA_EXE:-}" ] && [ -x "$NINJA_EXE" ]; then
      CMAKE_GENERATOR="Ninja"
      CMAKE_MAKE_PROGRAM="$NINJA_EXE"
else
      echo "NINJA_EXE is required and must be executable" >&2
      exit 3
fi

# get llvm-project
install -d build
if [ -n "${LLVM_PROJECT_TAR:-}" ] && [ -f "$LLVM_PROJECT_TAR" ]; then
      cp -f "$LLVM_PROJECT_TAR" build/llvm-project.tar.xz
fi
[ -s build/llvm-project.tar.xz ] || curl -Lo build/llvm-project.tar.xz https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.3/llvm-project-19.1.3.src.tar.xz
#   llvm-project-19.1.3.src/utils/bazel/vulkan_sdk.bzl is last file in tarball
[ -s build/llvm-project-19.1.3.src/utils/bazel/vulkan_sdk.bzl ] || tar -x -J -f build/llvm-project.tar.xz -C build

# -or:
#   git clone https://github.com/llvm/llvm-project.git
#   git -C llvm-project reset --hard ab51eccf88f5321e7c60591c5546b254b6afab99 # 19.1.3

install -d build
#   Overall instructions at: https://lld.llvm.org/#build
#   lit: From llvm19-test-utils; cf. https://pkgs.alpinelinux.org/contents?file=lit&path=&name=&branch=edge&repo=main&arch=x86_64
#   CMAKE_EXE_LINKER_FLAGS, CMAKE_FIND_LIBRARY_SUFFIXES: static executables; cf. https://stackoverflow.com/a/24671474
#   LLVM_STATIC_LINK_CXX_STDLIB: https://llvm.org/docs/CMake.html
#   LLVM_USE_LINKER=lld: In Debug builds this will eat RAM (exceeds 20GB) without lld as the linker.
#     But conanio the lld is too old. Caller should set it appropriately.
if [ -n "${LLVM_USE_LINKER:-}" ]; then
      run_cmake() {
                  "$CMAKE_EXE" "$@" "-DLLVM_USE_LINKER=${LLVM_USE_LINKER:-}"
      }
elif [ "$BUILDING_LLD" = "0" ] && [ -x "$PWD/build/lld-$DKML_TARGET_ABI/bin/lld" ]; then # Re-use from a prior LLD build
      run_cmake() {
                  "$CMAKE_EXE" "$@" "-DLLVM_USE_LINKER=$PWD/build/lld-$DKML_TARGET_ABI/bin/lld"
      }
else
      run_cmake() {
                  "$CMAKE_EXE" "$@"
      }
fi
set -x
#     CMAKE_FIND_PACKAGE_PREFER_CONFIG=true so we can supply our own cmake configs like libxml2 for Alpine
#     shellcheck disable=SC2086
run_cmake -G "$CMAKE_GENERATOR" -S build/llvm-project-19.1.3.src/llvm \
      -B "$BUILD_DIR" \
      "-DCMAKE_MAKE_PROGRAM=$CMAKE_MAKE_PROGRAM" \
      "-DCMAKE_BUILD_TYPE=${DKSDK_LLVM_BUILD_TYPE:-Release}" \
      -DCMAKE_EXE_LINKER_FLAGS=$CMAKE_EXE_LINKER_FLAGS \
      -DCMAKE_FIND_LIBRARY_SUFFIXES=$CMAKE_FIND_LIBRARY_SUFFIXES \
      "-DCMAKE_C_FLAGS=$CMAKE_C_FLAGS" \
      "-DCMAKE_CXX_FLAGS=$CMAKE_CXX_FLAGS" \
      "-DLLVM_BUILD_32_BITS=$LLVM_BUILD_32_BITS" \
      -DLLVM_USE_STATIC_ZSTD=$LLVM_USE_STATIC_ZSTD \
      "-DZLIB_LIBRARY=${ZLIB_LIBRARY:-}" \
      "-Dzstd_INCLUDE_DIR=${ZSTD_INCLUDE_DIR:-}" \
      "-Dzstd_STATIC_LIBRARY=${ZSTD_LIBRARY:-}" \
      -DLLVM_ENABLE_LIBXML2=FORCE_ON \
      -DLLVM_STATIC_LINK_CXX_STDLIB=$LLVM_STATIC_LINK_CXX_STDLIB \
      -DLLVM_ENABLE_PROJECTS=$LLVM_ENABLE_PROJECTS \
      "-DLLVM_ENABLE_RUNTIMES=$LLVM_ENABLE_RUNTIMES" \
      -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
      -DCMAKE_FIND_PACKAGE_PREFER_CONFIG=true \
      $CMAKE_CUSTOM_ARGS --debug-find-pkg=zstd
      # --trace-expand --trace-redirect=ci/build.log
set +x

# Diagnostics
echo "
===========
Diagnostics
===========
"
grep -B1 'TRIPLE:STRING' "$BUILD_DIR/CMakeCache.txt"
echo
grep ' DEFINES =' "$BUILD_DIR/build.ninja" | sort | uniq -c | sort -k1nr  | head -n1
grep ' FLAGS =' "$BUILD_DIR/build.ninja" | sort | uniq -c | sort -k1nr  | head -n1
echo "
.
"

# We get failures around the AMDGPU target ... indeterminate. Retrying seems to fix it.
# May be due to OOM reaper: https://forums.gentoo.org/viewtopic-p-8824165.html?sid=7e7cd06c3347d67094fc049ceced94e0
if ! "$CMAKE_EXE" --build "$BUILD_DIR"; then
      echo "=================" >&2
      echo "Retry 1st attempt" >&2
      echo "=================" >&2
      if ! "$CMAKE_EXE" --build "$BUILD_DIR"; then
            echo "=================" >&2
            echo "Retry 2nd attempt" >&2
            echo "=================" >&2
            "$CMAKE_EXE" --build "$BUILD_DIR"
      fi
fi

"$CMAKE_EXE" --install "$BUILD_DIR"

# Diagnostics
case "${FILTER_TARGETS:-0},${TARGET_LLD:-0}" in
    1,1)
      file "$BUILD_DIR/bin/lld"

      # fail if lld not statically linked on Linux
      case "$DKML_TARGET_ABI" in
            linux_*)
                  set +x
                  file "$BUILD_DIR/bin/lld" | grep "statically linked" > /dev/null
                  set -x
      esac
esac
