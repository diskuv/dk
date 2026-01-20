#!/bin/sh

# Windows:
#   winget install dk
#   dk Ml.Use -- .\maintenance\100-imports.sh

set -euf

rm -rf dksrc/
git clone https://github.com/diskuv/dk.git dksrc

# Import GitHub-attested artifacts
#   SYNC: 010-PROJECTROOT-README.sh 100-imports.sh
dksrc/dk0 --trial import-github-l2 --repo diskuv/dk --tag 2.5.202601180000 --outdir etc/dk/i/
