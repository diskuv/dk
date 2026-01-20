#!/bin/sh
if [ -x /usr/bin/cygpath ]; then
    DKSRC=$(cygpath -am "dksrc")
else
    DKSRC="$PWD/dksrc"
fi
exec ../dksdk-coder/_build/default/ext/MlFront/src/MlFront_Exec/Shell.exe -isystem "$DKSRC/etc/dk/i" --cell dk0="$DKSRC" "$@"
