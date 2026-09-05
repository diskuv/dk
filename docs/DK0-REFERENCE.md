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

A recipe may declare trust statements (its `trust` array), each mirroring
`dk0 trust accept PACKAGE [--key PUBKEY] [--run] [--write]`. The statements
are rendered on the quickstart's page, and before anything is scaffolded the
engine prints them and records them as durable acceptances in the new
workspace's `etc/dk/t/acceptances.json`, so the imports that follow accept
the declared producer keys without a prompt. An interactive session confirms
the printed statements once (`y/N`, deny at end of input) before they are
recorded; declining aborts with nothing recorded or written. A pinned `key`
means an import presenting a different key is denied. When the recipe imports
a package its trust statements do not cover, a non-interactive session fails
before scaffolding with a copy-pasteable `trust accept` command naming every
uncovered package.

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
signify -C [-q] -p pubkey [-x sigfile] -m checksums [file ...]
signify -G [-c comment] -p pubkey -s seckey
signify -S [-x sigfile] -s seckey -m message
signify -V [-q] [-p pubkey] [-x sigfile] -m message
```

Create and verify cryptographic signatures: `-G` generates a key pair, `-S` signs
a message, `-V` verifies a message against a signature, and `-C` verifies a signed
checksum list and then the checksum of each file (all listed files when none are
given). Unlike OpenBSD signify, `-C` takes the checksum list as a separate `-m`
file with a detached `-x` signature (no `-e` embedded signatures); the list may be
in BSD `sha256(1)` format (`SHA256 (FILE) = HEX`) or coreutils `sha256sum(1)`
format (`HEX  FILE`), with SHA256 and SHA512 checksums supported.

```text
zip ZIPFILE[.zip] [SRCFILE...]
```

Create or update a zipfile. Without `SRCFILE`, all files under the source
directory are added. `-srcdir DIR` sets the source directory; `-d` deletes
entries; `-x PATTERN` excludes a glob; `--deterministic` creates a reproducible
zipfile.

The same command is available inside a values file's `function.commands` as
the `["--zip", ...]` special form, which runs in-process and always produces a
deterministic zipfile. See the SPECIFICATION for details.

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
`oc414_wd64` - see `--print-platform-ids`). A `./PART.distmeta.manifest.zip`
seals the manifest inputs (the workspace `dk.u`, this part's distribution
script, and any `etc/dk/v/*.values.jsonc`) as a bundle asset for the
`inspect` command; importers never fetch it. Overwrites
`distributions[].producer.application` with the current `dk0` version or
`--with-producer-version`.

- `--no-valuestore` disables creation of `valuestore.zip`.
- `--diff`/`--actual`/`--actual-in-place` behave as in `test`.
- `--prepare-dir DIR` finds keys in `DIR` (default `etc/dk/d`).
- **exit 3:** there is one or more diff of actual vs expected.

Objects and rules are public interfaces, so only their transitive values are
included; bundle files and assets are included only if an object or rule
transitively has `get-asset`/`get-bundle` precommands.

When `--target-abi` names an ABI other than `--execution-abi`, objects whose slot
came from the `execution_abi` wildcard are computed but not published: they are
the host's slots, and the run that targets that ABI publishes them. Objects whose
rule named a literal `execution_slot` are published whatever their terms spell.
See "Object Slots" in the [Specification].

When the build key is the distribution producer key (for example the
distribution key that the dk-distribute CI action passes with `--keys-env`),
`distribute` also signs the distribution's canonical build payload and records
the signature as `build.attestation.openbsd_signify`. A local build's
auto-generated workspace key is not the producer key, so the attestation anchor
stays empty there.

```text
combine [--origin-name <origin-name>] [--mirror <origin-url>]*
```

Combine `dk-dist/*.values.json` from many `distribute PART` runs into a single
`dk-dist/values.json` containing one or more distributions. Any `--mirror`
`origin-url` become the bundle mirrors for the origin named `local`, which is then
renamed to `origin-name`. (`dk0 combine` can also adjust the mirrors permanently
during distribution.)

The combined build differs from every part, so combining clears the per-part
build signatures. With the global `--keys-env` option, `combine` re-signs each
combined distribution's canonical build payload with the distribution key; the
key must be the distribution's `producer.openbsd_signify` key.

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

Both commands (and `restore github-l2` and `remote-result import`) also enforce
the consumer-side signify trust model (see the Security section): embedded
signify signatures must verify against the release's `producer.openbsd_signify`
public key, the monotonic key-rotation rules hold against the releases already
imported in `DIR` and the local trust records in `<workspace>/etc/dk/t`,
and a producer key with no trust anchor (the built-in dk vendor root, a locally
prepared key in `etc/dk/d`, a signed continuation chain, a durable
`dk0 trust accept` record, or `--trust-local-package`) is denied unless
interactively accepted. The prompt denies at end of input, so unattended CI
fails closed. Record a durable acceptance ahead of the import with
`dk0 trust accept PACKAGE_ID` (add `--key PUBKEY` to pin a key obtained
out-of-band, so a first import over a compromised channel is denied), or pass
`--trust-local-package LIBRARY` to accept a known producer for the current
invocation only. An interactive acceptance, a `dk0 trust accept PACKAGE_ID`
record with no `--key`, and `--trust-local-package` each accept the producer
key the import presents, whichever key that is; a pin accepts one named key.
`import local` records each accepted release in `etc/dk/t` so later imports can
anchor on it.

```text
inspect github-l2 -R,--repo [HOST/]OWNER/REPO [--tag TAG] [--outdir DIR]
inspect local --path VALUES.JSON [--outdir DIR]
```

`inspect` is for documentation, catalog rendering, and audit that wants to
validate a release without the cost of a full import. It verifies a release
exactly like the matching `import` command - GitHub SLSA Level 2 attestation for
`github-l2`, then the consumer-side signify trust model above - but instead of
importing the package payload it fetches **only** the small distmeta and
extracts two artifact classes into separate directories:

- `DIR/LIBRARY.VERSION.script-modules/` - the exported `*.values.lua` script
  modules: the executable rules the release will run on a consumer machine,
  extracted so a reviewer can audit them before trusting the release.
- `DIR/LIBRARY.VERSION.dist-scripts/` - the distribution scripts the producer
  sealed at `distribute` time (the workspace `dk.u`, the `dist/*.u`
  distribution scripts, and any `etc/dk/v/*.values.jsonc`), laid out like the
  package working tree. Render a **verified manifest** from them with
  `dk0 query manifest -f DIR/LIBRARY.VERSION.dist-scripts/dk.u`.

No package values or traces are imported and there is no transitive discovery.
`inspect local` is the offline counterpart: same trust checks, same extraction,
against a local `VALUES.JSON`. A release produced by a dk0 that predates
manifest sealing extracts zero distribution scripts (the script modules still
extract). The sealed files are listed in the release bundle with checksums, so
they are covered by the signed build payload and the release attestation;
importers never fetch the manifest zip.

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

#### HOWTO: Change the producer (attestation) repository

Background: The GitHub repository that `prepare-version --ci github` prints in its
`gh api .../environments/dk-distribution` and `gh secret set --repo ...` commands
comes from `producer.github_slsa_v1_l2.repository` (or the SLSA L3 caller repository if set)
in your latest existing `etc/dk/d/*.dist.json`. This same field is the SLSA
attestation subject a consumer verifies at `import-github-l2`.

To point a new version's keys, secrets, and attestation at a different
repository, the safe sequence is:

1. Temporarily edit `"repository"` in the **latest existing** version's
   `etc/dk/d/<prev>.dist.json` to the new repository.
2. Run `prepare-version --ci github <new MAJOR.MINOR>`. The generated
   `<new>.dist.json`, workflow, and printed `gh` commands now target the new
   repository.
3. Revert the `"repository"` change in the old `<prev>.dist.json` so it
   still reflects how that already published version was attested.

When the consumer uses dk0 it will verify the SLSA attestation
against the previous repository, so consumers must be told to update their
`import` expressions in `dk.u` to the new repository for the new version.

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

### Trust commands

```text
trust list
trust accept PACKAGE_ID... [--key PUBKEY] [--run] [--write]
trust grant (PACKAGE_ID | --values-sha256 HEX) [--run] [--write]
trust revoke (PACKAGE_ID | --values-sha256 HEX) [--run] [--write]
```

`trust` manages the workspace trust records that let signed imports be accepted
and let UI rules perform privileged `request.ui` actions without an interactive
prompt. The records live in `<workspace>/etc/dk/t` and are committable, so a
repository carries its trust decisions into CI.

The trust commands anchor `etc/dk/t` at the nearest workspace within the
current repository. In a directory with no `dk.u`, and in a repository whose
only enclosing workspace belongs to another checkout, the records anchor at
the current directory: a `trust accept` issued in a project before its
`quickstart` lands in that project, where the quickstart-created workspace's
import reads it.

`trust list` is the audit surface for the whole signify trust model. It prints
one line per entry, each producer key shown in full so it can be compared
against a known-good key: the built-in vendor root, the locally prepared author
keys, the producer keys anchored by prior imports, the explicit capability
grants, the durable acceptances, the grantable local identities, and the import
ledger that activates producer-key grants.

A producer key anchored by a prior import prints as `anchor imported` only when
this workspace has *verified* the import, which happens when its content is in
the `etc/dk/t/imports.json` ledger. A committed `etc/dk/i` record that a fresh
clone carries but has not verified yet (no `update` has run) prints as
`anchor unverified-import` instead, and `trust list` names `update` as the
remedy. This keeps `trust list` from showing a producer anchor that the
execution-time trust check would still treat as unsigned local content.

`trust accept PACKAGE_ID` records a durable acceptance of the package's
producer key in `etc/dk/t/acceptances.json`. The next import of the package
accepts the key it presents and pins it, exactly as an interactive acceptance
would, and the record is visible to `trust list` and removable with
`trust revoke`. The record carries no local-resolution meaning, so it is the
consumer-side lever that `--trust-local-package` is not. Several PACKAGE_IDs may
be accepted in one command (for example to cover every producer key a
`quickstart` template imports); `--key` then applies to a single PACKAGE_ID
only, while `--run`/`--write` apply to every named package, so pass them only
for packages that need those capabilities.

`trust accept PACKAGE_ID --key PUBKEY` pins the expected producer key, the full
OpenBSD signify public key obtained out-of-band (for example from the package's
page on diskuv.com). Every import of the package whose producer key differs
from the pin is denied, the first one and each one after it, so an import over
a compromised channel is denied for as long as the record stands.

`trust accept PACKAGE_ID --run` / `--write` record pending capabilities that
resolve into ordinary producer-key grants at the first successful import. Until
that import the acceptance shows as `state=pending` in `trust list`; after it
the acceptance shows as `state=resolved` and the grant is indistinguishable
from one written by `trust grant`.

`trust grant PACKAGE_ID` grants a capability to a package that is already
imported. It resolves the package's current producer signify key from the
imported releases in `etc/dk/i` and the trust records in `etc/dk/t`, and grants
to that key: the full public key material, never the displayed fingerprint.
When no imported release carries a producer key, the grant falls back to the
package's keyless local distribution records and binds their values-file
content hashes. `trust grant --values-sha256 HEX` grants to unsigned local
content addressed by its dos2unix-ed values-file SHA-256.

The capabilities are `--run` (run programs: `request.ui.spawn` and
`request.ui.capture`) and `--write` (write files: `request.ui.writefile`).
`grant` requires at least one; `accept` treats them as optional. `revoke`
without a capability removes the whole grant, and `revoke PACKAGE_ID` also
removes the matching acceptance.

A UI rule may declare the capabilities it needs in a `uirule_capabilities` field
of its module table (see the Specification). When a rule declares its
capabilities, a `request.ui` call for a capability it did not declare is denied
without a prompt (the declaration is an enforced upper bound, not widened by any
trust flag), and a `trust grant` command suggested for the rule lists every
declared capability so one grant covers it. A rule with no declaration is
prompted for each capability as it first requests it.

#### Committing imports for clone-and-build repositories

A repository can carry its trust decisions so a fresh clone builds without
re-deciding them. Commit the import records (`etc/dk/i/*.values.json`), the
capability grants (`etc/dk/t/capabilities.json`), and the acceptances
(`etc/dk/t/acceptances.json`). Do **not** commit `etc/dk/t/imports.json` or the
`etc/dk/t/*.values.json` copies: those are the machine-written, per-workspace
record that this workspace *verified* an import, and the `.gitignore` `dk0`
writes keeps them out of git.

Because the verification ledger is per-workspace, a fresh clone holds import
records it has not verified yet. One `dk0 update` verifies them against their
GitHub attestation and producer signatures and writes the ledger, after which
the committed package grants and resolved acceptances apply. A privileged
`dk0 dialog` also verifies the committed imports on its own first (offline,
using the producer signatures and the committed acceptances), so cloning a
repository that commits its `acceptances.json` and running a dialog works with
no extra step; when a producer key is not anchored, the dialog reports the
import as unverified and names `dk0 update`. Until an import is verified, a rule
from it is treated as unsigned local content and a package (producer-key) grant
does not apply to it.

`trust accept` covers authenticity: it anchors each named package's producer
key (optionally pinned with `--key`), and its `--run`/`--write` become grants at
the first verification. `trust grant --values-sha256` grants are for local
unsigned development only: they pin one release's file content and go stale on
every release, so a committed repository grants by package instead.

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

```text
query manifest [-f WORKSPACE.u] [--markdown] [--outfile FILE] [--version VERSION]
```

Read a dk package's local working tree (`dk.u` workspace script and `dist/*.u`
or `dist-*.u/run.u` distribution scripts) and emit a `dk.package-manifest/2`
JSON document to stdout (or `--outfile FILE`).

`query manifest` performs no distribution verification by design: it reads the
local working tree so authors can preview a manifest before any release exists,
and it logs an UNVERIFIED warning to standard error on every run. A consumer that
renders manifest output (for example a package catalog) should render from
verified release data instead: `dk0 inspect github-l2 -R OWNER/REPO` verifies the
release and extracts its sealed distribution scripts, then
`dk0 query manifest -f <outdir>/LIBRARY.VERSION.dist-scripts/dk.u` renders the
manifest from that extracted tree (see the `inspect` command above).

| Flag | Meaning |
| --- | --- |
| `-f WORKSPACE.u` | Explicit workspace file path. Defaults to nearest ancestor `dk.u` with a `## Workspace` section. |
| `--markdown` | Emit Markdown (overview + body) instead of JSON. |
| `--outfile FILE` | Write output to `FILE` instead of stdout. |
| `--version VERSION` | Set the `package.version` field. Required unless the package provides one. |

The `schema` field identifies the manifest format and its version, currently
`dk.package-manifest/3` (version 3). The version number increases whenever the
JSON structure changes in a way that could break a reader; a tool can check it
before reading. The top-level fields are `schema`, `package`, `licenses`,
`platforms`, `assets`, `modules`, `dependencies`, `overview`, and `body`.
Module kinds are inferred from the distribution scripts: `apparatus` (workspace
assets via `% unified.asset`), `bundle` (title contains `.Bundle@`),
`scriptmodule` (has `run` or `post-object` commands), and `object` (has
`\dk.object` metadata or `get-object` commands in the expected output).

Each module has a `builds` list (one entry per `\dk.object`, with `platform`,
`abi` and `valueId`) and, when the module runs `get-asset`, an `assets` list
(one entry per `\dk.asset`, with `path`, `valueId` and `byteSize`). Object
builds have no size. Object payload bytes are not deterministic across builds,
which rules out size as a stable identifier. Asset value blobs are content
addressed and keep a deterministic `byteSize`.

Version 3 changed the format from version 2 by removing `byteSize` from each
build and adding the per-module `assets` list. Manifests produced before this
release use version 2 and still carry build sizes.

```text
sbom self [--pretty] [--outfile FILE]
sbom workspace [-f WORKSPACE.u] [--slot SLOT] [--timestamp now|RFC3339]
    [--pretty] [--outfile FILE]
sbom github-l2 [HOST/]OWNER/REPO[@TAG] [--outdir DIR] [--slot SLOT]
    [--verify-content] [--timestamp now|RFC3339] [--pretty] [--outfile FILE]
sbom local --path VALUES.JSON [--slot SLOT] [--verify-content]
    [--timestamp now|RFC3339] [--pretty] [--outfile FILE]
```

Emit a CycloneDX 1.6 software bill of materials as JSON (minified unless
`--pretty`; stdout unless `--outfile FILE`).

dk value ids are declaration-addressed: an object id hashes the module's
declaration text and slot, deliberately excluding the content of its build
inputs. Two releases can therefore
carry *different bytes under the same value id* (for example when a
non-bit-reproducible compiler is rebuilt), and a contaminated store can serve
one slot's bytes under another slot's id. Every component this command emits
records the value id *and* a `diskuv:dk:content:*` content digest of the
bytes actually present or consumed, so two releases (or a release and a
local store) can be compared with a plain `diff` of two `sbom` runs even
when their value ids are identical.

Subjects:

- `sbom self` prints the running `dk0`/`dk1` executable's own bill of
  materials, fully offline (like `--version`), from the opam lock
  (`dk.opam-lock.jsonc`) and `dk.u` compiled in at build time. It emits: one
  `library` component for the MlFront source (the `DK_SBOM_SOURCE_SHA256`
  digest as a `hashes[]` entry, and the `dk.u` `## License` expression as a
  `licenses[]` entry); one `framework` component for the OCaml toolchain from
  the lock's `ocaml` field; and one component per opam package in the binary's
  own slot, each with a `pkg:opam/NAME@VERSION` `purl`, the source archive
  checksums as `hashes[]`, and the archive URL as an `externalReferences[]`
  entry of type `distribution`. A top-level `dependencies` graph links each
  package to its resolved lock dependencies, and the opam-repository pins
  appear as `externalReferences[]` on the metadata component. The slot is the
  one the binary was built for (`DK_SBOM_SLOT` injected at release, recorded as
  `diskuv:dk:sbom:slot`; the host-detected slot in a dev build). Release builds
  inject the real values through the `DK_SBOM_SERIALNUMBER`,
  `DK_SBOM_TIMESTAMP`, `DK_SBOM_GITREF`, `DK_SBOM_SOURCE_SHA256`,
  `DK_SBOM_TOOLCHAIN_OCAMLCOMMON_SHA256` and `DK_SBOM_SLOT` build environment
  variables; a dev build shows placeholders (a zero-uuid serial, gitref `dev`)
  and the host slot. The opam lock records no per-package license fields, so
  third-party packages carry no `licenses[]` yet.
- `sbom workspace` reads only local data: the `\dk.import` pins recorded in
  `dk.u` (library, version, pin-file checksums), the transitive distributions
  from `etc/dk/i/dk-closure-manifest.tsv`, and every object/bundle/asset
  value recorded in the trace store. Each value carries the digest recorded
  at build/import time (`diskuv:dk:content:sha256:recorded`, from the trace)
  and the digest of the bytes now in the value store
  (`diskuv:dk:content:sha256`). A divergence is flagged
  `diskuv:dk:content:mismatch`. Values seeded by a lazy import whose bytes
  are not yet materialized are `diskuv:dk:content:state=lazy`.
- `sbom github-l2` verifies a GitHub release exactly like
  `inspect github-l2` (SLSA Level 2 attestation, then the consumer-side
  signify trust model; the attested `values.json` pins are saved to
  `--outdir`, default `<workspace>/etc/dk/i`), then inventories every
  per-slot value of the release from its tracestores, using the digests the
  producer recorded at distribute time. Only the small `values.json`, the
  tracestores and the valuestore indexes are downloaded, so diffing two
  releases is cheap.
- `sbom local` is the offline analog for a local `VALUES.JSON` distribution
  (a `dk-dist/` directory), with the same consumer trust checks as
  `inspect local`.

`--verify-content` (release subjects) additionally fetches every enumerated
value blob - a ranged download per value for `github-l2`, served from the
release's zip index - and re-hashes it locally, so the producer-recorded
digest is cross-checked against the bytes the release actually serves.

Output is byte-reproducible by design: `metadata.timestamp` is omitted by
default (`--timestamp now` or `--timestamp RFC3339` adds one) and
`serialNumber` is derived from the content (an RFC 4122 v5-style urn over
the SHA-256 of the serialized components), so identical inventories produce
identical bytes and `diff` shows only real changes.

Alongside the vendor properties below, components use the standard CycloneDX
elements where the data exists: `hashes` (content and pin digests, with the
CycloneDX algorithm names `SHA-256`, `SHA-512`, `MD5`, `SHA-1`,
`BLAKE2b-256`), `externalReferences` (archive and repository URLs), `licenses`
(SPDX expressions), and the top-level `dependencies` graph keyed by each
component's `bom-ref`. The `diskuv:dk:*` properties are retained for the
content and provenance details the standard elements do not carry.

Component properties (all in the `diskuv:dk:` namespace, all string valued):

| Property | Meaning |
| --- | --- |
| `diskuv:dk:subject` | `self`, `workspace`, `github-l2` or `local` (on the metadata component). |
| `diskuv:dk:gitref` | The source git ref the running binary was built from (`self` metadata component; `dev` in a dev build). |
| `diskuv:dk:source:sha256` | SHA-256 of the MlFront source zip the binary was built from (`self` metadata component). |
| `diskuv:dk:sbom:slot` | The slot the `self` inventory is taken for, e.g. `Release.Linux_x86_64` (`self` metadata component). |
| `diskuv:dk:origin` / `diskuv:dk:local` | `workspace` / `true` on the MlFront source and workspace-local opam components (`self`). |
| `diskuv:dk:import:type` | The import type of a `library` component (`github-l2`, `local`, `workspace`). |
| `diskuv:dk:import:pin:sha256` (also `:blake2b-256`, `:sha1`) | Checksums of the import's distribution pin file (`etc/dk/i/LIBRARY.VERSION.values.json`). |
| `diskuv:dk:import:transitive` | `true` on a distribution known only through the closure manifest. |
| `diskuv:dk:import:source` | For a transitive distribution, the direct pin file that carries it. |
| `diskuv:dk:origin:repo` / `diskuv:dk:origin:tag` / `diskuv:dk:origin:url` / `diskuv:dk:origin:path` | Where the release resolved from. |
| `diskuv:dk:value:id` | The declaration value id (`o...`, `b...`, `a...`, `i...`). |
| `diskuv:dk:value:kind` | `object`, `bundle`, `asset`, `assetindex` or `release-asset`. |
| `diskuv:dk:value:slot` | The object slot (objects only), e.g. `Release.Linux_x86_64`. |
| `diskuv:dk:value:asset-path` | The asset path (assets only). |
| `diskuv:dk:content:state` | `materialized`, `lazy` or `missing` (workspace subject only). |
| `diskuv:dk:content:sha256` / `diskuv:dk:content:size` | SHA-256 and byte size of the bytes actually present or fetched. |
| `diskuv:dk:content:sha256:recorded` | The digest recorded at build/distribute time (the producer claim). `blake2b-256`/`sha1` variants appear for declared release-asset checksums. |
| `diskuv:dk:content:mismatch` | Present when the recorded and computed digests both exist and differ. |
| `diskuv:dk:value:untracked` | `true` on a value present in the store without any covering trace (for example seeded by an import's payload replay); grouped under a `store-only` component (workspace subject only). |
| `diskuv:dk:toolchain:KEY` | A toolchain fingerprint entry read from the object (below). |

Toolchain fingerprint contract: a built object MAY carry a
`.dk/toolchain.properties` member at the root of its slot tree (the `.dk/`
directory inside an object is reserved for dk metadata). The file is plain
UTF-8 `key=value` lines; `#` starts a comment line. `sbom` surfaces every
pair verbatim as a `diskuv:dk:toolchain:KEY` property (sorted by key), so a
package's build-time toolchain (for example
`ocamlcommon-cmxa:sha256=...` recorded by an opam build wrapper) can be
compared against a live toolchain. Producers do not emit this file yet; this
paragraph defines the contract they should target.

A digest mismatch is *reported*, never fatal: `sbom` is descriptive and
exits 0 on success. Old releases whose tracestores predate recorded value
digests simply omit `diskuv:dk:content:sha256:recorded`; use
`--verify-content` to compute digests for those.

### Maintenance commands

```text
gc [info] [--prune-older-than DAYS] [--dry-run] [--empty-roots-ok]
```

Garbage collect the workspace stores with mark and sweep. Every top-level
dk0 command records the key it demands as a root in the root store
(`t/d/rts.1`, the same framed segment format as the constructive trace
store; machine local, never distributed or imported). `gc` marks the
dependency closure of recent roots through the trace store, then in
crash-safe order compacts the trace store to the live closure, compacts the
root store, deletes unreachable value store files, and removes per-process
scratch directories (`t/p/<pid>`, `t/x0/<pid>`). It also sweeps aged
`${RUNTIME}` script caches: each unified script gets a runtime directory
`t/xr/<uid>` whose uid hashes the script's content and location, so an
edited, renamed or removed script strands its old directory; the current
workspace script's directory stays live regardless of age, and any other
uid-shaped directory is swept once its age passes the retention window.
`gc` runs under the same exclusive trace store lock as builds, so it
cannot race a build.

Everything swept is re-buildable or re-downloadable; the signify keys
(`t/k`), user outputs (`t/o`, `t/s`), parsed-values caches, unrecognized
value ids and unrecognized `t/` entries are reported and never deleted.

| Flag | Meaning |
| --- | --- |
| `info` or `--dry-run` | Report what would be swept without deleting anything. |
| `--prune-older-than DAYS` | Roots recorded more than `DAYS` days ago stop pinning their dependency closure (default 30). Pinned roots never expire. |
| `--empty-roots-ok` | Proceed even when no live roots exist, which sweeps every value and trace. Without it `gc` refuses, because a workspace that predates the root store has no roots yet and would lose its whole cache. |

`gc` also refuses when the root store contains entries recorded by a newer
dk0 that this dk0 cannot understand.

```text
gc --pin COMMAND...
gc --unpin COMMAND...
```

Record (`--pin`) or remove (`--unpin`) a never-expiring root for the key
that the value shell `COMMAND` demands, without running the command. Use a
pin for something built too rarely to stay inside the retention window, for
example a release target or a large toolchain asset:

```text
dk0 gc --pin get-object MyLib_Std.Tool@1.2.0 -s Release.Agnostic -f tool.exe
dk0 gc --unpin get-object MyLib_Std.Tool@1.2.0 -s Release.Agnostic -f tool.exe
```

The command is parsed and resolved exactly like a real run (aliases and
subshells included) but is not executed. It must therefore be a complete
command - `get-object` still needs its `-f` or `-d` - but the output path
does not change the pinned key, so pin with the same command line you
normally run. A pin is exact: it covers the resolved `MODULE@VERSION` (and
slot or asset path), not other versions, so re-pin after a version bump.
`gc info` reports the number of pinned roots.

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
- `--trust-local-package PACKAGE_ID` - allow loading local distributions from `PACKAGE_ID`, and accept `PACKAGE_ID`'s producer key on import without the interactive accept/deny prompt. Repeatable. This is the producer/development lever for a local source tree, and its acceptance is per-invocation. For a consumer accepting a signed import, `dk0 trust accept PACKAGE_ID` records a durable acceptance without the local-resolution meaning. `--trust-local-package` never overrides signature verification or the key-rotation rules.
- `--dangerously-trust-all` - skip the `request.ui` capability prompts and allow every privileged rule action for the process. Don't do it: record explicit grants with `dk0 trust grant` (or an interactive `[a]lways` answer) instead. It never affects the import-time signify verification.
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

### Workspace directories

`dk0` keeps its durable workspace configuration under `etc/dk/` (transient
build state lives under `t/`; see the Configuration and Security options for
the `t/d`, `t/c` and `t/k` defaults). `dk0` drops a self-ignoring `.gitignore`
(`*`) into `t/` and each of its build directories, so a project keeps its `t/`
tree out of git without a hand-written `/t/` line. The `etc/dk/` directories
are:

| Directory | Contents | Written by | Read for |
| --- | --- | --- | --- |
| `etc/dk/d` | Prepared distribution keys: `<MAJOR.MINOR>.<PATCH>.dist.json` files carrying the producer public key and signed continuations for the version lines this workspace releases. Author-owned; commit them. | `prepare-version` | `distribute` and `combine` (signing); every import (the keys are locally prepared trust anchors). |
| `etc/dk/i` | The import directory: verified release `<LIBRARY>.<VERSION>.values.json` files, plus the `values.unattested.json` download scratch file. On the workspace include path, so the imported distributions resolve values and traces. The files double as prior-import trust anchors. Machine-written but committable, so a clone can carry them for clone-and-build (see "Committing imports for clone-and-build repositories"); `update` garbage-collects entries its resolution no longer uses, and an `import` prunes the strictly older releases it supersedes on the same `MAJOR.MINOR` line. | `add`, `import`, `restore`, and workspace `import` declarations | distribution resolution; prior-import trust anchoring. |
| `etc/dk/t` | Consumer trust records. Four kinds: **(1)** byte-identical copies of directly imported release values files (`<LIBRARY>.<VERSION>.values.json`), recorded only after the consumer trust checks pass; **(2)** `imports.json`, the machine-written import ledger. Each entry records a `values_sha256` (SHA-256 of the dos2unix-ed content) that an import/restore verification accepted, its `kind` (`record` for the imported `values.json` file, or `scriptmodule` for an exported `values.lua` whose hash the producer signed into `build_to_sign.build_script_module_sha256s`), and the distribution's producer `pubkey_base64`. A rule whose run-time content SHA matches a keyed entry is attributed to that producer; **(3)** `capabilities.json`, the human-authorized `request.ui` capability grants (`run`, `write`) keyed by producer public key (`pubkey_base64`) or by local values content (`values_sha256`); **(4)** `acceptances.json`, the durable `dk0 trust accept` records keyed by package name, each carrying an optional pinned producer key and optional pending capabilities that become grants at the first successful import. A `.gitignore` written by `dk0` keeps the machine-written records (1) and (2) out of git while leaving `capabilities.json` and `acceptances.json` committable so a repository can carry its trust decisions into CI. Deliberately **not** an include directory, so no values or traces are ever resolved from a record; a record only anchors the producer key and rotation of later imports, gates producer-key grants (ledger), carries grants, or carries acceptances. | `import local` (record copies); every `import`/`restore` (ledger, and acceptance resolution); `trust grant` and the capability prompt's `[a]lways` answer (grants); `trust accept` (acceptances) | prior-import trust anchoring; producer-key grant activation (ledger); `request.ui` capability decisions (grants); import-time key acceptance (acceptances). |
| `etc/dk/v` | Authored values files (`*.values.jsonc`, `*.values.lua`) belonging to the workspace. On the workspace include path. `distribute` seals them into the distribution manifest together with the workspace script and `dist/*.u`. | the workspace author | distribution resolution; manifest sealing. |

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
> asset's size and checksum won't be recomputed. The block is the
> `\dk.asset(byteSize: "...", checksum: (sha256: "..."))` metadata markup;
> the legacy three Lua value lines (`'asset'`, size, checksum) that predate
> the markup are still read so already-published packages keep working, and
> `update` rewrites them to the markup. The workspace script is
> re-evaluated only when the `update` command is issued.
>
> The precise behavior depends on which unified script the `unified.asset`
> declaration is in and how it was reached:
>
> | When `unified.asset` runs in... | What happens |
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
- `dk0` asks for confirmation before a rule runs a program or writes a file,
  unless a matching capability grant is recorded (`dk0 trust grant` or a prior
  `[a]lways` answer; see Security).

## Security

This section documents the controls that protect a *distribution* (a signed,
released build) and the trust decisions `dk0` makes when it imports or builds one.
The underlying model is in the [Specification] "Attestations" and "OpenBSD signify
keys" sections; the value-store protections are in `SECURITY.md`.

### Controls and entry points

| Control | Entry point | Enforced on consumption |
| --- | --- | --- |
| GitHub SLSA Level 2 attestation | `import github-l2`, `inspect github-l2`, `restore github-l2` | Yes. The release `values.json` is verified with `gh attestation verify` against the Sigstore trusted root, scoped to `-R OWNER/REPO`; a failed verification is fatal. |
| OpenBSD signify signing of a distribution | `prepare-version` (key generation); `distribute` and `combine` (signing); every import (verification) | Yes. `distribute` signs the canonical build payload (`ThunkDist.canonical_build_payload_id`) when the build key is the distribution producer key (the dk-distribute CI action passes it with `--keys-env`), and `combine` re-signs the combined distribution the same way. On `import github-l2`, `import local`, `restore github-l2` and `remote-result import`, the signed continuations must verify against the `producer.openbsd_signify` public key, and the `build.attestation.openbsd_signify` signature (when present) must verify over the canonical build payload. A present-but-invalid signature is fatal (`SecConsumerTrust`). |
| Key rotation via signed continuations, monotonic per `MAJOR.MINOR` | `prepare-version`, `distribute` (author); every import (consumer) | Yes. `SecPackageRegistry.characterize` runs on both sides. A producer key is imported once and never overwritten (no key may reclaim an established `MAJOR.MINOR`); a new `MAJOR.MINOR` must carry the continuation key a trusted prior release signed; a release below the latest imported release is rejected (`restore` falls back to a cold build). |
| Vendor-key trust root and deny-by-default acceptance | every import | Yes. Trust anchors, in order: the built-in dk signify key for `CommonsBase_Std`, locally prepared keys in `etc/dk/d`, previously imported releases (the import directory `etc/dk/i` plus the local trust records in `etc/dk/t`), a durable `dk0 trust accept` record (optionally pinned to a key; a pin mismatch is fatal), and the documented `--trust-local-package` escape hatch. Any other producer key gets an interactive accept/deny prompt that defaults to deny and denies at end of input, so CI fails closed. Transitive distributions recovered from a directly imported release are verified (signatures and rotation consistency) before their content-pinned acceptance, and never anchor a directly imported release's rotation. |
| Value-store integrity of Marshal-ed ASTs | build / `get-object` path | Yes. A SHA-256 prefix guards each Marshal-ed AST and is signify-signed with a per-workspace build key (`SECURITY.md`). |
| Rule-capability consent for `spawn` / `capture` / `writefile` / `selfignore`, keyed by signify provenance | `request.ui.*` (`BuildRequestUi`, `SecUiCapability`); `trust list/accept/grant/revoke` | Yes. Deny-by-default prompt before a rule first exercises a capability: `run` (running a program, `request.ui.spawn` and `request.ui.capture`, gated identically so capture cannot bypass a spawn denial) or `write` (`request.ui.writefile` and `request.ui.selfignore`); fails closed with no TTY, naming `dk0 trust grant`. The prompt identifies the rule by its signify provenance: the producer key fingerprint and `package@version` for a rule from an imported, signature-verified distribution, or the values-file SHA-256 for a host script or local rule. Answering `[a]lways` (or `dk0 trust grant`) persists the grant in `etc/dk/t/capabilities.json`, keyed by the full producer public key (never the fingerprint, which is the attacker-choosable keynum) or by content hash; `[y]es` allows once. A producer-key grant is honored only for values content whose SHA-256 is recorded in the `etc/dk/t/imports.json` ledger against that producer, because the producer signs each exported script module's content hash into `build_to_sign.build_script_module_sha256s`, and import records it after verifying the signature, so content tampered after import (or a local squatter) falls back to the content-hash prompt. Key acceptance at import never confers a capability, though `dk0 trust accept PACKAGE_ID --run`/`--write` records pending capabilities that become the same producer-key grants at the first successful import. The process-wide `--dangerously-trust-all` is a separate command-line escape hatch; the isolated `dk0 remote` path additionally allows the single, producer-trusted orchestration rule it runs without a prompt. The prompt warns when a program is a bare name resolved through `PATH`. |
| Windows executable-search hardening | `dk0` process startup (`Shell.ml`) | Yes. On Windows `dk0` sets `NoDefaultCurrentDirectoryInExePath`, removing the current directory from the executable search for every program it spawns (rule spawns, precommands, function commands and subshells), so a program named by a bare name is found only through `PATH`, never from an executable dropped into the working directory. |
| Build-state exclusion from globs | `request.ui.glob` (`BuildRequestUi`) | Yes. The signify keys directory (holding `build.sec`), the data directory and the cache directory are never enumerated, so a rule cannot route `build.sec` or other build state into a content-addressed bundle. |
| `signify` primitive (keygen / sign / verify / checksum lists) | `signify -G` / `-S` / `-V` / `-C` | The OpenBSD signify implementation (`MlFront_Signify`), including `-C` verification of a signed SHA256/SHA512 checksum list against its files. |

### Trust model

- **Attestation is required.** `dk0` rejects assets and objects produced without a
  trusted attestation. Two sources are recognized: a human OpenBSD signify
  signature, or GitHub Actions SLSA Level 2/3.
- **`import github-l2` verifies two anchors.** The release must carry a valid
  GitHub/Sigstore attestation for the `OWNER/REPO` on the command line, and its
  producer signify key must anchor to the built-in dk vendor root, a locally
  prepared key, a trusted continuation chain, a durable `dk0 trust accept`
  record (optionally pinned to a key, so a pin mismatch is denied),
  `--trust-local-package`, or an interactive acceptance (deny by default).
- **The Sigstore trusted root is derived at import time.** The Fulcio CAs and
  Rekor keys that anchor the SLSA Level 2 check are refreshed through Sigstore's
  threshold-signed TUF metadata. "Sigstore trusted root" below describes the
  three guarantees this gives an importer - root substitution resistance,
  bounded staleness, and channel independence - and how the root is cached.
- **`import local` has no transport attestation by design** (the user names a
  local file); the signify signature, rotation, and acceptance controls above are
  its distribution-integrity control.
- **`inspect` runs the same verification as `import`** (SLSA Level 2 for
  `github-l2`, then the signify / rotation / deny-by-default acceptance controls)
  but never imports the package payload: it extracts the exported script modules
  (for audit) and the sealed distribution scripts (for verified manifest
  rendering) from the small distmeta only. It is the verified-release source for
  catalog and manifest rendering.
- **Rule capabilities are deny-by-default and keyed by signify provenance.**
  A rule action that runs a program (`request.ui.spawn` and `request.ui.capture` share
  one `run` capability, so capture cannot bypass a spawn denial) or writes into
  the project tree (`request.ui.writefile` and `request.ui.selfignore`, the
  `write` capability) is prompted the first
  time; answering `[a]lways` persists a workspace grant
  (`etc/dk/t/capabilities.json`) for the rule's producer signify key, bound to
  the full public key, or, for unsigned local content, for the values-file
  SHA-256 (editing the content asks again). A rule from an imported distribution
  is attributed to the producer key when its `values.lua` content SHA-256 is in
  the import ledger (`etc/dk/t/imports.json`) against that key: the producer
  signs each exported script module's content SHA into the distribution
  (`build_to_sign.build_script_module_sha256s`), import records it after
  verifying the signature, and the run-time content is bound by matching that
  hash. Content tampered after import (or a local file squatting on the module
  id) is not in the ledger and safely falls back to the content-hash prompt.
  `dk0 trust grant|revoke|list` manages the grants non-interactively (CI), and
  `dk0 trust accept PACKAGE_ID --run`/`--write` records pending capabilities
  that become the same producer-key grants at the first successful import.
  Accepting a producer key at import time never grants a capability: authenticity
  and authorization are separate decisions. A program given as a bare name is
  flagged as `PATH`-resolved (with the current directory excluded from the
  search on Windows).
- **`dk0 remote` composes producer trust into capability.** The isolated remote
  orchestration path imports and verifies the explicitly named producer, then
  (only for the single orchestration rule it runs, in the ephemeral isolated
  workspace) allows that producer key's rule to run its own
  capture/spawn/writefile without a per-action prompt, so `dk0 remote GitHub@X`
  no longer needs `--dangerously-trust-all`. The allowance is scoped to the
  named producer's key and the isolated run; it is empty in every other process.

### Built-in trust root

`dk0` embeds the OpenBSD signify **public** key for exactly one package:
`CommonsBase_Std`, in `SecConsumerTrust.builtin_root_keys` (the current 2.6 line
key, fingerprint `f012f39422d61ed2`). This implements the [Specification]'s
trust store, which names the dk signify key for the `CommonsBase_Std` packages
as the only trusted entity by default.

The keys are embedded because deny-by-default enforcement needs a starting
anchor. Nearly every dk workspace bootstraps by importing `CommonsBase_Std`
(coreutils, 7zip, toybox, ...), and a fresh consumer - a first-time user or a
CI runner - has no previously imported releases, no locally prepared keys, and
no terminal to answer an accept/deny prompt. Without the embedded root, every
first import would fail closed or teach users to reach for
`--trust-local-package`, hollowing out the deny-by-default model. Only this
one package's keys are embedded - not every `Commons*` key - to keep the
curated, code-reviewed trust surface minimal: every other producer anchors
through the signed continuation chains of imported releases, a durable
`dk0 trust accept` record, an explicit `--trust-local-package`, or an
interactive acceptance.

Newer `CommonsBase_Std` lines chain from the embedded keys through the signed
continuations of imported releases (2.5 signs the 2.6 and 3.0 keys, and so
on), so rotation within the reachable chain needs no code change. A release
only carries the chain it links transitively, though, so a fresh import of the
latest release can outrun an old root (this is how the 2.6 key earned its
entry). The network-gated `trust-root.t` test imports the latest
`dkpkg/CommonsBase_Std` release into an anchorless workspace; when it fails,
`builtin_root_keys` must gain the current line's key, taken from the signed
continuation of an attested prior release.

### Sigstore trusted root

The SLSA Level 2 control verifies a release against the Sigstore **trusted root**
(the Fulcio certificate authorities and Rekor log keys). `dk0` derives that root
at import time by running `gh attestation trusted-root`, which refreshes it
through Sigstore's threshold-signed TUF metadata. The chain that produces it is:

```text
launcher (baked signify root, diskuv.com/dk manifest)
  -> dk0 binary (manifest-verified, per-arch sha256)
    -> built-in MlFront_Attestation catalog (compiled into dk0; pins gh.exe by sha256)
      -> gh.exe (checksum-verified download)
        -> gh's embedded Sigstore TUF root
          -> TUF refresh (threshold-signed, expiring metadata)
            -> trusted_root.jsonl (Fulcio CAs, Rekor keys)
```

That chain gives an importer three guarantees.

1. **Root substitution resistance.** Forging the trusted root requires breaking
   either the `dk0` release channel (the signify producer key, human-gated and
   rarely used) or Sigstore's threshold-signed TUF chain. No single automated
   signer can substitute it.
2. **Bounded staleness and revocation.** TUF metadata expires, so a revoked or
   rotated Fulcio or Rekor key stops being trusted within the refresh window, and
   a frozen or replayed old root is rejected.
3. **Channel independence.** SLSA/sigstore (GitHub plus Sigstore infrastructure)
   is an independent second channel from the signify producer-key channel
   (Diskuv). Compromising one signing infrastructure leaves the other standing:
   the trusted root is never redistributed from `diskuv.com`, and on the
   `import github-l2` path a signify signature is never accepted in place of the
   attestation check.

`dk0` caches the derived root so a second workspace on the same machine does not
repeat the TUF refresh. The cache is keyed by the GitHub CLI's module version and
the `--build-period` build number, so a new build period is a new key and derives
the root again; `--build-period 1h` is the recommended production setting. A
cached root is re-verified whenever it is read, and one that fails its check or
has outlived `--trusted-root-max-age` is discarded and derived again. The `gh`
binary that derives it is pinned by SHA-256 in the built-in
`MlFront_Attestation` catalog and re-checked against that pin on every read.

### Gaps

The consumer-side gaps that the controls above close were found by Opus 4.8 with
Claude Code on 2026-07-11, and were closed the same day. Still tracked:

1. GitHub SLSA Level 3 is not verified. A release carrying a non-empty
   `github_slsa_v1_l3` attestation document is explicitly rejected on import
   instead of being accepted unverified.
2. `query manifest` performs no verification by design: it reads the local working
   tree for authoring and preview. A consumer that renders its output (for example
   a package catalog) should render from verified release data instead:
   `inspect github-l2` extracts the sealed distribution scripts, and
   `query manifest -f <outdir>/LIBRARY.VERSION.dist-scripts/dk.u` renders them.
   Releases produced before dk0 sealed manifest inputs cannot be rendered this
   way until re-released.
3. A release produced without the distribution key in the build environment (for
   example a local `distribute` with the auto-generated workspace key) publishes
   an empty `build.attestation.openbsd_signify` anchor; consumers accept the
   absence and rely on the other controls. Requiring the signature is a possible
   future hardening once every producer signs.

## Operational guide

Day-to-day guidance for people who publish dk packages. Each entry is written
for package publishers, not build-system developers.

### Keep the releases that newer releases build on

Each new release of a package is usually built on top of the release before
it, and it reuses pieces of that earlier release. People who add or update
your package can therefore still need the earlier release to be published.

+ Publish a new release before deleting any earlier release. A fresh release
  stands on its own and ends the need for the releases before it.
+ dk0 warns and continues when it meets a deleted earlier release. The
  warning goes away after the next release.

## Bootstrap scripts

The reference implementation is a single-file executable.
A `dk0` shell script (Unix) and a
`dk0.cmd` Windows batch script are also available that bootstrap and run the single-file executable.
They rely on a small set of external tools per platform; a different implementation may
use different tools or none at all.

Each dk0 version installs into its own `dk0exe-<version>-<abi>` directory
under the launcher data home (`%LOCALAPPDATA%\Programs\dk0` on Windows,
`$XDG_DATA_HOME/dk0` or `~/.local/share/dk0` on Unix, `DKCODER_DATA_HOME`
override). The launchers garbage collect that store on every run: the
version being launched is marked used, then version directories and
superseded `verifier/mlfront-signify-*` binaries that no launcher has used
in 30 days are removed. Everything in the store re-downloads on demand from
its signed manifest, so pruning is always safe and never blocks a launch.

### Windows POSIX shells

On Windows the `dk0` shell script runs under Git Bash, MSYS2, and Cygwin, and
`dk0.cmd` runs under `cmd.exe` and PowerShell. Both select the `windows_x86_64` or
`windows_x86` binaries and share one launcher data home,
`%LOCALAPPDATA%\Programs\dk0`, so a project driven from both shells downloads
each version once.

The shell script looks for `curl` and `wget` in `/usr/bin` and `/bin` first, and then
on `PATH`. The `PATH` step is what finds `/mingw64/bin/curl` under Git for Windows.

### Windows

| File                     | What                                                                   |
| ------------------------ | ---------------------------------------------------------------------- |
| `pwsh` in PATH           | `enter-object` interactive shell (optional; searched 1st)              |
| `powershell` in PATH     | `enter-object` interactive shell (optional; searched 2nd)              |
| `cmd` in PATH            | `enter-object` interactive shell (fallback; searched last)             |
| `powershell.exe` in PATH | `dk0.cmd` batch script - for InvokeWebRequest (optional; searched 1st) |
| `bitsadmin` in PATH      | `dk0.cmd` batch script - for download (fallback; searched last)        |
| `certutil` in PATH       | `dk0.cmd` batch script - verify sha256sums                             |
| `forfiles` in PATH       | `dk0.cmd` batch script - prune old dk0 versions (optional)             |

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
| `/bin/wget`         | `dk0` shell script (optional; searched 4th)                       |
| `curl`/`wget` in PATH | `dk0` shell script (fallback; searched last)                    |
| `/usr/bin/mv`       | `dk0` shell script (optional; searched 1st)                       |
| `/bin/mv`           | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/rm`       | `dk0` shell script (optional; searched 1st)                       |
| `/bin/rm`           | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/uname`    | `dk0` shell script (optional; searched 1st)                       |
| `/bin/uname`        | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/awk`      | `dk0` shell script - to parse sha256sums (optional; searched 1st) |
| `/bin/awk`          | `dk0` shell script (fallback; searched last)                      |

### Linux / BSDs / MSYS2 / Cygwin / Git Bash

| File                 | What                                                              |
| -------------------- | ----------------------------------------------------------------- |
| `/bin/sh`            | `enter-object` interactive shell unless `SHELL` env var set       |
| `/bin/sh`            | `dk0` shell script                                                |
| `/usr/bin/shasum`    | `dk0` shell script (optional; searched 1st)                       |
| `/usr/bin/sha256sum` | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/curl`      | `dk0` shell script (optional; searched 1st)                       |
| `/bin/curl`          | `dk0` shell script (optional; searched 2nd)                       |
| `/usr/bin/wget`      | `dk0` shell script (optional; searched 3rd)                       |
| `/bin/wget`          | `dk0` shell script (optional; searched 4th)                       |
| `curl`/`wget` in PATH  | `dk0` shell script (fallback; searched last)                    |
| `/usr/bin/mv`        | `dk0` shell script (optional; searched 1st)                       |
| `/bin/mv`            | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/rm`        | `dk0` shell script (optional; searched 1st)                       |
| `/bin/rm`            | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/uname`     | `dk0` shell script (optional; searched 1st)                       |
| `/bin/uname`         | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/awk`       | `dk0` shell script - to parse sha256sums (optional; searched 1st) |
| `/bin/awk`           | `dk0` shell script (fallback; searched last)                      |
| `/usr/bin/cygpath`   | `dk0` shell script (optional)                                     |

### Dynamic linker (per ABI, not per OS)

The tables above list files that vary by operating system. The dynamic linker
is the exception: it varies by **ABI**. A dynamically linked executable names
its loader by absolute path in its ELF `PT_INTERP` header, so that exact path
must exist to run objects of that ABI. Statically linked objects carry no
`PT_INTERP` and need no loader; the `Linux_x86_64_musl` `dk0`/`dk1` launchers
are static for this reason. The loader is normally supplied by the host's own
libc, and must be provided explicitly only when objects of one ABI run on a
host of another - for example `Linux_x86_64_musl` objects on a glibc host.

| ABI                 | File                          | What                                                |
| ------------------- | ----------------------------- | --------------------------------------------------- |
| `Linux_arm64`       | `/lib/ld-linux-aarch64.so.1`  | glibc dynamic linker for dynamically linked objects |
| `Linux_x86`         | `/lib/ld-linux.so.2`          | glibc dynamic linker for dynamically linked objects |
| `Linux_x86_64`      | `/lib64/ld-linux-x86-64.so.2` | glibc dynamic linker for dynamically linked objects |
| `Linux_x86_64_musl` | `/lib/ld-musl-x86_64.so.1`    | musl dynamic linker for dynamically linked objects  |

### Minimum glibc (per ABI)

The published Linux binaries are built on `manylinux_2_28` container images,
so the glibc ABIs run on any distribution carrying glibc 2.28 or newer. The
`Linux_x86_64_musl` binaries are statically linked and carry no libc floor.

| ABI                 | Minimum libc               |
| ------------------- | -------------------------- |
| `Linux_arm64`       | glibc 2.28                 |
| `Linux_x86`         | glibc 2.28                 |
| `Linux_x86_64`      | glibc 2.28                 |
| `Linux_x86_64_musl` | none (statically linked)   |

### System toolchains (per-ABI contract)

Slot artifacts that contain native code are built with one system toolchain
per ABI family. This section is the contract for where that toolchain comes
from and what compatibility floor the built artifacts inherit.

| ABI family        | System toolchain                      | How it is located                                    |
| ----------------- | ------------------------------------- | ---------------------------------------------------- |
| `Linux_*` (glibc) | `gcc`, `as`, binutils                 | resolved from `PATH` at build time                   |
| `Linux_*_musl`    | `x86_64-linux-musl-*` cross toolchain | bundled inside the slot                              |
| `Windows_*`       | MSVC                                  | at consume time: `vswhere`, then `vcvarsall` capture |
| `Darwin_*`        | `/usr/bin/clang`                      | fixed path (Xcode Command Line Tools)                |

+ `Linux_*` (glibc): distribution builds must run in a glibc 2.28 build
  environment, canonically the `quay.io/pypa/manylinux_2_28_*` containers,
  so slot artifacts run on any distribution carrying glibc 2.28 or newer.
+ `Linux_*` (glibc): glibc links are backward-compatible only, so a build
  on a newer-glibc host inherits that host's glibc floor. Such builds work
  for local use (the DkML compiler is relocatable as of CommonsLang_OCaml
  release `0.1.20260820083108`), and a newer-glibc host can never
  produce distribution-grade artifacts natively.
+ `Linux_*` (glibc): runtime objects are compiled as position-independent
  code, so native links succeed under PIE-default toolchains.
+ `Linux_*_musl`: the slot bundles its cross toolchain (bare
  `x86_64-linux-musl-*` tool names plus dispatch shims) and its output is
  statically linked.
+ `Windows_*`: MSVC is the sole official Windows slot toolchain. `vswhere`
  finds the Visual Studio installation, a `vcvarsall` environment capture
  supplies `INCLUDE`, `LIB`, `LIBPATH` and `PATH`, and the slot to
  `vcvarsall` architecture mapping is the CommonsLang_OCaml table
  `assets/table/msvc-arch/Release.<slot>`.
  `CommonsBase_LLVM.Toolchain.MinGW` is a cross toolchain for building C
  userland packages.
+ `Darwin_*`: `/usr/bin/clang` is the `xcode-select` trampoline installed
  with the Xcode Command Line Tools.
+ Per-ABI build-environment conformance checks run once, in the shared
  `diskuv/dk-distribute` action that every dk package's distribute
  workflow invokes, before the distscript executes. A published
  attestation therefore implies the build environment conformed; the
  combine job's `file`-based architecture check on the produced binaries
  is the post-build complement.
