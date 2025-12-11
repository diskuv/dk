#!/bin/sh

# Windows:
#   winget install dk
#   dk Ml.Use -- .\maintenance\100-imports.sh

set -euf

rm -rf dk0/
git clone https://github.com/diskuv/dk.git dksrc

# Import GitHub-attested artifacts
dksrc/dk0 -- import-github-l2 --repo diskuv/dk --tag 2.4.202512120000 --outdir etc/dk/i/
