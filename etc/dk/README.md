# etc/dk

`etc/dk/v` are values to build for the current distribution package.

`etc/dk/i` are remotely downloadable (importable) values **from** the distribution.
For the `github.com/diskuv/dk.git` project in particular, the `etc/dk/i` **is** the system include directory.

Use `-nosysinc -I etc/dk/v` in CI to build the package.

After CI has built the package, use:

1. `dksrc/dk0 import-github-l2 --repo jonahbeckford/dk --tag 2.4.202510100005 --outdir etc/dk/i/` (etc.)
2. `-isystem etc/dk/i` to test the imported values
