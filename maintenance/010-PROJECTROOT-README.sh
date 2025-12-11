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

# Hack dk0 2.4.2.12 until 2.4.2.13 is built
# if [ -x ../dksdk-coder/_build/default/ext/MlFront/src/MlFront_Exec/Shell.exe ]; then
#     echo "SECURITY WARNING: Using local build of dk0" >&2
#     install -v ../dksdk-coder/_build/default/ext/MlFront/src/MlFront_Exec/Shell.exe "$LOCALAPPDATA/Programs/dk0/dk0exe-2.4.2.12-windows_x86_64/mlfshell.exe"
# fi

rm -rf dksrc/
rm -rf 7zip-project/
install -d 7zip-project
set +f
install docs/7zip-tutorial/* 7zip-project/
set -f

CMD=
if [ -n "${COMSPEC:-}" ]; then
    CMD=.cmd
fi

# dksrc/dk0$CMD -- get-object DkSetup_Std.Exe@2.4.202508302258-signed -s Release.Windows_x86_64 -d target/

# nit: Why doesn't CRLF work with ocaml-mdx?
if [ -n "${COMSPEC:-}" ]; then
    dos2unix README.md
fi

if [ -n "${COMSPEC:-}" ]; then
    # ensure dk cache is populated
    ./dk$CMD --version

    install -d target/dkexe
    printf '#!/bin/sh\nexec "%s" "$@"\n' "$LOCALAPPDATA/Programs/DkCoder/dkexe-2.4.202508302258-signed-windows_x86_64/dk.exe" > target/dkexe/dk
    chmod +x target/dkexe/dk
    export PATH="$PWD/target/dkexe:$PATH"
fi

opam exec -- ocaml-mdx test -v -v -o README.corrected.md README.md

install README.md "target/README.$(date +%s).md"
mv README.corrected.md README.md
