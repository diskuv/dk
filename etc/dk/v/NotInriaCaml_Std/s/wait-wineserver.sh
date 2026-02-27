#!/bin/sh
set -euf

# Inspiration from:
# https://github.com/mstorsjo/msvc-wine/blob/32b504c63b869681cda6824a20e30b74cb718432/Dockerfile#L8-L11

## LICENSE.txt
# The msvc-wine project - the scripts for downloading and setting up the
# toolchain - is licensed under the ISC license.
#
# This license only covers the scripts themselves. In particular, it does
# not conver the downloaded and installed tools.
#
# The ISC license:
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
##

usage() {
    echo "Usage: wait-wineserver.sh [--max-seconds N]" >&2
    exit 1
}

_maxsecs=10
while [ "$#" -gt 0 ]; do
    case "$1" in
        --max-seconds)
            _maxsecs="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# Loop no more than _maxsecs times
i=0
while pgrep -x wineserver && [ $i -lt "$_maxsecs" ]; do
    sleep 1
    i=$((i + 1))
done

# If exceeds _maxsecs times then fail.
if pgrep -x wineserver; then
    echo "Processes with 'wine' in the name:" >&2
    pgrep -f -l wine >&2
    echo "FATAL: wineserver still running after $_maxsecs seconds" >&2
    exit 1
fi
