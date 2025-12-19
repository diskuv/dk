# Scripting

> OCaml-based scripting (this document) is undergoing a large refactoring to sit behind the `dk` build system's Lua-based scripting. OCaml-based scripting has a **pre-alpha status**.

## Introduction

Scripting with `dk` does two things:

1. You model your actions (all that stuff you would put into a README) with scripts that `dk` will cross-compile for your users' platforms.
2. All required actions are executed as needed on your users' machines with `dk`'s build tool.

`dk`'s scripting functionality requires a runtime environment and platform development kits are downloaded on-demand. We want our users (ex. you) to install and get started *quickly*. Users copy-and-paste the text blocks below on Windows. Go ahead and copy-and-paste yourself if you want to try the `dk` cross-compiling scripting environment, or skip past it to learn about the `dk` build tool:

<!-- Windows updates: dk Ml.Use -- .\maintenance\010-PROJECTROOT-README.sh -->

<!-- $MDX skip -->
```console
# Install a standalone executable. And available for macOS and Linux.
$ winget install -e --id Diskuv.dk -v "2.4.25164.1"
```

<!-- $MDX skip -->
```console
# THIS EXAMPLE: The `dk` software stack has scripting.
#      Here's a script to download and print a page to the screen.
# IN GENERAL: Your users copy-and-paste your first example ...
$ dk -S "
    module Uri = Tr1Uri_Std.Uri
  " -U "
    Tr1Stdlib_V414Io.StdIo.print_endline @@
    Lwt_main.run @@
    DkNet_Std.Http.fetch_url ~max_sz:4096 @@
    Uri.of_string {|https://jigsaw.w3.org/HTTP/h-content-md5.html|}
  " -O ReleaseSmall Exe

... THIS EXAMPLE: `dk` will install a scripting environment, download
... development kits on-demand for different platforms, and do a
... cross-compile. It *takes time* to download massive development kits.
... You (and your user) will do something else in another window, but as
... long as you don't have to type anything, you'll probably stick around!
... ⟳ ⟳ ⟳ software installed automatically ⟳ ⟳ ⟳
... ⟳ ⟳ ⟳         example executed         ⟳ ⟳ ⟳

# THIS EXAMPLE: `dk` scripting makes standalone executables.
# IN GENERAL: Your users get the results they want ...
$ file target/ZzZz_Zz.Adhoc-*
target/ZzZz_Zz.Adhoc-android_arm32v7a:   ELF 32-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-android_arm64v8a:   ELF 64-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-android_x86_64:     ELF 64-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-darwin_arm64:       Mach-O 64-bit executable arm...
target/ZzZz_Zz.Adhoc-darwin_x86_64:      Mach-O 64-bit executable x86...
target/ZzZz_Zz.Adhoc-linux_x86:          ELF 32-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-linux_x86_64:       ELF 64-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-windows_x86_64.exe: PE32+ executable (console) x...
target/ZzZz_Zz.Adhoc-windows_x86.exe:    PE32 executable (console) In...
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
```console
sudo curl -o /usr/local/bin/dk https://diskuv.com/a/dk-exe/2.4.202508302258-signed/dk-darwin_arm64
sudo chmod +x /usr/local/bin/dk
```

or Apple/Intel:

<!-- $MDX skip -->
```console
sudo curl -o /usr/local/bin/dk https://diskuv.com/a/dk-exe/2.4.202508302258-signed/dk-darwin_x86_64
sudo chmod +x /usr/local/bin/dk
```

or Linux with glibc and libstdc++ (Debian, Ubuntu, etc. but not Alpine):

<!-- $MDX skip -->
```console
sudo curl -o /usr/local/bin/dk https://diskuv.com/a/dk-exe/2.4.202508302258-signed/dk-linux_x86_64
sudo chmod +x /usr/local/bin/dk
[ -x /usr/bin/dnf ] && sudo dnf install -y libstdc++
```

Then cross-compile a script to standalone Windows, Linux, Android executables (and to a macOS executable if you are on a macOS machine):

<!-- $MDX skip -->
```console
$ dk -S "
    module Http = DkNet_Std.Http
    module Uri = Tr1Uri_Std.Uri
    let print_endline = Tr1Stdlib_V414Io.StdIo.print_endline
  " -U "
    print_endline @@
    Lwt_main.run @@
    Http.fetch_url ~max_sz:4096 @@
    Uri.of_string {|https://jigsaw.w3.org/HTTP/h-content-md5.html|}
  " -O ReleaseSmall Exe
[INFO ] /StdStd_Std.Run/
       Assembling adhoc script ZzZz_Zz.Adhoc:
       module Http = DkNet_Std.Http
       module Uri = Tr1Uri_Std.Uri

       let print_endline = Tr1Stdlib_V414Io.StdIo.print_endline

       let __init (context : DkCoder_Std.Context.t) =
         print_endline @@ Lwt_main.run
         @@ Http.fetch_url ~max_sz:4096
         @@ Uri.of_string {|https://jigsaw.w3.org/HTTP/h-content-md5.html|};
         __init context
       [@@warning "-unused-var-strict"]


[INFO ][2025-09-17T23:18:56Z] /StdStd_Std.Exe/
       <linux_x86_64>     target/ZzZz_Zz.Adhoc-linux_x86_64
[INFO ][2025-09-17T23:18:57Z] /StdStd_Std.Exe/
       <linux_x86>        target/ZzZz_Zz.Adhoc-linux_x86
[INFO ][2025-09-17T23:19:01Z] /StdStd_Std.Exe/
       <android_x86_64>   target/ZzZz_Zz.Adhoc-android_x86_64
[INFO ][2025-09-17T23:19:04Z] /StdStd_Std.Exe/
       <android_arm64v8a> target/ZzZz_Zz.Adhoc-android_arm64v8a
[INFO ][2025-09-17T23:19:05Z] /StdStd_Std.Exe/
       <android_arm32v7a> target/ZzZz_Zz.Adhoc-android_arm32v7a
[INFO ][2025-09-17T23:19:05Z] /StdStd_Std.Exe/
       Skipped darwin_x86_64 executable since that requires macOS machines for codesigning and Xcode for licensed MacOSX SDK
[INFO ][2025-09-17T23:19:05Z] /StdStd_Std.Exe/
       Skipped darwin_arm64 executable since that requires macOS machines for codesigning and Xcode for licensed MacOSX SDK
[INFO ][2025-09-17T23:19:08Z] /StdStd_Std.Exe/
       <windows_x86_64>   target/ZzZz_Zz.Adhoc-windows_x86_64.exe
[INFO ][2025-09-17T23:19:11Z] /StdStd_Std.Exe/
       <windows_x86>      target/ZzZz_Zz.Adhoc-windows_x86.exe
```

The executables will be available in the `target/` folder:

<!-- $MDX skip -->
```console
$ file target/ZzZz_Zz.Adhoc-* | cut -c1-69 | awk '{print $0 "..."}'
target/ZzZz_Zz.Adhoc-android_arm32v7a:   ELF 32-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-android_arm64v8a:   ELF 64-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-android_x86_64:     ELF 64-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-darwin_arm64:       Mach-O 64-bit executable arm...
target/ZzZz_Zz.Adhoc-darwin_x86_64:      Mach-O 64-bit executable x86...
target/ZzZz_Zz.Adhoc-linux_x86:          ELF 32-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-linux_x86_64:       ELF 64-bit LSB pie executabl...
target/ZzZz_Zz.Adhoc-windows_x86.exe:    PE32 executable (console) In...
target/ZzZz_Zz.Adhoc-windows_x86_64.pdb: MSVC program database ver 7....
target/ZzZz_Zz.Adhoc-windows_x86_64.exe: PE32+ executable (console) x...
target/ZzZz_Zz.Adhoc-windows_x86.pdb:    MSVC program database ver 7....
```

## Developer Reference

The reference documentation for the script runner is at <https://diskuv.com/dk/help/latest/>
