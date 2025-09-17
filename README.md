# dk - The boring build and script tool

Running scripts with `dk` solves the problem of **README-itis**: you give your users a lengthy README document, your users fail to setup your software, and you lose a user forever.

`dk` is meant to be dry and boring. Here is an example for you building and running a package **as a developer** ... copy-and-paste it in PowerShell or in a Unix terminal:

<!-- $MDX os_type=Win32 -->
```sh
$ git clone https://github.com/diskuv/dk.git dk0
Cloning into 'dk0'...
$ dk0/mlfront-shell -- get-object DkSetup_Std.Exe@2.4.202508302258-signed -s File.Windows_x86_64 -d target/
[up-to-date] DkSetup_Std.Exe@2.4.202508302258-signed+bn-20250101000000 -s File.Windows_x86_64
$ target/dk.exe --version
2.4.202508312131 | ocaml 4.14.2
```

and how it would look for **your users** ...

<!-- $MDX skip -->
```sh
# this is not working yet, but it is close!
$ winget install -e --id Diskuv.dk
$ dk DkSetup.Exe@2.4.202508302258-signed dk.exe --version
2.4.202508312131 | ocaml 4.14.2
```

`dk` solves README-itis in two ways:

1. You model your actions (all that stuff you would put into a README) with scripts that `dk` will cross-compile for your users's platforms.
2. All required actions are executed as needed on your end-users' machines with dk's build tool.

