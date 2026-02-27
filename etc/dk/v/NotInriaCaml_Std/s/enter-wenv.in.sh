#!/bin/sh
set -euf

usage() {
    case "$0" in
        */enter) echo "Usage: '$0' <Windows command> [args...]" ;;
        *)       echo "Usage: <wenv>/bin/enter <Windows command> [args...]" ;;
    esac
    exit 1
}

# Parse options
if [ "$#" -lt 1 ]; then
    usage
fi

# Set defaults for Wine debug messages. Exclude fixme:file
WINEDEBUG=${WINEDEBUG:-"-vulkan,fixme-file"}

exec '@WINEHOME@/bin/enter-wine.sh' \
    --winehome '@WINEHOME@' \
    --gnutls-libdir '@GNUTLS_LIBDIR@' \
    --inotify-libdir '@INOTIFY_LIBDIR@' \
    --krb5-libdir '@KRB5_LIBDIR@' \
    '@WINEPREFIX@' "$@"
