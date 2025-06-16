# dk - A script runner and cross-compiler

The main documentation site is <https://diskuv.com/dk/help/latest/>.

## Quick Start

<!-- SYNC: site:src/content/docs/guide/dk-quick-walkthrough.mdoc, dk.git:README.md#quickstart -->

Install on Windows:

```powershell
winget install -e --id Diskuv.dk
```

or Apple/Silicon:

```sh
sudo curl -o /usr/local/bin/dk https://diskuv.com/a/dk-distribution/2.3.202505282324/dk-darwin_arm64
sudo chmod +x /usr/local/bin/dk
```

or Apple/Intel:

```sh
sudo curl -o /usr/local/bin/dk https://diskuv.com/a/dk-distribution/2.3.202505282324/dk-darwin_x86_64
sudo chmod +x /usr/local/bin/dk
```

or Linux with glibc (Debian, Ubuntu, etc. but not Alpine):

```sh
sudo curl -o /usr/local/bin/dk https://diskuv.com/a/dk-distribution/2.3.202505282324/dist/dk-linux_x86_64
sudo chmod +x /usr/local/bin/dk
```

Then cross-compile a script to standalone Windows, Linux, Android executables (and to a macOS executable if you are on a macOS machine):

```sh
dk -g dune -S "
    module Http = DkNet_Std.Http
    module Uri = Tr1Uri_Std.Uri
    let print_endline = Tr1Stdlib_V414Io.StdIo.print_endline
 " -U "
    print_endline @@
    Lwt_main.run @@
    Http.fetch_url ~max_sz:4096 @@
    Uri.of_string {|https://jigsaw.w3.org/HTTP/h-content-md5.html|}
 " -O ReleaseSmall Exe
```

The executables will be available in the `target/` folder:

```sh
file target/ZzZz_Zz.Adhoc-* | cut -c1-69 | awk '{print $0 "..."}'

target/ZzZz_Zz.Adhoc-android_arm32v7a:   ELF 32-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-android_arm64v8a:   ELF 64-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-android_x86_64:     ELF 64-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-darwin_arm64:       Mach-O 64-bit executable arm...
target/ZzZz_Zz.Adhoc-darwin_x86_64:      Mach-O 64-bit executable x86...
target/ZzZz_Zz.Adhoc-linux_x86:          ELF 32-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-linux_x86_64:       ELF 64-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-windows_x86_64.exe: PE32+ executable (console) x...
target/ZzZz_Zz.Adhoc-windows_x86_64.pdb: MSVC program database ver 7....
target/ZzZz_Zz.Adhoc-windows_x86.exe:    PE32 executable (console) In...
target/ZzZz_Zz.Adhoc-windows_x86.pdb:    MSVC program database ver 7....
```

32-bit targets are not ready yet. <https://github.com/diskuv/dk/issues> has the full list of issues.

## Licenses

Copyright 2023 Diskuv, Inc.

The `./dk` and `./dk.cmd` build scripts ("dk") are
available under the Open Software License version 3.0,
<https://opensource.org/license/osl-3-0-php/>.
A guide to the Open Software License version 3.0 is available at
<https://rosenlaw.com/OSL3.0-explained.htm>.

`dk.cmd` downloads parts of the 7-Zip program. 7-Zip is licensed under the GNU LGPL license.
The source code for 7-Zip can be found at <www.7-zip.org>. Attribute requirements are available at <https://www.7-zip.org/faq.html>.

"dk" downloads OCaml, codept and other binaries at first run and on each version upgrade.
OCaml has a [LPGL2.1 license with Static Linking Exceptions](./LICENSE-LGPL21-ocaml).
codept has a [LPGL2.1 license with Static Linking Exceptions](./LICENSE-LGPL21-octachron).
The other binaries are DkSDK Coder Runtime Binaries © 2023 by Diskuv, Inc.
These DkSDK Coder Runtime Binaries are licensed under Attribution-NoDerivatives 4.0 International.
To view a copy of this license, visit <http://creativecommons.org/licenses/by-nd/4.0/>.

"dk" acts as a package manager; you run `./dk` and tell it what packages you want to download
and run. These packages have independent licenses and you may be prompted to accept a license.
Those licenses include but are not limited to:

- The [DkSDK SOFTWARE DEVELOPMENT KIT LICENSE AGREEMENT](./LICENSE-DKSDK)

## Open-Source

The significant parts of `dk` that are open-source and downloaded:

- DkML compiler: <https://github.com/diskuv/dkml-compiler> and <https://gitlab.com/dkml/distributions/dkml>
- MlFront: <https://gitlab.com/dkml/build-tools/MlFront>
- Tr1 libraries: *to be published*
