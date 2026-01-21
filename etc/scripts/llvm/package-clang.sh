#!/bin/sh
set -euf

CODEGEN_DIR=$1
OUT_DIR=$2

install -d "$OUT_DIR/bin" "$OUT_DIR/lib"

# clang binaries
if [ -e "$CODEGEN_DIR/bin/clang" ]; then
  cp -L "$CODEGEN_DIR/bin/clang" "$OUT_DIR/bin/"
fi
if [ -e "$CODEGEN_DIR/bin/clang++" ]; then
  cp -L "$CODEGEN_DIR/bin/clang++" "$OUT_DIR/bin/"
fi
if [ -e "$CODEGEN_DIR/bin/clang-cpp" ]; then
  cp -L "$CODEGEN_DIR/bin/clang-cpp" "$OUT_DIR/bin/"
fi
if [ -e "$CODEGEN_DIR/bin/clang-cl.exe" ]; then
  cp -L "$CODEGEN_DIR/bin/clang-cl.exe" "$OUT_DIR/bin/"
fi
if [ -e "$CODEGEN_DIR/bin/clang.exe" ]; then
  cp -L "$CODEGEN_DIR/bin/clang.exe" "$OUT_DIR/bin/"
fi
if [ -e "$CODEGEN_DIR/bin/clang++.exe" ]; then
  cp -L "$CODEGEN_DIR/bin/clang++.exe" "$OUT_DIR/bin/"
fi

# clang resource directory (builtin headers, runtimes)
if [ -d "$CODEGEN_DIR/lib/clang" ]; then
  mkdir -p "$OUT_DIR/lib"
  cp -R "$CODEGEN_DIR/lib/clang" "$OUT_DIR/lib/"
fi

# shared libraries (if present)
if [ -d "$CODEGEN_DIR/lib" ]; then
  find "$CODEGEN_DIR/lib" -maxdepth 1 -type f \( -name 'libclang*.so*' -o -name 'libLLVM*.so*' -o -name 'libclang*.dylib' -o -name 'libLLVM*.dylib' \) -exec cp -L {} "$OUT_DIR/lib/" \;
fi

# Windows DLLs
if [ -d "$CODEGEN_DIR/bin" ]; then
  find "$CODEGEN_DIR/bin" -maxdepth 1 -type f -name '*.dll' -exec cp -L {} "$OUT_DIR/bin/" \;
fi
