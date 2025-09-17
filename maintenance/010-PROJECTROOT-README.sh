#!/bin/sh

# Windows:
#   winget install dk
#   dk Ml.Use -- .\maintenance\010-PROJECTROOT-README.sh

# Tasks to convert into `dk`
#   Why? This script is hacky working on Windows; dogfooding; letting others get useful packages
#
# - [ ] Create a values.json for `mdx` binary.
# - [ ] Complete the values.json for `git` binary. Use it to fetch MDX source code and all MDX dependencies.
# - [ ] Create a values.json for `dune` binary.
# - [ ] Create a values.json for relocatable OCaml (<https://discuss.ocaml.org/t/volunteers-to-review-the-relocatable-ocaml-work/16667/7>)

set -euf

cd "$(dirname "$0")/.."

# Follow steps in https://github.com/realworldocaml/mdx ...
opam show mdx || opam install mdx

# Hack for mlfront-shell until 2.4.2.5 is built
# if [ -x ../dksdk-coder/_build/default/ext/MlFront/src/MlFront_Exec/Shell.exe ]; then
#     echo "SECURITY WARNING: Using local build of mlfront-shell" >&2
#     install -v ../dksdk-coder/_build/default/ext/MlFront/src/MlFront_Exec/Shell.exe "$LOCALAPPDATA/Programs/mlfront-shell/mlfront-shellexe-2.4.2.4-windows_x86_64/mlfshell.exe"
# fi

rm -rf dk0/

# CMD=
# if [ -n "${COMSPEC:-}" ]; then
#     CMD=.cmd
# fi
# dkx/mlfront-shell$CMD -- get-object DkSetup_Std.Exe@2.4.202508302258-signed -s File.Windows_x86_64 -d target/

# nit: Why doesn't CRLF work with ocaml-mdx?
if [ -n "${COMSPEC:-}" ]; then
    dos2unix README.md
fi

opam exec -- ocaml-mdx test -v -v -o README.corrected.md README.md
