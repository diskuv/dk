#!/bin/sh
set -euf
_winehome=$(dirname "$0")
_winehome=$(cd "$_winehome/.." && pwd)

usage() {
    echo "Usage: enter-wine.sh [--init] WINEPREFIX <Windows command> [args...]"
    echo "  --init: initialize the Wine prefix with 'wineboot --init'"
    echo "  --winehome DIR: set the path for Wine installation. default assumes this script is <winehome>/bin/enter-wine.sh"
    echo "  --gnutls-libdir DIR: set the path for gnutls libraries. default is from build machine"
    echo "  --inotify-libdir DIR: set the path for inotify libraries. default is from build machine"
    echo "  --krb5-libdir DIR: set the path for krb5 libraries. default is from build machine"
    exit 1
}

# Parse options
_init=false
_gnutls_libdir='@GNUTLS_LIBDIR@'
_inotify_libdir='@INOTIFY_LIBDIR@'
_krb5_libdir='@KRB5_LIBDIR@'
while [ "$#" -gt 0 ]; do
    case "$1" in
        --init)
            _init=true
            shift
            ;;
        --winehome)
            _winehome="$2"
            shift 2
            ;;
        --gnutls-libdir)
            _gnutls_libdir="$2"
            shift 2
            ;;
        --inotify-libdir)
            _inotify_libdir="$2"
            shift 2
            ;;
        --krb5-libdir)
            _krb5_libdir="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            break
            ;;
    esac
done
if [ "$#" -lt 1 ]; then
    usage
fi
_wineprefix="$1"
shift

# Make absolute path WINEPREFIX. Create directory if it doesn't exist.
_wineprefix=$(install -d "$_wineprefix" && cd "$_wineprefix" && pwd)
export WINEPREFIX="$_wineprefix"

# Any shared libraries that are given to ./configure must be available at runtime
# using DYLD_FALLBACK_LIBRARY_PATH:
#   GNUTLS_LIBDIR: @GNUTLS_LIBDIR@
#   INOTIFY_LIBDIR: @INOTIFY_LIBDIR@
#   KRB5_LIBDIR: @KRB5_LIBDIR@
#
# If you want X11, the path for X11 libraries needs to be here as well.
# macOS X11: Confer https://gitlab.winehq.org/wine/wine/-/wikis/MacOS-FAQ#how-to-launch-wine-from-terminal-instead-of-the-wine-application
export DYLD_FALLBACK_LIBRARY_PATH="$_gnutls_libdir:$_inotify_libdir:$_krb5_libdir:/usr/lib"

# Disable the Wine Mono installer popup.
# confer https://gitlab.winehq.org/wine/wine/-/wikis/Wine-User's-Guide#winedlloverrides-dll-overrides
export WINEDLLOVERRIDES=mscoree=

# --init: Initialize the Wine prefix
if [ "$_init" = true ]; then
    exec "$_winehome/bin/wineboot" --init
fi

# otherwise: execute Wine
exec "$_winehome/bin/wine" "$@"
