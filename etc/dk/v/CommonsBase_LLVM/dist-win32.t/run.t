Distribution for CommonsBase_LLVM

# These are not yet ready to be built ... they use precommands instead of subshells and they don't use the CommonsBase_Build package for CMake0.
# Release.Windows_x86_64:CommonsBase_LLVM.Clang@19.1.3
# Release.Windows_x86:CommonsBase_LLVM.Clang@19.1.3

--- Objects and Assets ---

CommonsBase_LLVM.Toolchain.MinGW is split into smaller parts (win32, etc.) because:
- each part must not exceed 2GB (which is GitHub's file size limit)
- the Unix tarballs have symlinks that can't be handled by 7z on Windows

  $ get-object CommonsBase_LLVM.Toolchain.MinGW@21.1.8+rev-20251216 -s Release.Windows_x86_64 -f ${RUNTIME}/Windows_x86_64-Toolchain.MinGW-21.1.8+rev-20251216.zip
  [pass] object:oq3nxfnjwe7grbcsgjatyw6llayfn5dzeprrn5ggrtixc3dgsp4zq:CommonsBase_LLVM.Toolchain.MinGW@21.1.8+rev-20251216
  $ get-object CommonsBase_LLVM.Toolchain.MinGW@21.1.8+rev-20251216 -s Release.Windows_x86 -f ${RUNTIME}/Windows_x86-Toolchain.MinGW-21.1.8+rev-20251216.zip
  [pass] object:oxgjgpjitb5i3ky5dsbdh35cpoaokzmznklgxt5snnddt2ejdtxka:CommonsBase_LLVM.Toolchain.MinGW@21.1.8+rev-20251216
