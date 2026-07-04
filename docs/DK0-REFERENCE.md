# dk0 Reference Implementation

`dk0` is the open-source reference implementation of the dk build system.

This document describes behavior that is specific to `dk0`. The
implementation-agnostic build model - projects, assets, bundles, forms, objects,
values, subshells, distributions and scripts - is in the
[Specification].

> [!NOTE]
> There will be other implementations (ex. `dk1` and `dk`) in the future.

[Specification]: SPECIFICATION.md

## Invocation

```text
dk0 [global options] [--] command [command args]
```

Use `--` to separate the global options from the command and its arguments.

The **workspace** directory is the nearest ancestor directory containing a `dk.u`
unified script with a level-2 `## workspace` section; if none, the current
directory. In `dk0` the directory containing the `dk0` shell script and the
`dk0.cmd` Windows batch script is the project directory.

You can invoke a value shell command directly from the command line. For
example, `dk0 get-object OurStd_Std.Build.Clang@1.0.0 -s Release.Agnostic -f clang.exe`.

> [!NOTE]
> Some behavior described in the [Specification] is **not yet available** in `dk0`:
>
> - Lockfiles are not implemented yet; build metadata is taken from the `-t`/`-P`/`-n`
>   options (see [Options](#options)) instead.
> - Only single-file `*.ml` embedded scripts are supported so far.

## Commands

### High-level commands

```text
update [--no-imports] [-f unifiedscript.u]
```

Update the workspace `dk.u` or self-contained `unifiedscript.u`; updates imports
and workspace assets. `--no-imports` skips imports. (`dk0` updates workspace asset
checksums with `dk0 update`, and invalidates values with `dk0 invalidate` or
`dk0 -x EXPRESSION`.)

```text
quickstart GROUP NAME [--dir DIR] [--base-registry URL]
                      [--group-registry GROUP=URL] [--force]
```

Bootstrap a new workspace from the recipe `NAME` in group `GROUP`. `GROUP` is
the organisation namespace (e.g. `ocaml`) and `NAME` is the recipe within that
group (e.g. `opam`). Fetches the recipe from the registry at runtime, writes a
`dk.u` with the appropriate imports, then runs `dk0 update` automatically.

- `--dir DIR` writes the workspace in `DIR` instead of the current directory.
- `--base-registry URL` overrides the global base URL for the recipe registry
  (default: `https://diskuv.com/dk/quickstart`). Recipes are fetched from
  `<URL>/<GROUP>/<NAME>.quickstart.jsonc`. The environment variable
  `DK_QUICKSTART_BASE_REGISTRY` is a fallback checked before the built-in
  default. Useful for mirroring all groups without a per-group override.
- `--group-registry GROUP=URL` points one group at its own registry. Recipes
  for that group are fetched from `<URL>/<NAME>.quickstart.jsonc` (the group is
  not part of the path). The environment variable `DK_QUICKSTART_<GROUP>_REGISTRY`
  (e.g. `DK_QUICKSTART_OCAML_REGISTRY`) is the equivalent fallback. The flag can
  be repeated for multiple groups. A group override takes priority over
  `--base-registry` for that group.
- `--force` overwrites an existing `dk.u` in the target directory.

The registry serves `<NAME>.quickstart.jsonc` recipe files in the
[dk-quickstart-recipe-1.0](../etc/jsonschema/dk-quickstart-recipe-1.0.json) JSON
schema, published at
`https://diskuv.com/dk/schema/dk-quickstart-recipe-1.0.json`. A registry index
(`index.jsonc`, [dk-quickstart-index-1.0](../etc/jsonschema/dk-quickstart-index-1.0.json))
lists the available groups, and each group publishes a group index
(`<group>/index.jsonc`,
[dk-quickstart-group-index-1.0](../etc/jsonschema/dk-quickstart-group-index-1.0.json))
listing its recipes.

#### Hosting a group on your own registry

A group does not have to live on diskuv.com. Any organisation can host a group
on its own registry:

- Serve each recipe file at `<your-url>/<name>.quickstart.jsonc` (one level; no
  group prefix is needed since `--group-registry` already selects the group).
- Publish a group index at `<your-url>/index.jsonc` conforming to
  `dk-quickstart-group-index-1.0.json` so the diskuv.com listing page can
  enumerate your recipes.
- Users reach your group with `--group-registry <group>=<your-url>` or by
  setting `DK_QUICKSTART_<GROUP>_REGISTRY=<your-url>` once (e.g. in a shell
  profile); existing commands keep working after a move.

To take over a group that started on diskuv.com, host the recipes and the group
index at your own URL, then the group's entry in the diskuv.com registry
`index.jsonc` is updated once to advertise your `registry_url`. After that you
add new recipes (e.g. `dune`, `rocq`) by updating your own `index.jsonc`;
diskuv.com refreshes its listing page on its own schedule.

```text
add [-f unifiedscript.u] github-l2 [HOST/]OWNER/REPO[@TAG]
```

Add the latest release - or the release with tag `TAG` - of the GitHub repository
`[HOST/]OWNER/REPO` to the workspace. The release must have a distribution with a
SLSA Level 2 attestation.

```text
test [--diff file] [--actual file] [--actual-in-place] unifiedtest.u
```

Run the unified test in `<unifiedtest>.u` (a file) or `<unifiedtest>.u/run.u` (a
directory). A unified test is a superset of <https://bitheap.org/cram/>: each
`$ command` is a value shell command or a `dialog`/`exec` command, and each
`%% command` is a Lua chunk. Any interactive option for `dialog`/`exec` errors
and exits non-zero. If `# Title` is a package id, a cell is created with the
package's library as `NAME` and the parent directory (file) or the directory
itself (dir) as `VALUE` (see `--cell`). The `.t` cram-test extension is also
allowed. A self-contained unified test may carry an inline `## workspace` to
import libraries; otherwise the workspace is per the Configuration section. All
workspace declarations are evaluated before the test commands.

- `${RUNTIME}` is a temp directory unique to the unified test. `${CONFIG}` is for
  files in the cram-test directory, set by `dk0 test`.
- `--diff -|file` saves diffs to a file or stdout (repeatable).
- `--actual -|file` saves actual output to a file or stdout (repeatable).
- `--actual-in-place` edits the unified-test file in place.
- Default, if none of the above, is to print the diff.
- **exit 3:** there is one or more diff of actual vs expected.

### Value shell commands

```text
get-object MODULE@VERSION -s SLOT [-f|-d <output> [-n <strip>]] [-m <member>]
```

Get the contents of `SLOT` for the object `MODULE@VERSION`.

```text
run-object MODULE@VERSION -s SLOT (-c COMMAND [-n <strip>] | -m MEMBER)
    [-x <glob>]... [-e <glob>]... [-- [args...]]
```

Get `SLOT` of the object `MODULE@VERSION` into an anonymous directory and run
`COMMAND` relative to that directory, or get and run `MEMBER`.

```text
merge-object MODULE@VERSION -s SLOT [-f|-d <output> [-n <strip>]] [-m <member>]
```

Build the object `MODULE@VERSION` and merge its files into the output path.

```text
get-asset MODULE@VERSION -p ASSET [-f|-d <output> [-n <strip>]] [-m <member>]
```

Get the contents of `ASSET` in the bundle `MODULE@VERSION`.

```text
run-asset MODULE@VERSION -p ASSET (-c COMMAND [-n <strip>] | -m MEMBER)
    [-x <glob>]... [-e <glob>]... [-- [args...]]
```

Get `ASSET` in the bundle `MODULE@VERSION` into an anonymous directory and run
`COMMAND` relative to that directory, or get and run `MEMBER`.

```text
get-bundle MODULE@VERSION [-f|-d <output> [-n <strip>]]
```

Get all the bundle files in the bundle `MODULE@VERSION`.

```text
run-function MODULE@VERSION [-f|-d <output> [-n <strip>]] [-m <member>]
    [requestparam=value ...]
```

Run the function rule `MODULE@VERSION` and write the resulting object. Example:

```text
dk0 run-function MyLibrary_Std.A.B.MyModule.MyRule@1.0.0 -s Some.Slot -- a=1 b=2
```

```text
enter-object MODULE@VERSION -s SLOT
```

Launch a shell with the environment and file content of `SLOT` for object
`MODULE@VERSION`. The shell may be skipped if `MODULE@VERSION -s SLOT` is
up-to-date. The shell is `$SHELL` (if unset `/bin/sh`) on Unix, and `pwsh.exe`,
`powershell.exe` or `cmd.exe` on Windows. `SHELL_SLOT` is set to the `-s SLOT`
output directory; `SHELL_SLOTS` to the output parent directory of all slots.

### Script commands

```text
dialog [-e stat] [-l [g=]modname[@version]] [-i] MODULE@VERSION [name1=val1 ...]
```

Run the interactive (UI) rule `MODULE@VERSION`. The JSON request is created from
the `name1=val1 ...` name-values per <https://www.w3.org/TR/html-json-forms/>
(e.g. `pet[name]=Dot kids[1]=Zoe` ⇒ `{"pet":{"name":"Dot"},"kids":[null,"Zoe"]}`).
`-e stat` evaluates the Lua statement `stat`; `-l modname` is equivalent to
`require(modname)` (or `g = require(modname).at(version)` for `-l g=modname@version`).
`-e`, `-l` and the UI rule are handled in the order they appear; `-i` enters
interactive mode at the end. (`dialog` is the reference implementation's
subcommand for UI rules, while `run-function` is reserved for function rules.)

```text
exec [-e stat] [-l [g=]modname[@version]] [-i] [--lua] script [args...]
```

Run `script`. An embedded interactive rule is searched first; if none is found and
either `--lua` is given or `script` ends with `*.lua[u]`, the Lua script is run.
`args` is available to the script as strings in a global table `arg` per
<https://www.lua.org/manual/5.4/manual.html#7>. `-e`, `-l` and `script` are
handled in order; `-i` enters interactive mode at the end.

```text
lua [--analysis] [--valuescan] [-e stat] [-l [g=]modname[@version]] [-i]
    [script [args...]]
```

Launch a Lua REPL. Each REPL line is evaluated as a Lua chunk and any `return`
values are printed. `--analysis` enters the analysis mode used during the
VALUESCAN phase; `dk0 lua --analysis somefile.lua` shows the rules the build
system thinks are defined in a Lua script. `--valuescan` adds a VALUESCAN phase
where `-e`, `-l` and `script` are scanned and any `require()` are resolved before
evaluation. If `script` is given it is executed as a Lua script; `-i` enters
interactive mode afterward (default when no `script` and stdin is a terminal).
`dk0` also runs a file directly as a Lua script - `dk0 run some-script.lua` - when
the file ends with `.lua` (and some other extensions); see `dk0 --help`.

```text
dk0 lua -la b.lua t1 t2
dk0 lua -e "print(arg[1])"
```

```text
remote UI_MODULE@VERSION [REMOTE_OPTION=VALUE...] [REPOSITORY] COMMAND...
```

Run a local value shell command, `test`, `lua`, `dialog`, `exec`, or deprecated
`run` command on a remote execution engine. Short forms expand the library id -
e.g. `GitHub@0.1.0` ⇒ `CommonsBase_Remote.GitHub@0.1.0`, `BuildBuddy.Cloud@0.1.0`
⇒ `BuildBuddy_Remote.Cloud@0.1.0`.

### Utility commands

```text
signify -G [-c comment] -p pubkey -s seckey
signify -S [-x sigfile] -s seckey -m message
signify -V [-q] [-p pubkey] [-x sigfile] -m message
```

Create and verify cryptographic signatures: `-G` generates a key pair, `-S` signs
a message, `-V` verifies a message against a signature.

```text
zip ZIPFILE[.zip] [SRCFILE...]
```

Create or update a zipfile. Without `SRCFILE`, all files under the source
directory are added. `-srcdir DIR` sets the source directory; `-d` deletes
entries; `-x PATTERN` excludes a glob; `--deterministic` creates a reproducible
zipfile.

### Distribution commands

`dk0` requires that the package (a common prefix for a set of modules) is a `VendorQualifier_Unit` library id. For example, `CommonsBase_GNU.Make.Apparatus`
is not an acceptable package for distribution but `CommonsBase_GNU` is.

```text
prepare-version [--ci github] [--prepare-dir DIR] MAJOR.MINOR
```

Create key pairs for `MAJOR.MINOR`, the next minor, the next even minor, and the
next major version, and add public keys to `etc/dk/d/MAJOR.MINOR.PATCH.dist.json`.
Existing public keys are skipped. Asks for and sets the license if not present.
Fails if keys exist but `MAJOR.MINOR` is not the next minor or major version.

- `--ci github` creates the GitHub workflow
  `.github/workflows/distribute-MAJOR.MINOR.yml` and prints the GitHub CLI command
  to register the `MAJOR.MINOR` secret key (default).
- `--prepare-dir DIR` places keys in `DIR` (default `etc/dk/d`).

```text
distribute --library LIBRARY@VERSION [--with-producer-version VERSION]
    [--no-valuestore] [--diff FILE] [--actual FILE] [--prepare-dir DIR]
    PART unifiedtest.t
```

Evaluate the commands in `unifiedtest.t`, then define a distributed bundle and a
distribution `LIBRARY@VERSION` in `dk-dist/PART.values.json`. `PART` avoids
conflicts when combining many bundles with `combine`. Set up `LIBRARY@VERSION`
first with `prepare-version ... MAJOR.MINOR`; `VERSION` must be a monotonically
increasing patch of `MAJOR.MINOR` without build or prerelease components. The
`LIBRARY` is added to `--trust-local-package`. The distributed bundle is relative
to `dk-dist/` with `./PART.distmeta.valuestore.zip` + `./PART.package.valuestore.zip`
(metadata and package payload valuestores) and `./PART.distmeta.TAG.tracestore` +
`./PART.package.TAG.tracestore` (tracestores; `TAG` is the compatibility tag, e.g.
`oc414_wd64` - see `--print-platform-ids`). Overwrites
`distributions[].producer.application` with the current `dk0` version or
`--with-producer-version`.

- `--no-valuestore` disables creation of `valuestore.zip`.
- `--diff`/`--actual`/`--actual-in-place` behave as in `test`.
- `--prepare-dir DIR` finds keys in `DIR` (default `etc/dk/d`).
- **exit 3:** there is one or more diff of actual vs expected.

Objects and rules are public interfaces, so only their transitive values are
included; bundle files and assets are included only if an object or rule
transitively has `get-asset`/`get-bundle` precommands.

```text
combine [--origin-name <origin-name>] [--mirror <origin-url>]*
```

Combine `dk-dist/*.values.json` from many `distribute PART` runs into a single
`dk-dist/values.json` containing one or more distributions. Any `--mirror`
`origin-url` become the bundle mirrors for the origin named `local`, which is then
renamed to `origin-name`. (`dk0 combine` can also adjust the mirrors permanently
during distribution.)

```text
import github-l2 -R,--repo [HOST/]OWNER/REPO [--tag TAG] [--outdir DIR]
import local --path VALUES.JSON [--outdir DIR]
```

`import github-l2` verifies the distributions in `values.json` and related assets
(valuestores and tracestores) from the GitHub release with tag `TAG` (or latest),
using GitHub's SLSA Level 2 attestation. If verified, the `values.json` with the
attestation embedded is saved to `DIR/LIBRARY.values.json` (`DIR` default
`<workspace>/etc/dk/i`). Values and traces are not imported unless `DIR` is on the
include path and the distribution libraries are referenced. `import local` saves a
distribution from `VALUES.JSON` to `DIR` and discovers transitive distributions
from its tracestores and valuestores - for local/offline workflows and tests.

> [!NOTE]
> Documentation and catalog rendering want to validate the attestation without the
> cost of a full import: verify the release, but skip fetching traces and values,
> and instead fetch the package's exported distribution scripts. The intended flags
> are `import github-l2 --repo OWNER/REPO --no-traces --no-values --with-dist-scripts`
> (proposed; not yet implemented).

```text
restore github-l2 [HOST/]OWNER/REPO[@TAG] [--tag-before TAG]
```

Reuse a previous GitHub release as a lazy build cache instead of a
size-constrained, all-or-nothing CI cache (e.g. GitHub Actions cache). Verifies
the latest release (or the release with tag `TAG`) with GitHub's SLSA Level 2
attestation, saves its `values.json` to `<workspace>/etc/dk/i`, then seeds the
trace store (`t/c`) and lazy value pointers (`t/d`) by forcing the release's
distributions with `--import lazy`. Only the small `*.valuestore.index` files are
downloaded eagerly; individual value blobs are range-fetched on demand by the next
`distribute`.

If no matching release exists, no-op (exit 0).

If matching release can't be read, erases valuestore and tracestore to
maintain future incrementality.

#### Selecting the release with `--tag-before`

`--tag-before TAG` selects the most recent release before TAG with the same `MAJOR.MINOR`. The intended usage is for a GitHub workflow to set TAG
to the git tag it is currently building, and `restore` gets its cache
from the release that immediately preceded it.

`--tag-before` and `@TAG` are mutually exclusive.

If the GitHub workflow listing is unavailable from dk0's embedded GitHub
CLI (ie. no authentication, offline, or a `gh` error), it is
treated as "no candidate release" and `restore` degrades to a cold build.

A restore tag is `MAJOR.MINOR.TIMESTAMP`, where `TIMESTAMP` is one of
these UTC stamp formats:

| Digits | Form             | Example          |
| ------ | ---------------- | ---------------- |
| 8      | `YYYYMMDD`       | `20260701`       |
| 10     | `YYYYMMDDHH`     | `2026070100`     |
| 12     | `YYYYMMDDHHMM`   | `202607010017`   |
| 14     | `YYYYMMDDHHMMSS` | `20260701001730` |

Resolution algorithm:

1. Split `TAG` into `MAJOR.MINOR` and `TIMESTAMP`.
2. List the repository's release tags with the embedded `gh`, keeping only tags
   of the form `MAJOR.MINOR.TIMESTAMP` with the *same* `MAJOR.MINOR` line.
3. Compare timestamps by zero-padding each to 14 digits.
4. Keep the candidates whose padded timestamp is strictly less than `TAG`'s, and select the greatest. If none remain, that indicates a
   cold build (exit 0).

### Query commands

```text
invalidate [origin:ORIGIN:subpath:PATH]... [FILE.values.{jsonc,lua}]...
```

Invalidate matching traces, including other traces that depend on them.
`origin:...` invalidates assets obtained through `get-asset` whose `origin` is
`ORIGIN` and whose `path` is `PATH` or a descendant (empty `PATH` is all paths);
assets obtained through `get-bundle` are not invalidated. `FILE.values.jsonc` /
`FILE.values.lua` invalidate values in `FILE`.

```text
query
```

*(Unstable; options will change.)* List all build traces in the trace store. Exit
2 when there is an error reading the trace store.

## Options

### Command options

| Option                            | Meaning                                                                                                         |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `-s SLOT`                         | the slot name in the object or bundle, like `Release.Agnostic`                                                  |
| `-p ASSET`                        | the path of the asset in the bundle                                                                             |
| `-c COMMAND`, `--command COMMAND` | strictly relative command path inside the anonymous command directory                                           |
| `-f FILE`, `--file FILE`          | write to `FILE` (overwriting if it exists)                                                                      |
| `-d DIR`, `--dir DIR`             | write to directory `DIR` (creating it if needed)                                                                |
| `-n STRIP`, `--strip STRIP`       | when writing to a directory, strip this many leading path components [default: 0]                               |
| `-m MEMBER`, `--member MEMBER`    | when writing to a tar archive, only extract `MEMBER`; for run-object/run-asset it also implies the command path |

### Global options

Use `--` to separate the global options from the command and its arguments.

- `-help`, `--help` - show help and exit.
- `--version` - show version information and exit.
- `-v`, `--verbose` - show command lines while building; show values when complete. Repeat for more verbosity (max three).
- `--quiet` - don't show progress status; command lines still shown with `-v`.
- `--global` - set defaults to XDG directories under the `dk` program name.
- `--install PROGRAM` - *[caution]* install files to XDG directories under `PROGRAM` for forms with XDG variables (`${STATE}`, `${CACHE}`), and to home directories for `${HOME}`.
- `-I DIR` - include directory to search for `values.json[c]` and `*.values.json[c]` (also library subdirectories, e.g. `DIR/SomeLibrary_Std/values.json`). Repeatable.
- `--cell NAME=PATH` - add a subdivision of project source code with the given `NAME` and `PATH`; later cells override earlier cells with the same name.
- `-C DIR` - change to `DIR` before doing anything else.
- `--execution-abi ABI` - set the `execution_abi` wildcard; defaults to the ABI of this build executable (e.g. `Darwin_arm64`, `Windows_x86_64`).
- `--target-abi ABI` - set the `target_abi` wildcard; defaults to `--execution-abi`.
- `-d MODE` - enable debugging (`-d list` lists modes).
- `-x TARGET`, `--invalidate TARGET` - invalidate `TARGET` before running the command; like `invalidate` but saved only if the command succeeds. Repeatable.
- `--import lazy|eager` - import values from distributions lazily, or all values for all slots at once [default: `lazy`].
- `-a`, `--autofix` - *[caution]* automatically fix problems like incorrect checksums.

#### Build metadata

- `-t BUILD_TIMESTAMP`, `--build-timestamp BUILD_TIMESTAMP` - from the ISO-8601 `BUILD_TIMESTAMP` (`2021-02-03T04:05:06Z`), set the semver "build metadata" for invalidated and new objects' versions to `bn-YYYYMMDDhhmmss`.
- `-P BUILD_PERIOD`, `--build-period BUILD_PERIOD` - as `-t`, modulo `BUILD_PERIOD`. Suffixes: `s` seconds, `m` minutes, `h` hours, `d` days.
- `-n BUILD_NUMBER`, `--build-number BUILD_NUMBER` - set the build metadata to `bn-BUILD_NUMBER` (omit the `bn-` prefix).

The build metadata is constructed from `dk0`'s `-t TIMESTAMP` command-line
option in the `bn-YYYYMMDDhhmmss` format. In CI, pass the commit timestamp:

```yaml
# GitHub Actions
run: dk0 -t "${{ github.event.head_commit.timestamp }}" ...
```

```yaml
# GitLab CI
- dk0 -t "$CI_COMMIT_TIMESTAMP" ...
```

### Security options

- `--integrity none|existence|checksum` - verify the local value store against the trace store. `none` is fastest but can't tell if values are evicted; `existence` checks for the existence of values (fetching from a remote value store if present); `checksum` is slowest, skips any value read without a constructive-trace entry, and removes it if permitted [default: existence].
- `--random-seed SEED` - seed the RNG for operations needing randomness (e.g. signing build files). Highly insecure but allows reproducible trace/value stores; if unset, a seed is generated from system entropy.
- `--trust-local-package PACKAGE_ID` - allow loading distributions from `PACKAGE_ID` even if their signatures cannot be verified. Repeatable.
- `--dangerously-trust-all` - skip all trust prompts and allow every privileged operation. Don't do it.
- `--keys-env ENV_PREFIX` - use `<ENV_PREFIX>_PUBKEY` and `<ENV_PREFIX>_SECKEY` as the build public/secret key (lines may be separated with pipes or newlines).
- `--keys-dir DIR` - directory for the `build.pub`/`build.sec` keys [default: `<workspace>/t/k`, or `<xdg config>/dk` with `--global`].

### Configuration options

- `--data-dir DIR` - data files [default: `<workspace>/t/d`, `--global`: `<xdg data>/dk`].
- `--cache-dir DIR` - transient cache files [default: `<workspace>/t/c`, `--global`: `<xdg cache>/dk`].
- `--valuestore DIR` - the value store for assets and intermediate build artifacts [default: `datadir/val.1`].
- `--tracestore DIR` - the trace store for successful builds and their dependent assets/artifacts [default: `datadir/cts.1`].

### Include paths

- `-I DIR` - include directory (see Global options).
- `-isystem DIR` - add `DIR` to the system include directories.
- `-nobuiltininc` - do not include built-in modules like `MlFront_Attestation.GitHubCLI`.
- `-nosysinc` - do not include the system include directories (the `etc/dk/i` directory where `dk0` is installed) or any `-isystem` dirs.
- `-noworkspaceinc` - do not include the workspace include directories (`etc/dk/i` and `etc/dk/v` in the workspace).

### Display options

- `--errors-color` / `--errors-plain` / `--errors-pretty` - control error-message formatting [default: plain if `CI=true`, otherwise color].
- `--ancestor-graph FILE` / `--dependency-graph FILE` - at exit, print a DOT-format ancestor/dependency graph to `FILE` or stdout (`-`).

### Advanced options

- `--print-platform-ids` - print platform-specific ids that affect cache ids.
- `--print-config` - print configuration and exit.
- `--wait-trace-store` - when multiple builds run in the same directory, wait for the trace store to become available (nothing printed while waiting).
- `-f FILE` - a package search start file: the directory of `FILE` is implicitly added with `-I DIR`, and ancestor directory names form a package id for forms without one.
- `-p PACKAGE`, `--package PACKAGE` - the package for forms without explicit package ids [default: inferred from parent directories].
- `--long` - use long identifiers to avoid collisions (on Windows, enable long paths first).

## Reference implementation behavior

Behavior that is specific to `dk0` and may differ in other implementations.

### Lua interpreter

`dk0` uses a pure-OCaml version of Lua (`lua-ml`), which is fully type-safe,
re-entrant, and can have Lua evaluations bounded in time and
sandboxed to the project directories. The internal table of packages is stored in
an OCaml analog of the [Lua C registry](https://www.lua.org/manual/5.4/manual.html#4.3).

- Lua scripts should minimize the use of global variables. `dk0` does not yet
  enforce the complete removal of global variables, but
  [it will in the future](https://github.com/diskuv/dk/issues/55).
- *bug:* `string.len( "a\000bc000" )` is 9 in `dk0`
  (<https://github.com/diskuv/dk/issues/54>).

### Limits and platform quirks

- A few internal buffers are bounded by `dk0`'s `Sys.max_string_length` limit on
  32-bit systems.
- The byte positions, lines and columns embedded in the AST for error reporting
  are Unix byte positions. On Windows the byte positions may be inaccurate if the
  JSON file is checked out by `git` with CRLF endings; this may be fixed if `dk0`
  moves exclusively to lines and columns.
- `dk0` only recognizes the `OSFamily` property (as of 2025-11-09).
- The `execution_abi` wildcard defaults to the ABI of this build executable; it can
  be set by `dk0` (see `--execution-abi`).

### Change detection

The [Specification] does not mandate how change detection is implemented. `dk0`
scans all the globs at startup, with optimizations to skip directories it can
prove will never match a glob. Invalidation can be forced with the `--invalidate
TARGET` [global option](#global-options).

### Assets and the library cell

When a `unified.asset` declaration runs, the origin is named after the library id
and its mirrors are set to the library cell. In `dk0`:

- when run with a directory-based unified script (e.g. `dk0 test unifiedscript.u/`),
  the library cell is set to the unified-script directory while the script is
  evaluated
- when the unified script being evaluated is the [workspace script],
  the library cell is set to the directory containing the workspace script
- the `dk0 combine` command can adjust the mirrors permanently during distribution.

[workspace script]: SPECIFICATION.md#workspace-script

In the workspace, asset libraries are implicitly trusted, so no
`--trust-local-package ASSET_LIBRARY` is needed to access the workspace assets.

> [!NOTE]
> *`dk0` reference implementation behavior*
>
> In the [workspace script], if the
> [existing output block] has a size and checksum then the
> asset's size and checksum won't be recomputed. The workspace script is
> re-evaluated only when the `update` command is issued.
>
> The precise behavior depends on which unified script the `unified.asset`
> declaration is in and how it was reached:
>
> | When `unified.asset` runs in… | What happens |
> | --- | --- |
> | A unified test or distribution script that is *not* the workspace script | The asset's file or directory contents are always read to calculate its size and checksum. |
> | The workspace script | If the existing output block under the asset's command already contains size and checksum, those values are reused. Otherwise the asset is always read to recompute them. |
> | An `update`-style command refreshing the workspace script | The asset is always read to recompute the size and checksum. |

[existing output block]: SPECIFICATION.md#unifiedexistingoutput

### Distributions

- `dk0 add` places distribution metadata in the source tree at
  `<workspace>/etc/dk/i/<LIBRARY>-<VERSION>.values.json`.
- `dk0 add` places *lazy* value files in the value store by default, to avoid the
  time and space to download every binary artifact from a distribution.
- `dk0 add` downloads an internal copy of the GitHub CLI and uses it to download from
  GitHub releases and validate attestations.
- `dk0` accepts only the JSON request derived from command-line name-values.
  There is no ability today to accept the form document directly from an HTML
  form (per the W3C HTML JSON Forms specification) or a JSON document.

### Values

- A `values.lua` file added to the valuestore is an in-memory file in `dk0`.

### Other behavior

- Before submitting work, `dk0` prints the resolved inner argument vector (it can
  pass the exact argument vector to a subshell/remote engine).
- `dk0` prompts the user and asks for confirmation before running a program.

## Bootstrap scripts

The reference implementation is a single-file executable.
A `dk0` shell script (Unix) and a
`dk0.cmd` Windows batch script are also available that bootstrap and run the single-file executable.
They rely on a small set of external tools per platform; a different implementation may
use different tools or none at all.

### Windows

| File                     | What                                                                   |
| ------------------------ | ---------------------------------------------------------------------- |
| `pwsh` in PATH           | `enter-object` interactive shell (optional; searched 1st)              |
| `powershell` in PATH     | `enter-object` interactive shell (optional; searched 2nd)              |
| `cmd` in PATH            | `enter-object` interactive shell (fallback; searched last)             |
| `powershell.exe` in PATH | `dk0.cmd` batch script - for InvokeWebRequest (optional; searched 1st) |
| `bitsadmin` in PATH      | `dk0.cmd` batch script - for download (fallback; searched last)        |
| `certutil` in PATH       | `dk0.cmd` batch script - verify sha256sums                             |

### macOS

| File                | What                                                              |
| ------------------- | ----------------------------------------------------------------- |
| `/usr/bin/codesign` | executables are locally signed when `-e GLOB_PATTERN`             |
| `/bin/sh`           | `enter-object` interactive shell unless `SHELL` env var set       |
| `/bin/sh`           | `dk0` shell script                                                |
| `/usr/bin/shasum`   | `dk0` shell script                                                |
| `/usr/bin/curl`     | `dk0` shell script (optional; searched 1st)                       |
| `/bin/curl`         | `dk0` shell script (optional; searched 2nd)                       |
| `/usr/bin/wget`     | `dk0` shell script (optional; searched 3rd)                       |
| `/bin/wget`         | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/mv`       | `dk0` shell script (optional; searched 1st)                       |
| `/bin/mv`           | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/rm`       | `dk0` shell script (optional; searched 1st)                       |
| `/bin/rm`           | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/uname`    | `dk0` shell script (optional; searched 1st)                       |
| `/bin/uname`        | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/awk`      | `dk0` shell script - to parse sha256sums (optional; searched 1st) |
| `/bin/awk`          | `dk0` shell script (fallback; searched last)                      |

### Linux / BSDs / MSYS2 / Cygwin

| File                 | What                                                              |
| -------------------- | ----------------------------------------------------------------- |
| `/bin/sh`            | `enter-object` interactive shell unless `SHELL` env var set       |
| `/bin/sh`            | `dk0` shell script                                                |
| `/usr/bin/shasum`    | `dk0` shell script (optional; searched 1st)                       |
| `/usr/bin/sha256sum` | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/curl`      | `dk0` shell script (optional; searched 1st)                       |
| `/bin/curl`          | `dk0` shell script (optional; searched 2nd)                       |
| `/usr/bin/wget`      | `dk0` shell script (optional; searched 3rd)                       |
| `/bin/wget`          | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/mv`        | `dk0` shell script (optional; searched 1st)                       |
| `/bin/mv`            | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/rm`        | `dk0` shell script (optional; searched 1st)                       |
| `/bin/rm`            | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/uname`     | `dk0` shell script (optional; searched 1st)                       |
| `/bin/uname`         | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/awk`       | `dk0` shell script - to parse sha256sums (optional; searched 1st) |
| `/bin/awk`           | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/cygpath`   | `dk0` shell script (optional)                                     |
