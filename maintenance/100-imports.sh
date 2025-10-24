#!/bin/sh

# Windows:
#   winget install dk
#   dk Ml.Use -- .\maintenance\100-imports.sh

set -euf

rm -rf dk0/
git clone https://github.com/diskuv/dk.git dk0

# Import GitHub-attested artifacts
dk0/mlfront-shell -- import-github-l2 --repo jonahbeckford/dk --tag 2.4.202510100005 --outdir etc/dk/i/
