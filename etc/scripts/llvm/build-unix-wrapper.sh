#!/bin/sh
set -euf

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Inputs
#   CMAKE_EXE
#   ZSTD_TAR_GZ
#   LIBXML2_TAR_XZ
#   LLVM_PROJECT_TAR
#   LLVM_DEV_TAR (macOS)
#   DKML_TARGET_ABI
#   NINJA_EXE
#   CODEGEN_DIR (optional)
#   PACKAGE_CLANG_OUT (optional)

# Set project directory
PROJECT_DIR=$PWD

# Get `cmake` to work on Unix
if [ -n "${CMAKE_EXE:-}" ] && [ -e "$CMAKE_EXE" ] && [ ! -x "$CMAKE_EXE" ]; then
  chmod +x "$CMAKE_EXE"
fi

# Get `cmake` to work on macOS
CMAKE_APP_DIR=
if [ -n "${CMAKE_EXE:-}" ] && command -v xattr >/dev/null 2>&1; then
  CMAKE_EXE_DIR=$(dirname "$CMAKE_EXE")
  if [ -d "$CMAKE_EXE_DIR/../.." ]; then
    CMAKE_APP_DIR=$(cd "$CMAKE_EXE_DIR/../.." && pwd)
    xattr -dr com.apple.quarantine "$CMAKE_APP_DIR" >/dev/null 2>&1 || true
  fi
  xattr -dr com.apple.quarantine "$CMAKE_EXE" >/dev/null 2>&1 || true
fi
case "$DKML_TARGET_ABI" in
  darwin_*)
    if command -v codesign >/dev/null 2>&1; then
      if [ -n "${CMAKE_APP_DIR:-}" ]; then
        codesign --force --deep --sign - "$CMAKE_APP_DIR" >/dev/null 2>&1 || true
      elif [ -n "${CMAKE_EXE:-}" ]; then
        codesign --force --sign - "$CMAKE_EXE" >/dev/null 2>&1 || true
      fi
    fi
    ;;
esac

if [ -z "${CMAKE_EXE:-}" ] || [ ! -x "$CMAKE_EXE" ]; then
  echo "CMAKE_EXE is required and must be executable" >&2
  exit 3
fi
CMAKE_EXE=$(cd "$(dirname "$CMAKE_EXE")" && pwd)/$(basename "$CMAKE_EXE")
export CMAKE_EXE

build_zstd() {
  zstd_src=build/zstd-1.5.7
  if [ ! -d "$zstd_src" ]; then
    install -d build
    tar xCfz build "$ZSTD_TAR_GZ"
  fi
  case "$DKML_TARGET_ABI" in
    darwin_*)
      "$CMAKE_EXE" -B build/zstd-build-$DKML_TARGET_ABI -S "$zstd_src/build/cmake" \
        -D ZSTD_BUILD_STATIC=ON -D ZSTD_BUILD_SHARED=OFF
      "$CMAKE_EXE" --build build/zstd-build-$DKML_TARGET_ABI
      "$CMAKE_EXE" --install build/zstd-build-$DKML_TARGET_ABI --prefix build/zstd-install
      export zstd_DIR="$PROJECT_DIR/build/zstd-install"
      ;;
    linux_*)
      make -C "$zstd_src"
      export ZSTD_LIBRARY="$PROJECT_DIR/$zstd_src/lib/libzstd.a"
      export ZSTD_INCLUDE_DIR="$PROJECT_DIR/$zstd_src/lib"
      ;;
  esac
}

build_libxml2() {
  libxml2_src=build/libxml2-2.14.2
  if [ ! -d "$libxml2_src" ]; then
    install -d build
    tar xCfJ build "$LIBXML2_TAR_XZ"
  fi
  case "$DKML_TARGET_ABI" in
    darwin_*)
      # macOS uses SDK libxml2, no build required
      ;;
    linux_*)
      cd "$libxml2_src"
      env "CFLAGS=${LIBXML2_CFLAGS:-}" ./configure --prefix "$PROJECT_DIR/build/libxml2-install" --enable-static --enable-shared=no --with-iconv=no --with-python=no
      make
      make install
      cd "$PROJECT_DIR"
      export LIBXML2_INCLUDE_DIR="$PROJECT_DIR/build/libxml2-install/include/libxml2"
      export LIBXML2_LIBRARY="$PROJECT_DIR/build/libxml2-install/lib/libxml2.a"
      ;;
  esac
}

if [ -n "${ZSTD_TAR_GZ:-}" ]; then
  build_zstd
fi
if [ -n "${LIBXML2_TAR_XZ:-}" ]; then
  build_libxml2
fi

if [ -n "${NINJA_EXE:-}" ] && [ -e "$NINJA_EXE" ] && [ ! -x "$NINJA_EXE" ]; then
  chmod +x "$NINJA_EXE"
fi
if [ -n "${NINJA_EXE:-}" ] && command -v xattr >/dev/null 2>&1; then
  xattr -dr com.apple.quarantine "$NINJA_EXE" >/dev/null 2>&1 || true
fi
case "$DKML_TARGET_ABI" in
  darwin_*)
    if [ -n "${NINJA_EXE:-}" ] && command -v codesign >/dev/null 2>&1; then
      codesign --force --sign - "$NINJA_EXE" >/dev/null 2>&1 || true
    fi
    ;;
esac
if [ -z "${NINJA_EXE:-}" ] || [ ! -x "$NINJA_EXE" ]; then
  echo "NINJA_EXE is required and must be executable" >&2
  exit 3
fi
NINJA_EXE=$(cd "$(dirname "$NINJA_EXE")" && pwd)/$(basename "$NINJA_EXE")
export NINJA_EXE

export LLVM_PROJECT_TAR
export LLVM_DEV_TAR

sh "$SCRIPT_DIR/build-unix-inside.sh"

if [ -n "${PACKAGE_CLANG_OUT:-}" ]; then
  codegen_dir=${CODEGEN_DIR:-"codegen/$DKML_TARGET_ABI"}
  sh "$SCRIPT_DIR/package-clang.sh" "$codegen_dir" "$PACKAGE_CLANG_OUT"
fi