Skip down to [Comparisons](#comparisons) for how `dk` fits with other tools. TLDR: `dk` is similar to the Nix package manager (except `dk` works on Windows) and to Docker (except not as heavy).

The build tool is quite new and has not yet been integrated into the script runner. But it has the `dk0/mlfront-shell` reference implementation, and specifications are at [docs/SPECIFICATION.md](docs/SPECIFICATION.md).

Separately, a [Quick Start for Scripting](#quick-start---scripting) is further below, and the main documentation site for the script runner is <https://diskuv.com/dk/help/latest/>.

## Quick Start - Build Tool

**Install** on Windows with PowerShell, or macOS or Linux with your terminal:

<!-- $MDX skip -->
```sh
git clone https://github.com/diskuv/dk.git
dk0/mlfront-shell --version
```

That will do a one-time download of a small binary (< 10MB), and
give you access to the community-submitted packages (*pending*) in
<https://github.com/diskuv/dk/tree/1.0/pkgs/include>.

**Download your first cloud asset** with:

```sh
$ dk0/mlfront-shell -- get-asset-file DkSetup_Std.Exe@2.4.202508302258-signed -p dk-darwin_arm64 -f binary-for-darwin_arm64
```

That downloaded an executable `dk-darwin_arm64` which is the `dk` script runner for Apple Silicon.
Change the path to `dk-windows_x86_64`, `dk-windows_x86`, `dk-linux_x86_64`, `dk-linux_x86` or `dk-darwin_x86_64` for other operating systems.

Run it with:

```sh
$ ./binary-for-darwin_arm64 --help
```

Congratulations! Hint: Later you will do [Quick Start for Scripting](#quick-start---scripting) that makes real use of that script runner.

**Download your first object** with:

```sh
$ dk0/mlfront-shell -- get-object DkExe_Std.Asset.Latest@1.0.202501010000 -s File.Darwin_arm64 -d dir-for-darwin_arm64
```

Objects (ie. `get-object`) have build commands embedded in them. Think of them like build targets with one or more outputs.
The `DkExe_Std.Asset.Latest` object has build commands that gets the latest `dk` executable asset for you.

If we inspect our new directory, we'll see:

```powershell
PS1> dir dir-for-darwin_arm64
Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---            1/1/1980 12:00 AM        8810960 dk
```

```sh
$ ls -l dir-for-darwin_arm64
-rw-r--r--  1 jonah  staff  8810960 Jan  1  1980 dk
```

All of the dates are set to Jan 1, 1980 for reproducibility.

**Explore more with the schema**. If you have an IDE/editor that supports JSON schema like Visual Studio Code,
you can create a build file with the following content (save it with a `.values.jsonc` extension):

```json
{
  "$schema": "https://github.com/diskuv/dk/raw/refs/heads/V2_4/etc/jsonschema/mlfront-values.json"
}
```

and you will get auto-completion for your build file.

Then you can run it with:

```sh
$ dk0/mlfront-shell -I the/directory/to/your/build/file -- get-object YourLibrary_Something.Something@1.0.202501010000 -s File.Agnostic
```

Almost any command you have been doing with `dk0/mlfront-shell ... -- THE-COMMAND ...` you can do inside the "precommands" of your build file.

**Shell into your first build** with:

<!-- $MDX skip -->
```sh
# Only for Apple Silicon ...

$ dk0/mlfront-shell -- enter-object DkDistribution_Std.Asset.Latest@1.0.202501010000 -s File.Darwin_arm64

DkDistribution_Std.Asset.Latest@1.0.202501010000 fn/File.Darwin_arm64 %
../../out/File.Darwin_arm64/DkCoder.bundle/Contents/Helpers/ocamlrun ../../out/File.Darwin_arm64/DkCoder.bundle/Contents/Helpers/ocaml -I ../../out/File.Darwin_arm64/DkCoder.bundle/Contents/Resources/lib/ocaml

OCaml version 4.14.2
Enter #help;; for help.

# 1+1 ;;
- : int = 2
# #quit;;
```

or

<!-- $MDX skip -->
```sh
# Only for Windows and Linux (use "Linux_x86_64") ...

$ dk0/mlfront-shell -- enter-object DkDistribution_Std.Asset.Latest@1.0.202501010000 -s File.Windows_x86_64

DkDistribution_Std.Asset.Latest@1.0.202501010000 fn/File.Windows_x86_64 %
../../out/File.Windows_x86_64/DkCoder.bundle/Contents/Helpers/ocamlrun ../../out/File.Windows_x86_64/DkCoder.bundle/Contents/Helpers/ocaml -I ../../out/File.Windows_x86_64/DkCoder.bundle/Contents/Resources/lib/ocaml

OCaml version 4.14.2
Enter #help;; for help.

# #show Stdlib;;
# #quit;;

```

## Quick Start - Scripting

<!-- SYNC: site:src/content/docs/guide/dk-quick-walkthrough.mdoc, dk.git:README.md#quickstart -->

Install on Windows:

<!-- $MDX skip -->
```powershell
winget install -e --id Diskuv.dk
```

or Apple/Silicon:

<!-- $MDX skip -->
```sh
sudo curl -o /usr/local/bin/dk https://diskuv.com/a/dk-exe/2.4.202508302258-signed/dk-darwin_arm64
sudo chmod +x /usr/local/bin/dk
```

or Apple/Intel:

<!-- $MDX skip -->
```sh
sudo curl -o /usr/local/bin/dk https://diskuv.com/a/dk-exe/2.4.202508302258-signed/dk-darwin_x86_64
sudo chmod +x /usr/local/bin/dk
```

or Linux with glibc and libstdc++ (Debian, Ubuntu, etc. but not Alpine):

<!-- $MDX skip -->
```sh
sudo curl -o /usr/local/bin/dk https://diskuv.com/a/dk-exe/2.4.202508302258-signed/dk-linux_x86_64
sudo chmod +x /usr/local/bin/dk
[ -x /usr/bin/dnf ] && sudo dnf install -y libstdc++
```

Then cross-compile a script to standalone Windows, Linux, Android executables (and to a macOS executable if you are on a macOS machine):

```sh
$ dk -g dune -S "
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
$ file target/ZzZz_Zz.Adhoc-* | cut -c1-69 | awk '{print $0 "..."}'

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

## Comparisons

*Italics* are a pending feature.

| Tool      | Features better with the tool | Features better with `dk`          |
| --------- | ----------------------------- | ---------------------------------- |
| Nix       | Huge set of packages          | Works on Windows. Static types.    |
| (contd.)  |                               | *Signify-backed supply chain*      |
| Buck2 +   | Scales to millions of files   | Works well outside of monorepo     |
| ... Bazel | Backed by Big Tech            | Easier to adopt                    |
| Ninja     | Integrated with CMake. Fast   | Cloud-friendly, sharable artifacts |
| (contd.)  | Rules to simplify build files | *Pending integration in scripts*   |
| (contd.)  | Multithreading                | *Pending integration in dk*        |
| Docker    | Huge set of images            | Works well on Windows              |
| (contd.)  | Works very well in CI         | Works in CI and *during installs*  |

The following are tools specific to the OCaml language, and `dk` should not replace them.
Skip this table if you are not an OCaml-er.

| Tool | Features better with the tool | Features better with `dk`            |
| ---- | ----------------------------- | ------------------------------------ |
| opam | Thousands of packages         | Immutable storage. Binary artifacts. |
| dune | Watch mode. Fast              | Extensible. Not tied to OCaml.       |

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
