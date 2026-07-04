# Authoring dk packages

## Context

You write `dk.u` workspace scripts to configure `dk` in an existing project.

You write distribution scripts (`dist/*.u` files) when you publish your libraries, executables or rules for others to use.

This guide shows you what to put into `dk.u` or `dist/*.u` files.

## Terminology

Version: A [semver](https://semver.org/) version like `2.5.202606262052`.

Module: A rule, object, or asset identified by a `VendorQualifier_Unit.Terms@VERSION`.
For example `CommonsBase_GNU.Make.Apparatus@4.4.1`. A module is usually defined in
a `values.jsonc` declarative file or `values.lua` script.

Package: A common prefix for one or more modules that are distributed together.
For example `CommonsBase_GNU`.

## The workspace script: `dk.u`

`dk.u` is a [unified script]. In other words, it is a [Markdoc]
document with reserved sections and some specially formatted areas.

[Markdoc]: https://markdoc.dev/

The basic structure of a `dk.u` is:

```markdown
# YOUR PROJECT TITLE
## Overview
## Workspace
## License
```

Reserved sections are case-insensitive. That means `## Overview` is treated the same as `## overview`.

### `## Workspace`

The `## Workspace` section lists the package's dependencies as `%% import`
directives.

Typically you won't hand-edit this section. Commands like `add` and `update`
in the [dk0 Reference Implementation] are available to manage imports.

Each import pins an exact version and its checksums.
And just like a JavaScript `package-lock.json` or a Python `uv.lock`, the
section behaves like a miniature lock file:

```unified
## workspace

  %% import {
  ..   type="github-l2",
  ..   repo="dkpkg/CommonsBase_Std" }
  'import'
  'github-l2'
  { { 'CommonsBase_Std', '2.5.202606240625', {
      'blake2b-256:6450d810180892d71647fe63c2313d17df5ce23eef80e1050a13cf7ad4417b31',
      'sha256:9eac4142bc0a80e5b51d3b89e83069672873ec628256afe849408ab64f954100',
      'sha1:8c02d3bf95fe54717dd1798f292c6d6688a63faa'
    } } }
```

The two spaces and the `%%` start a [Lua workspace command], and the
two spaces and the `..` continue the [Lua workspace command].

[Lua workspace command]: SPECIFICATION.md#lua-workspace-globals

The `import { type="github-l2" }`, for example, imports a distribution from
a GitHub release and verifies it with GitHub's SLSA Level 2 attestation.

### `## Overview`

This section is a summary of the package for documentation.

For example:

```markdown
## Overview

`CommonsBase_GNU` provides the GNU command-line tools that other dk packages and
your projects depend on.
```

### `## License`

The `## License` section is a [SPDX license expression] for the
package.

Standard licenses are named directly:

```markdown
## License

GPL-3.0-or-later
```

[SPDX license expression]: https://spdx.org/licenses/

Often complex licenses are required. Here is a [SPDX license expression]
that combines several open source licenses with a custom license:

```markdown
## License

BSD-3-Clause AND Apache-2.0 AND MIT AND LicenseRef-CMake-Copyright

### LicenseRef-CMake-Copyright

CMake - Cross Platform Makefile Generator
Copyright 2000-2025 Kitware, Inc. and Contributors. All rights reserved.
...
```

Each `LicenseRef-<name>` must have its own `### LicenseRef-<name>`
subsection.

## The distribution scripts

### Organization of the dist folder

The platform matrix is *the set of `dist/*.u` scripts present*.

A package that builds the same way everywhere should use a single `dist/any.u`.

A package that needs custom build logic per platform should use one per ABI:

```text
dist/Darwin_arm64.u
dist/Darwin_x86_64.u
dist/Linux_arm64.u
dist/Linux_x86.u
dist/Linux_x86_64.u
dist/Windows_arm64.u
dist/Windows_x86.u
dist/Windows_x86_64.u
```

### Contents of dist/*.u

Each `dist/<ABI>.u` (or `dist/any.u`) is a [unified script]:
ordinary [Markdoc] with the value shell commands that build the package.

The [Markdoc] is the package's build documentation.

The section headings in a distribution script can be anything you want.

The value shell commands, however, are executed in order. Each value shell
command starts with two spaces and then a `$`. Two spaces and a `>` continue
an existing value shell command:

```unified
## GNU Awk

Let's check the file type of our CommonsBase_GNU.Awk@5.3.1 module:
  $ run-object CommonsBase_FileMagic.File@7.8.50407 -s Release.execution_abi -m ./bin/file.exe -e bin/file.exe --
  >   -b $(get-object CommonsBase_GNU.Awk@5.3.1 -s Release.target_abi -d : -e file.exe)/bin/awk.exe
  \test(pass)
  \dk.target(abi: "Windows_x86")[PE32 executable for MS Windows 6.00 (console),, 13 sections
  ]\;
```

The documentation for value shell commands can be found in the [Specification].

## Assets

The source code and URLs needed by your build are called **assets**.

> [!IMPORTANT]
> Unlike most other build systems, your builds do not get automatic access to your
> project source code. You use assets to specify which
> directories and files are given to your build. This extra effort is a key
> reason why your builds can be reproducible and can efficiently be run remotely.

The source code are workspace assets, while URLs are downloaded assets.

### Workspace assets

These are files and directories that live in the package directory (the directory
with a `dk.u`).

They are declared in `dk.u` with a `% unified.asset` directive that names
either a `file=` or a `dir=` path:

```unified
## Apparatus

### CommonsLang_DotNet.Apparatus@1.0.0

Here 
  % unified.asset { name="NuGetConfig", file="assets/nuget/NuGet.Config" }
  'asset'
  '321'
  'sha256:b7b2fedda9c847bdee1e5d4035460c895cda1db56c28629940bfb4d200b6bb90'

  % unified.asset { name="NuGetPackages", dir="assets/nuget/packages" }
  'asset'
  '226'
  { 'sha256:e21a238ce8fede4c01faa609588c44207a330515ce78a973e79c3443b1695ace' }
```

As shown above, the `unified.asset` must be in a section with a module identifier
(ex. `CommonsLang_DotNet.Apparatus@1.0.0`).

The output blocks (the lines that start with `'asset'` and end with sha256
checksums) are not meant to be hand-maintained. There will be a command like
`dk0 update --no-imports` for the [dk0 Reference Implementation] that will
recalculate the checksums on your behalf.

### Downloaded assets

These are third-party sources. They are declared in a `*.values.jsonc`
file (traditionally located at `etc/dk/v/Bundle.values.jsonc`).
The [SPECIFICATION] documents what an origin is:

```jsonc
{
  "origin": "gnu-awk",
  "path": "gawk-5.3.1.tar.gz",
  "size": 6264553,
  "sha256": "fa41b3a85413af87fb5e3a7d9c8fa8d4a20728c67651185bb49c38a7f9382b1e",
  "mirrors": ["https://ftp.gnu.org/gnu/gawk", "https://mirrors.kernel.org/gnu/gawk"]
}
```

A downloaded asset's source URL is `mirror "/" path`. In the example above
that would be `https://ftp.gnu.org/gnu/gawk/gawk-5.3.1.tar.gz` for the
first mirror.

> [!TIP]
> Unless your third-party source is highly available, you should provide **more
> than one mirror**. That avoids you not being able to build when your third-party
> source has an outage. If there are not public mirrors for your third-party
> source, consider making a GitHub project and manually making a GitHub Release
> containing the third-party source.

## Previewing your package documentation

To see your package documentation in the [dk0 Reference Implementation], run:

```shell
dk0 query manifest --markdown --outfile docs.md
```

That reads your `dk.u` and `dist/*.u` scripts and creates a single Markdown document.

## Publishing

When your package is ready for others, you publish it as a GitHub release carrying
a SLSA Level 2 attestation. You publish a package (a `VendorQualifier_Unit` id such
as `CommonsBase_GNU`) which includes all the modules in your package source tree.
Creating signing keys, producing the release, and how consumers verify and
`import` it are documented in the [dk0 Reference Implementation].

## A minimal checklist

- [ ] `dk.u` has `## workspace` with each dependency pinned via `%% import`
      (use `dk0 add` / `dk0 update`).
- [ ] `dk.u` has `## Overview` and `## License` with a
      `### LicenseRef-*` subsection for every custom license.
- [ ] One `dist/<ABI>.u` per supported ABI (or a single `dist/any.u`)
      containing `$` value shell build commands.
- [ ] Workspace assets declared with `% unified.asset { file=... | dir=... }`
- [ ] Downloaded assets declared in `*.values.jsonc` with multiple `mirrors`.
- [ ] `dk0 test` passes on every distribution script.
- [ ] `dk0 query manifest` shows the package the way users will see it.
- [ ] Ready to share? Publish a release (see [Publishing](#publishing)).

[dk0 Reference Implementation]: DK0-REFERENCE.md
[SPECIFICATION]: SPECIFICATION.md
[Unified Script]: UNIFIED_SCRIPTS.md
