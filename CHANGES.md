# Changes

## 2.3.202505282324

- Moved to dkcoder based `dk` executable which is downloaded by `./dk` and `./dk.cmd`. No CMake is required, so `__dk.cmake` is no longer necessary.

## 2.2.1.4

- Include custom version of `topfind` in REPL so equivalent of `#use "topfind";;`.

## 2.2.1.3

- Add `Tr1Fpath_Std`.
- Add `Tr1Cmdliner_Std`.
- Replace untrusted uses of `Fpath.v` with `Fpath.of_string`, which strengthens handling of user inputs. Use `Tr1Fpath_Cmdliner.Fpath_Cmdliner`  to handle untrusted input in command line arguments.
- Avoid hardcoded stdlib in REPL, and open the Stdlib shadow module from DkCoder instead.

## 2.2.1.1

- `dk.sqlite3` is now backwards-compatible, which is required for soon-to-be old versions like `./dk DkRun_V2_2.Run` to co-exist with `./dk DkRun_V2_3.Run`.
- lsp upgraded to 1.20.1 from 1.20.0 to fix slowness
- Added `--debug-on-compile-failure` option that will launch a [Down-enhanced](https://erratique.ch/software/down/doc/) OCaml toplevel session after a build failure. Use it to debug type errors since the OCaml toplevel will have any successfully compiled modules available for inspection.
- The `--override-dkcoderppx-exe` option, if specified, is now written into the generated `dune-file` files. That makes the Dune files not portable, but the overrides can only be done with `run-you.sh` and `run-us.sh` for DkCoder subscribers. Without the override, `dkcoder-ppx` is expected on the PATH which is portable and trivially satisfied by the PATH setup in `./dk`.
- Run accepts `repl` subcommand which will start a REPL (OCaml toplevel). The entry module's `let __repl () : unit = ...` function, which does nothing by default, will be called during the REPL initialization.

## 2.2.0.1

- Run accepts `sbom` subcommand which will print an early version of a software bill of materials. There is now also a `run` subcommand which is chosen by default.
- The Run `--cmake-exe` (DKCODER_CMAKE_EXE envar) and `--ninja-exe` (DKCODER_NINJA_EXE envvar) options were removed. In later versions of DkCoder CMake will be completely removed from the initial boot sequence.
- Allow `file://` in RemoteSpec
- `V0_1` was removed as its end of grace period was 2024-09-30.

## 2.1.4.10

- New `DkDev_Std.Export create-blib` subcommand to make a blib archive.
- Patched capnp behind `Tr1Capnp_Std` that is amenable to codept analysis: <https://github.com/capnproto/capnp-ocaml/pull/91> and <https://github.com/capnproto/capnp-ocaml/pull/92>
- `DkDev_Std.Export` now exports `.cmti` in addition to `.cmi`
- The `Run` (ex. `./dk DkRun_Project.Run`) is now native code rather than bytecode. Native code has dead-code and other optimizations necessary so that more features can be added to `Run` while still fitting inside a 32-bit end-user environment.
- Renamed `DkDev_Std` to `MlStd_Std`. In an upcoming version you will be able to drop the trailing `Std` segments, so that `MlStd_Std.Export` could be invoked as `Ml.Export`.
- All `MlStd_Std` scripts will skip the ToS check, not just the newly renamed `MlStd_Std.Exec`, `MlStd_Std.Export` and `MlStd_Std.Legal.Record`. This will mean `dk Ml.*` will be consistently:
  1. Apache 2.0 license
  2. No terms of service check
- Mitigate occurrence of `Reason: flexdll error: cannot relocate xxxx RELOC_REL32, target is too far` on `windows_x86_64` when `./dk DkRun_Project.Run` (etc.) runs: <https://github.com/diskuv/dkml-compiler/compare/b211c65d1ac69590ce75e9ae8405fb71a3654f63...main>

## 2.1.4.9

- The marshalled `.mli` filenames (part of `Location.t`) are now equal in both DkSDK CMake and DkSDK Coder for all the package dependencies of DkSDKFFI_OCaml: base,ocplib-endian,res,result,sexplib0, and stdio. That makes their `.cmi` checksums equivalent which avoids `make inconsistent assumptions` ocamlc errors.

## 2.1.4.8

- Allow unpackaged scripts to run. That means `./dk DkRun_Project.Run somefile.ml` can have `somefile.ml` be any path on the filesystem. That gives a new third way to run scripts:
  1. With a standard module id (ex. DkDev.Export).
  2. With a path which ends with one or more MlFront module names and has an immediate MlFront library name ancestor. For example `../a/b/c/SomeTest_Std/X/Y/Z.ml` will be a standard module `SomeTest_Std.X.Y.Z` because the path ends with the module names `X`, `Y` and `Z` and has an immediate library name `SomeTest_Std`.
  3. (new change) Any other path will be treated as if it were the reserved module id `ZzZz_Zz.<CapitalizedBasename>` as long as the path's basename, when capitalized, is a valid standard module name. For example:
  
  - `somefile.ml` becomes `ZzZz_Zz.Somefile`
  - `A.ml` becomes `ZzZz_Zz.A`
  - `AbcDefHello.ml` becomes `ZzZz_Zz.AbcDefHello`
  - `AbcDef_Hello.ml` is not accepted because it matches MlFront library name standards
  - `A__.ml` is not accepted because it has a double underscore
  - `_A.ml` is not accepted because it begins with an underscore

## 2.1.4.7

- The generated `dune` files in the `#/s` are now relocatable. That means you can move the project directory (both the source code and the `#s/` folder) and your build should in theory work. However, the `findlib.conf` has hardcoded paths that might be addressed in a later version of findlib <https://github.com/ocaml/ocamlfind/pull/72>.
- The generated `dune` and `dune-project` files are now `.z-dk-dune` and `dune-file`. That lets Dune projects work with DkCoder without having to remove existing `dune-project` and `dune` files. An empty `dune-workspace` will also be created if it doesn't exist so that Merlin knows there is a Dune project.

## 2.1.4.4

- `DKML_TARGET_ABI` environment variable, if set, is honored in `./dk dksdk.java.jdk.download`. `./dk dksdk.java.jdk.download DKML_TARGET_ABI <abi>` is also supported.
- Support for `DKCODER_TTL_MINUTES` had regressed, and is now fixed so that it re-fetches DkCoder after the specified minutes from the last time.

## 2.1.4.3

- Upgrade to Ninja 1.12.1 from 1.11.1 specifically to fix <https://github.com/ninja-build/ninja/issues/829>
- Provide and download ninja-build static binaries on Linux since system-installed Ninja versions are unpredictable and Ninja-provided binaries are linked to recent glibc versions.
- Provide and download CMake static binaries for same reasons as ninja-build.
- Remove now-unused code for `unzip` install on Linux in `./dk`. `unzip` was used for unpacking a Python wheel archive that contained CMake, and for unzipping a Ninja installation zipfile, but that is no longer needed.
- Have `./dk` work with BusyBox's `tar`
- Use `FetchContent(URL)` in `__dk.cmake` rather than Git to download the latest system scripts (`./dk dkml.xxx` and `./dk dksdk.xxx` scripts).
- *breaking change*: Remove `git` from being installed during `./dk` on Linux, which presumes that `sudo` or something similar is available to do the installation, and presumes authentication is set up. It was previously being done to let CMake do `FetchContent(GIT_xxx)` in `__dk.cmake`; however, it was never being done for Windows or macOS so it was broken. Instead, user scripts (and system scripts) should handle any Git install + setup themselves. Also, user scripts are long deprecated so this breaking change should affect only system commands.
- The archive format for downloads of DkCoder has switched exclusively to zip archives due to varying incompatible tar support.
- bugfix: Initial `./dk` would fail but subsequent ones would work.
- bugfix: Search for uname in /usr/bin but also /bin
- Setting `DKML_HOST_ABI` environment variable to `linux_x86` (etc.) will override which binary is downloaded during `./dk` on Unix hosts.
- Using `./dk dksdk.project.get SANDBOX` will skip fetching from any URL that has `${sourceParentDir}` or `${projectParentDir}` variables (ie. they go outside the project). Should be used in CI jobs.

## 2.1.3.2

- Propagate NO_COLOR and Windows color detection to Dune
- Replace Tr1Tar_LwtUnix/Unix/Std. It is no longer a thin layer on top of the `ocaml-tar` package since that package is very unstable. Instead it exposes only one extraction function, with more functions possible in the future.
- bugfix: <https://github.com/diskuv/dkcoder/issues/1>. `Tr1Assets` and other implicit modules no longer depend on `open__.ml`.
- bugfix: <https://gitlab.com/diskuv/samples/dkcoder/DkHelloScript/-/issues/1>. No more duplicate module errors with text "Module ___ is provided simultaneously".
- New `DkDev_Std.Legal.Record --help` for programmatically accepting the license. Designed for continuous integration.
- Enable Windows long path support for all executables inside their application manifests. Works only when registry is updated using admin privileges. Confer <https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation>
- Standard error is used consistently for logging in `./dk`
- Use quiet `-q` option for `yum install` in `./dk` for Linux, and `--quiet --no-progress` for `apk add`
- bugfix: Consistently use `-qq install --no-install-suggests` for apt-get install
- Support `DkRun_Project` in addition to `DkRun_Env` and `DkRun_V<n>_<m>`. The *project version* is whatever long-term supported version is embedded in `__dk.cmake`. Among other things, this simplifies vscode settings.json.
- *For DkSDK subscribers.* Automatic re-install if the checksum on a `DKRUN_ENV_URL_BASE` locally-built DkCoder tarball has changed.
- Allow `DKML_HOST_ABI` environment variable to influence which ABI is downloaded in `./dk`.
- On Windows the data home is `%LOCALAPPDATA%\Programs\DkCoder`. Was previously a mix of `%LOCALAPPDATA%\Programs\DkSDK` and `%LOCALAPPDATA%\Programs\DkCoder`. You can delete `%LOCALAPPDATA%\Programs\DkSDK`.
- On Unix the data home is now `$XDG_DATA_HOME/dkcoder` or `$HOME/.local/share/dkcoder`. Was previously `$XDG_DATA_HOME/dksdk` or `$HOME/.local/share/dksdk`, both of which you can delete.
- On Unix when `CI=true` use `.dk/tools` subdirectory not `.tools`.
- On Windows and Unix allow DKCODER_DATA_HOME environment variable to override default locations.

## 0.4.0.2

- Path-based commands can be given to `./dk`. That means `./dk somewhere/DkHello_Std/Hi.ml` will add `somewhere/` to the You directories and run the module `DkHello_Std.Hi`.
  This feature simplifies the 0.4.0 feature which had required `./dk DkRun_V0_4.Run somewhere/DkHello_Std/Hi.ml`.
- **Breaking change**:
  - Default generator is dune (not dune-ide) if non-DkCoder dune-project. That avoids a conflict with existing dune-project based projects.
  - If you have an old checkout of DkHelloScript, DkSubscribeWebhook or SanetteBogue, remove the `dune-project` from that checkout so that DkCoder can regenerate a dune-project annotated for 0.5.0.
- Add `./dk DkFs_C99.Dir [mkdir|rm]` script
- bugfix: Some module ids were not compilable (ex. `SonicScout_Setup.Q`) since they had dots in their first or last two characters.
- bugfix: The squished module ids (ex. `SonicScout_Setup.Qt`) were using the second and third last characters rather than the correct last and second last characters.
- performance: Optimize initial `./dk` install by not copying files. On Windows install time (neglecting download time) dropped from 75 seconds to 6 seconds.
- usability: Detect if terminal attached on Windows, and use ANSI color when terminal attached (except when NO_COLOR or in CI).
- Add DkCoder_Std package that has module and module types that DkCoder scripts implement.
- Rename `DkDev_Std.ExtractSignatures` to `DkDev_Std.Export`. Include writing .cma alongside updated dkproject.jsonc. Pushdown log level from `DkDev_Std.Export` to `codept-lib-dkcodersig`
- Add type equations for `Tr1Logs_Std` so `Logs.level` (etc.) is equivalent to `Tr1Logs_Std.Logs.level`
- Us scripts are now part of a findlib site-lib and can be referenced from other scripts, not just run as standalone scripts.
- `__dkcoder_register` has been renamed `__init` which means it initializes the module, similar to have Python's `__init__` initializes a class.
- Let `__init` be overridable. WARNING: Although today `__init` is only called for the entry script, future DkCoder will call `__init` for all `You` scripts in dependency order. So defining your own `let __init () = ...` as an alternative to `if Tr1EntryName.module_id = __MODULE_ID__ then ...` will eventually break for `You` scripts.
- Add --force option to `DkFs_C99.Dir rm`
- Add `DkFs_C99.Path` and `DkFs_C99.File`.
- Add `os` to `Tr1HostMachine`.
- Add `--kill` to `DkFs_C99.Path rm`
- findlib.conf generated at analysis time rather than __dk.cmake install time

Important Notes

- `open__.ml` is not transitive at compile-time. That means other libraries that use your library may get:

  ```text
  Error: This expression has type Uri.t but an expression was expected of type
          DkCurl_StdO__.Open__.Uri.t
        DkCurl_StdO__.Open__.Uri.t is abstract because no corresponding cmi file was found in path.
  ```

  Use fully-qualified module ids if other libraries will use your scripts.
  A future version of DkCoder may change the error message but won't mandate that you fully qualify
  every module reference (that defeats the purpose for the vast majority of scripts which aren't shared).
  Alternatives include requiring fully qualifing module ids in `.mli` files (but not `.ml`),
  or having an `exports__.ml` that functions as the public compile-transitive version of `open__.ml`.

## 0.4.0.1

- Run using a file path in addition to module id
- Add Tr1Tar
- Expose Logs.Src and Logs.Tag for codept
- bugfix: Do not search for nephews of implicit or optimistic modules
- Upgrade merlin from 4.12-414 to 4.14-414
- bugfix: `[%sample]` was not dedenting when there was a blank line
- Add Tr1String_Ext
- Add `./dk DkStdRestApis_Gen.StripeGen`
- Upgrade to Tezt 4.1.0 which has upstreamed Windows fixes from DkCoder 0.3.0
- Add `Tr1HostMachine` implicit with a ``abi : [`android_arm64v8a|`android_arm32v7a|`android_x86|`android_x86_64|`darwin_arm64|`darwin_x86_64|`linux_arm64|`linux_arm32v6|`linux_arm32v7|`linux_x86_64|`linux_x86|`windows_x86_64|`windows_x86|`windows_arm64|`windows_arm32|`dragonfly_x86_64|`freebsd_x86_64|`netbsd_x86_64|`openbsd_x86_64|`unknown_unknown|`darwin_ppc64|`linux_ppc64|`linux_s390x]`` value

## 0.3.0

- Add cohttp-curl
- Do not distribute .pdb in non-debug builds
- Add Tr1Logs_Std, Tr1Logs_Clap and Tr1Logs_Lwt and Tr1Http_Std and Tr1Uri_Std
- Export base64, ezjsonm, resto and json-data-encoding and uri and cohttp-server-lwt-unix and cohttp-curl-lwt
- bugfix: Stitched modules were not being created if nephews already existed
- bugfix: implicit modules check if known to solver
- bugfix: setting solver state should fully set state
- bugfix: modified aliases means must expand to solve harder
- bugfix: Fix bug with duplicated pending module
- Add simultaneity invariant check of pending and resolved solver states

## 0.2.0

- Support `.mli` interface files
- Libraries can have a `open__.ml` module that will be pre-opened for every script in the library.
  This module is the correct place to supply the DkCoder required module imports without changing existing OCaml code:

  ```ocaml
  module Printf = Tr1Stdlib_V414CRuntime.Printf
  module Bos = Tr1Bos_Std.Bos
  module Bogue = Tr1Bogue_Std.Bogue
  ```

- A bugfix for SDL logging is included and SDL logging is now enabled.
- Module and library names ending with `__` are reserved for DkCoder internal use.
- `DkDev_Std` is a reserved "Us" library. You cannot redefine this library. Any library that starts with `Dk` is also reserved.
- Add implicit modules (see below)
- Make `__MODULE_ID__` value available to scripts so they can see their own fully qualified module identifiers (ex. `SanetteBogue_Snoke.X.Y.Snoke`)
- Make `__LIBRARY__` value available to scripts so they can see which library they belong (ex. `SanetteBogue_Snoke`)
- Make `__FILE__` value be the Unix-style (forward slashes) relative path of the script to the script directory (ex. `SanetteBogue_Snoke/X/Y/Snoke.ml`).
- `Stdlib.Format` was moved from Tr1Stdlib_V414Base to Tr1Stdlib_V414CRuntime because `Format.printf` does C-based file I/O.
- The `dune` generator and the internal DuneUs generator will use fixed length encoding of the library names.
  This partially mitigates very long paths created by Dune that fail on Windows path limits.
- Added `Tr1Tezt_C` and `Tr1Tezt_Core`.
  - No Runner module is provided since that only connects to Unix.
  - The `Process` module has been removed since it assumes Windows and its dependency `Lwt_process` is buggy on Windows.
  - A `ProcessShexp` is bundled that is a cross-platform, almost API-equivalent of Tezt's `Process`.
    - No `spawn_with_stdin` since difficult to bridge I/O channels between Lwt and Shexp.
    - No `?runner` parameters since Runner is Unix-only.
    - There is an extra method `spawn_of` that accepts a `Shexp.t` process
  - A `ProcessCompat` is bundled that does not assume Windows but still uses a buggy `Lwt_process`. Use for porting old code only.
- The Debug builds are no longer bundled due to Microsoft not allowing those to be distributed. Also speeds install time. Anyone with source code access (ie. DkSDK subscribers) can do debug builds and get meaningful stack traces.
- End of life and a grace period for a version are enforced with messages and errors. They respect the SOURCE_DATE_EPOCH environment variable so setting it to `1903608000` (Apr 28, 2030) can test what it looks like.

### 0.2.0 - Implicit Modules

Implicit modules are modules that are automatically created if you use them. Unlike explicit modules, their content can be based on the structure of the project.

#### 0.2.0 - Tr1Assets.LocalDir

The `v ()` function will populate a cache folder containing all non-ml source code in the `assets__` subfolder of the library directory.
The `v ()` function will return the cache folder.

```ocaml
val v : unit -> string
(** [v ()] is the absolute path of a cache folder containing all the files
    in the `assets__` subfolder of the library directory.

    For example, in a project:

    {v
      <project>    
        ├── dk
        ├── dk.cmd    
        └── src
            └── SanetteBogue_Snoke
                ├── Snoke.ml
                └── assets__
                    ├── SnakeChan-MMoJ.ttf
                    ├── images
                    │   ├── apple.png
                    │   └── snoke_title.png
                    └── sounds
                        └── sol.wav    
    v}

    the ["Snoke.ml"] script would have access to a cached directory from
    [v ()] that contains:

    {v
      <v ()>
      ├── SnakeChan-MMoJ.ttf
      ├── images
      │   ├── apple.png
      │   └── snoke_title.png
      └── sounds
          └── sol.wav    
    v}
    *)
```

#### 0.2.0 - Tr1EntryName

```ocaml
(** The name of the DkCoder library the entry script belongs to.
    Ex: SanetteBogue_Snoke *)
val library : string

(** The simple name of the entry script.
    Ex: Snoke *)
val simple_name : string

(** The fully qualfied module name for the entry script.
    Ex: SanetteBogue_Snoke.Snoke *)
val module_name : string
```

Using the `Tr1EntryName` module, you can mimic the following Python:

```python
if __name__ == "__main__":
    print("Hello, World!")
```

with

```ocaml
let () =
  if Tr1EntryName.module_id = __MODULE_ID__ then
    Tr1Stdlib_V414Io.StdIo.print_endline "Hello, World!"
```

That means you can isolate side-effects when importing other scripts.

#### 0.2.0 - Tr1Version

```ocaml
(** The fully qualified [Run] module corresponding to the current version.
    Ex: DkRun_V0_1.Run *)
val run_module : string

val run_env_url_base : string option
(** The base URL necessary when if launching with {!run_module} when
    [run_module = "DkRun_Env.Run"]. *)

val major_version : int
val minor_version : int
```

### Known problems

#### Windows hung processes

Exiting scripts with Ctrl-C on Windows only exits the Windows batch script, not the actual subprocess.

For now `taskkill /f /im ocamlrunx.exe` will kill these hung processes.

#### Windows STATUS_ACCESS_VIOLATION

On first install for Windows running the `./DkHelloScript/dk DkRun_V0_2.Run -- DkHelloScript_Std.Y33Article --serve`
example gives:

```text
[00:00:22.564] [[32m[1mSUCCESS[0m] (3/18) reproducibility or quick typing
[00:00:22.564] Starting test: focus on what you run
[00:00:22.566] [1m[.\dk.cmd#3] '.\dk.cmd' DkRun_V0_2.Run '--generator=dune' -- DkHelloScript_Std.AndHelloAgain[0m
[ERROR][2024-04-29T00:00:43Z] /Run/
       Failed to run
         C:\Users\WDAGUtilityAccount\DkHelloScript\src\DkHelloScript_Std\Y33Article.ml
         (DkHelloScript_Std.Y33Article). Code fa10b83d.

       Problem: The DkHelloScript_Std.Y33Article script exited with
         STATUS_ACCESS_VIOLATION (0xC0000005) - The instruction at 0x%08lx
       referenced memory at 0x%08lx. The memory could not be %s.
       Solution: Scroll up to see why.
```

Rerunning it works.

### Punted past 0.2.0

- Fetch and use "Them" libraries
  - Adds --cmake-exe (DKCODER_CMAKE_EXE envar) and --ninja-exe (DKCODER_NINJA_EXE envvar) to Run command.
- Libraries can have a `lib__.ml` module that can provide documentation for the library (ex. `MyLibrary_Std`) through a top comment:

  ```ocaml
  (** This is the documentation for your library. *)

  (* Anything else inside lib__.ml will trigger an error *)
  ```

  Documentation hover tips are refreshed on the next run command (ex. `./dk DkHelloScript_Std.N0xxLanguage.Example051`)
- Running `DkDev_Std.ExtractSignatures` will update `dkproject.jsonc` with an `exports` field that has codept signatures.
  The `dkproject.jsonc` will be created if not present.

## 0.1.0

Initial version.
