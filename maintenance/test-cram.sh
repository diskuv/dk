#!/bin/sh

# Windows:
#   winget install dk
#   dk Ml.Use -- .\maintenance\test-cram.sh

set -euf

usage() {
    printf 'usage: maintenance/test-cram.sh [-w] [-a]\n'
    printf '  -w: watch mode\n'
    printf '  -a: auto promote\n'
    printf '  -S: no sandbox mode\n'
    exit 2
}
watch=0
autopromote=0
sandbox=1
while getopts 'waSh' c
do
    case $c in
        w) watch=1 ;;
        a) autopromote=1 ;;
        S) sandbox=0 ;;
        h|?) usage
    esac
done
shift $((OPTIND-1))

extra=
if [ $watch -eq 1 ]; then extra="-w $extra"; fi
if [ $autopromote -eq 1 ]; then extra="--auto-promote $extra"; fi
if [ $sandbox -eq 0 ]; then extra="--sandbox=none $extra"; fi

cd "$(dirname "$0")/.."

opam show dune || opam install dune

# Clone dk source. First step in README.md.
rm -rf dksrc/
git clone --branch V2_5 https://github.com/diskuv/dk.git dksrc

# Make dk0 available in PATH
export PATH="$PWD/dksrc:$PATH"

# Symlink etc/dk/v
rm -f tests/cram/etc
ln -s "$PWD/etc" tests/cram/etc

# Run cram tests using dune
#   shellcheck disable=SC2086
opam exec -- dune test --root tests/cram $extra
