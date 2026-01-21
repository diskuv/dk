#!/bin/sh

# Prereq 1
#   The caller is responsible for cleaning the codegen/ directory as needed.
#   This script does not clean the codegen/ since at least one mode (FILTER_TARGETS=1,
#   especially when developing on desktop from dksdk-coder) we want the LLDB + LLVM to accumulate.

# This script:
#  Is meant to be inside a Docker container (like dockcross) instead of using cmdrun/opamrun.
#  Can be run on Windows if there is a MSYS2/Cygwin shell available.

set -euf

# Set project directory
if [ -n "${CI_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$CI_PROJECT_DIR"
elif [ -n "${PC_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$PC_PROJECT_DIR"
elif [ -n "${GITHUB_WORKSPACE:-}" ]; then
    PROJECT_DIR="$GITHUB_WORKSPACE"
else
    PROJECT_DIR="$PWD"
fi
if [ -x /usr/bin/cygpath ]; then
    PROJECT_DIR=$(/usr/bin/cygpath -au "$PROJECT_DIR")
fi

# Optional: pre-seeded LLVM source tarball
if [ -n "${LLVM_PROJECT_TAR:-}" ] && [ -f "$LLVM_PROJECT_TAR" ]; then
    install -d build
    cp -f "$LLVM_PROJECT_TAR" build/llvm-project.tar.xz
fi

if [ -z "${CMAKE_EXE:-}" ] || [ ! -x "$CMAKE_EXE" ]; then
    echo "CMAKE_EXE is required and must be executable" >&2
    exit 3
fi

# MACOSX_DEPLOYMENT_TARGET
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
MACOSX_DEPLOYMENT_TARGET=$("$CMAKE_EXE" -D REPORT_MACOSX_VERSION_MIN=1 -P "$SCRIPT_DIR/DkSDKPresets.cmake")
test -n "${MACOSX_DEPLOYMENT_TARGET:-}"
export MACOSX_DEPLOYMENT_TARGET

# shellcheck disable=SC2154
echo "
=============
build-unix-inside.sh
=============
.
------
Matrix
------
DKML_TARGET_ABI=$DKML_TARGET_ABI
.
-------------------------
Constants and Derivatives
-------------------------
MACOSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET
.
"

# Rearrange LLVM installation prefix into a vcpkg-like structure
# for consistency with dksdk-c-packages
llvmprefix_to_vcpkg() {
    llvmprefix_to_vcpkg_PREFIX=$1; shift
    #   note: cmake -E copy[_directory] creates the destination directory
    #   llvm-config
    if [ -e "$llvmprefix_to_vcpkg_PREFIX/bin/llvm-config" ]; then
        install -d "codegen/$DKML_TARGET_ABI/bin"
        "$CMAKE_EXE" -E copy "$llvmprefix_to_vcpkg_PREFIX/bin/llvm-config" "codegen/$DKML_TARGET_ABI/bin/llvm-config"
    fi
    #   clang tools
    if [ -e "$llvmprefix_to_vcpkg_PREFIX/bin/clang" ]; then
        install -d "codegen/$DKML_TARGET_ABI/bin"
        cp -L "$llvmprefix_to_vcpkg_PREFIX/bin/clang" "codegen/$DKML_TARGET_ABI/bin/clang"
    fi
    if [ -e "$llvmprefix_to_vcpkg_PREFIX/bin/clang++" ]; then
        install -d "codegen/$DKML_TARGET_ABI/bin"
        cp -L "$llvmprefix_to_vcpkg_PREFIX/bin/clang++" "codegen/$DKML_TARGET_ABI/bin/clang++"
    fi
    if [ -e "$llvmprefix_to_vcpkg_PREFIX/bin/clang-cpp" ]; then
        install -d "codegen/$DKML_TARGET_ABI/bin"
        cp -L "$llvmprefix_to_vcpkg_PREFIX/bin/clang-cpp" "codegen/$DKML_TARGET_ABI/bin/clang-cpp"
    fi
    #   headers
    if [ -e "$llvmprefix_to_vcpkg_PREFIX/include" ]; then
        "$CMAKE_EXE" -E copy_directory "$llvmprefix_to_vcpkg_PREFIX/include" "codegen/$DKML_TARGET_ABI/include"
    fi
    #   libraries
    if [ -e "$llvmprefix_to_vcpkg_PREFIX/lib" ]; then
        "$CMAKE_EXE" -E copy_directory "$llvmprefix_to_vcpkg_PREFIX/lib" "codegen/$DKML_TARGET_ABI/lib"
    fi
    #   lld (do not copy ld.lld, ld64.lld, lld-link and wasm-ld since just symlinks which are not portable in zipfiles)
    if [ -e "$llvmprefix_to_vcpkg_PREFIX/bin/lld" ]; then
        install -d "codegen/$DKML_TARGET_ABI/tools/lld"
        install "$llvmprefix_to_vcpkg_PREFIX/bin/lld" "codegen/$DKML_TARGET_ABI/tools/lld/"
    fi
    #   Get rid of libFortran, libMLIR. They are huge and not needed
    if [ -e "codegen/$DKML_TARGET_ABI/lib" ]; then
        find "codegen/$DKML_TARGET_ABI/lib" -name 'libFortran*' -exec rm -f {} \;
        find "codegen/$DKML_TARGET_ABI/lib" -name 'libMLIR*' -exec rm -f {} \;
    fi
}

# Install codegen to the staging area codegen/
if [ ! "${CPKG_CODEGEN:-}" = "DISABLE" ]; then
    llvm_dev=build/dl/llvm-dev-$DKML_TARGET_ABI
    llvm=build/dl/llvm-$DKML_TARGET_ABI
    install -d "$llvm" "$llvm_dev"
    install -d codegen
    case "$DKML_TARGET_ABI" in
        darwin_x86_64) llvmname=macOS-X64 ;;
        darwin_arm64) llvmname=macOS-ARM64 ;;
    esac
    case "$DKML_TARGET_ABI" in
        linux_x86|linux_x86_64)
            sh "$SCRIPT_DIR/build-llvm.sh"

            echo "Reorganizing LLD and LLVM installation ..."
            llvmprefix_to_vcpkg build/lld-install
            llvmprefix_to_vcpkg build/llvm-install
            ;;
        darwin_x86_64|darwin_arm64)
            # See PACKAGES.md#LLVM for how to get the URL. 19.1.3 is latest official GPG signed release
            if [ -n "${LLVM_DEV_TAR:-}" ] && [ -f "$LLVM_DEV_TAR" ]; then
                cp -f "$LLVM_DEV_TAR" "$llvm_dev.tar.xz"
            fi
            if [ ! -e "$llvm_dev.tar.xz" ]; then
                DL="https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.3/LLVM-19.1.3-$llvmname.tar.xz"
                echo "Dowloading $DL ..."
                curl -Lo "$llvm_dev.tar.xz" "$DL"
            fi
            echo "Extracting binaries from $llvm_dev.tar.xz ..."
            [ -e "$llvm_dev/LLVM-19.1.3-$llvmname/bin/lld" ] || tar xvCfJ "$llvm_dev" "$PWD/$llvm_dev.tar.xz" "LLVM-19.1.3-$llvmname/bin/lld"
            sh "$SCRIPT_DIR/build-llvm.sh"

            echo "Reorganizing $llvm_dev ..."
            llvmprefix_to_vcpkg "$llvm_dev/LLVM-19.1.3-$llvmname"
            llvmprefix_to_vcpkg build/lld-install
            llvmprefix_to_vcpkg build/llvm-install
            ;;
        *)
            # For other ABIs we could use vcpkg:
            #   ./vcpkg/${vcpkg_exe} install "--Triplet=$DKML_TARGET_ABI" \
            #     "--overlay-ports=$OVERLAY_LOCATION" "--overlay-triplets=$OVERLAY_TRIPLETS" \
            #     --x-feature=codegen --x-install-root=codegen
            echo "There is no support yet for building LLVM on target ABI $DKML_TARGET_ABI" >&2
            exit 3
    esac
fi
