# dk for opam users

At a high level, dk is a build system with a distributed key value store.
The key value stores are either local in a private `t/` folder in your project
or are remotely stored in GitHub releases. dk provides tools so you can
maintain your own GitHub projects (called "packages") with your own build
artifacts and reusable build rules stored in GitHub releases. GitLab and other
CI providers may be used at a later date.

The [CommonsLang_OCaml] package has reusable build rules that create
multi-platform lockfiles and maintain a global federation of built packages
backed by dk's remote key value stores.
Each locked package builds in its own directory hashed by the
package source, its locked dependencies, and the OCaml compiler. A build
that needs a locked package downloads it from GitHub releases
if it exists; otherwise it builds from source. When you want true incremental
development, an opam prefix can be materialized from the built packages,
so `dune build -w` and similar commands run against your source tree.

The authoritative reference for the rules this page describes is the
[CommonsLang_OCaml] package page.

[CommonsLang_OCaml]: https://diskuv.com/dk/pkg/CommonsLang_OCaml

> [!NOTE]
> I use Windows as my primary dev environment so I don't have any experience
> with `dune pkg`. I expect there is some overlap, even if the overall goals
> are quite different. (Jonah)

## The pin table

In conventional opam use, an `opam install` command would run a "solve"
(find the exact package versions that match the constraints in the .opam files)
and then install the packages.

`dk-opam-pins.txt` is how you declare your inputs to the solve.
It plays the role of `opam repository add` and `opam pin`.

```text
repo NAME URL          opam repository
pin NAME VERSION       hard version lock for one opam package
float NAME             remove a pin inherited from an existing switch
archexclude NAME ARCH  exclude a package on one architecture
```

You need to select an OCaml toolchain with a pin:

- `pin ocaml 4.14.3` solves against the DkML 4.14 toolchain. This toolchain is OCaml 4.14 with patches; the most important patches are the relocatable patches.
- `pin ocaml 5.5.0` solves against unpatched OCaml 5.5.

> [!TIP]
> Use a `#COMMIT` gitref in a `repo NAME URL#COMMIT` line to make the
> solve reproducible.

## Technical Details

### Solving the pin table

The solve runs `opam list --resolve` to compute the dependency closure and
`opam show` to read each package's version, source, dependencies, and build
commands. Since the opam solver needs a switch's repositories, pins, and
os/arch variables, the solve creates a throwaway opam switch from the
[pin table](#the-pin-table). Nothing is ever installed into the throwaway
switch.

### The lock file

The solve creates `dk.opam-lock.jsonc`, a committed lockfile with one section
per platform (ie. a "slot" in dk: `Release.Linux_x86_64`,
`Release.Windows_x86_64`, and so on). It records every package's version,
source URL, checksum, and build commands. The lock also
carries a `generated` block with the solve's own inputs (the package roots
and the [pin table](#the-pin-table) identifier).

### Building the package dependencies

Each locked package builds in its own directory and becomes a cached object. That gives a coarse-grained
incrementality to builds: if the binary artifacts of an opam package are cached
and its inputs have not changed, those binary artifacts are loaded from the cache.

### Prebuilt packages

[CommonsLang_OCaml] includes the following prebuilt objects:

- the OCaml compiler
- Dune
- opam
- MSYS2 (building opam packages on Windows unfortunately needs substantial Unix emulation today)

[CommonsBase_Build] includes:

- Git (opam needs this)

[CommonsBase_Build]: https://diskuv.com/dk/pkg/CommonsBase_Build/

When you "adopt" dk into an existing opam project, you import the [CommonsLang_OCaml]
dk package *and* you can import other dk-adopting packages. The net effect
is you can import binary opam artifacts from other people, and you can
distribute your binary opam artifacts to other people.

## Underlying build system

Today [CommonsLang_OCaml] only provides package level builds. It knows how to
build packages that use `dune` or `ocamlbuild`, the two widely deployed OCaml
build systems.

Both `dune` and `ocamlbuild` have incremental compilation. You can use the
OpamVenv dialog to create a real opam prefix from the already-built
closure into the project's `opam-venv/` directory. Activation scripts for
a POSIX shell, Windows Command Prompt and Windows PowerShell are available.
Once activated, `dune build -w`, LSPs, merlin, etc., should work
like they do from any opam switch.

## Host prerequisites

Building an opam closure from source compiles native code on your machine, so
the host needs a working C toolchain before you adopt.

- A C toolchain must be on `PATH`. On Ubuntu or Debian install `curl` and
  `build-essential`.
- The system toolchain is enough. The DkML toolchain objects invoke
  `PATH`-resolved tool names (`gcc`, `as`) and ship a PIC runtime, so native
  compilation and linking succeed on stock PIE-default hosts such as
  Ubuntu 24.04 and Debian 12 and later. This needs `CommonsLang_OCaml`
  release `0.1.20260820083108` or later.

## Adopting an opam project

Adoption is (replace `VERSION` with your project version):

{% tabs %}
{% tabitem label="Unix" %}

```sh
curl -fsSL https://diskuv.com/dk/vendor.sh | sh
./dk1 quickstart ocaml opam414
./dk1 update
./dk1 dialog CommonsLang_OCaml.Dk.OpamLock.Adopt@1.1.12 version=VERSION
```

{% /tabitem %}
{% tabitem label="PowerShell" %}

> `3072` is the code for `Tls12`. That is, don't use legacy TLS 1.0 or SSL 3.0.

```powershell
[Net.ServicePointManager]::SecurityProtocol = 3072
irm https://diskuv.com/dk/vendor.ps1 | iex
./dk1 quickstart ocaml opam414
./dk1 update
./dk1 dialog CommonsLang_OCaml.Dk.OpamLock.Adopt@1.1.12 version=VERSION
```

{% /tabitem %}
{% tabitem label="Command Prompt" %}

> `3072` is the code for `Tls12`. That is, don't use legacy TLS 1.0 or SSL 3.0.

```bat
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = 3072; irm https://diskuv.com/dk/vendor.ps1 | iex"
.\dk1.cmd quickstart ocaml opam414
.\dk1.cmd update
.\dk1.cmd dialog CommonsLang_OCaml.Dk.OpamLock.Adopt@1.1.12 version=VERSION
```

{% /tabitem %}
{% /tabs %}

`quickstart ocaml opam414` selects the DkML 4.14 toolchain and
`quickstart ocaml opam550` selects OCaml 5.5.

Adoption will:

- copy dk launcher scripts into your project so you can type `./dk1` in PowerShell or POSIX (or `.\dk1` in Command Prompt) to run the dk executable
- print and record the trust statements the quickstart declares (also shown on its page on diskuv.com): the pinned publisher keys of `CommonsLang_OCaml` and its support package `CommonsBase_Build`, plus run and write for `CommonsLang_OCaml`'s adoption dialog. The support package needs no capabilities, so its key is accepted without any. An interactive session confirms the statements once before they are recorded
- construct a `dk.u` workspace file, populate the pin table for the chosen toolchain, and import [CommonsLang_OCaml]
- verify the imported release against its GitHub attestation
- let the adoption dialog run programs (the opam solver) and write files (the generated build scripts) without interactive prompts, resolved from the pending grant the acceptance recorded
- launch the adoption dialog, which solves the opam lock, generates the build scripts, and registers the project source code

When the dialog finishes it prints the two remaining commands: a final
`./dk1 update` that records the checksums of the registered files, and the
`./dk1 run-object` that builds your project's dependency closure and runs
your executable.

The [CommonsLang_OCaml] package page
documents the adoption dialog and the individual rules (solve, driver
generation, venv) with their current versions and parameters.
