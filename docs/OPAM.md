# dk for opam users

dk runs the opam you already know: the real solver, real opam repositories,
your pins. It adds a committed, per-platform lockfile and a cache of built
packages that releases publish as signed, attested assets. Each locked
package builds in its own sandbox, and the result is stored under the hash of
everything that went into it: the package source, its locked dependencies,
and the compiler. A build that needs a locked package downloads and verifies
a published object when one exists and builds it from source when one does
not. When you want the standard inner loop, an opam prefix can be
materialized from the built packages, so `dune build -w` runs against the
working tree.

The authoritative reference for the rules this page describes is the
[CommonsLang_OCaml package page](https://diskuv.com/dk/pkg/CommonsLang_OCaml).

## The pin table

`dk-opam-pins.txt` is the project's input to the solver, in one small file.
It plays the role of `opam repository add` and `opam pin` for the solve, and
it is committed, so the whole team solves against the same inputs.

```text
repo NAME URL          opam repository (append #COMMIT to pin a commit)
pin NAME VERSION       hard version lock for one opam package
float NAME             remove a pin inherited from an existing switch
archexclude NAME ARCH  exclude a package on one architecture
```

Pinning the compiler is how a project selects its toolchain: `pin ocaml
4.14.3` solves against the DkML 4.14 toolchain, and `pin ocaml 5.5.0` solves
against OCaml 5.5. Appending `#COMMIT` to the opam-repository line makes the
solve reproducible down to the repository state.

## Solving the lock

The solve runs `opam list --resolve` to compute the dependency closure and
`opam show` to read each package's version, source, dependencies, and build
commands. It never runs `opam install`. opam has no switch-less solve (the
solver needs a switch's repositories, pins, and os/arch variables), so the
solve creates an empty opam switch purely as a throwaway resolution context:
it adds the pinned repositories, applies the version pins from the pin
table, path-pins the local packages, and resolves. The switch is an
ephemeral local switch in the rule's sandbox, unique per run, and removed
once the solve finishes; nothing is ever installed into it.

## The lock

The solve writes `dk.opam-lock.jsonc`, a committed lockfile with one section
per platform ("slot" in dk terms: `Release.Linux_x86_64`,
`Release.Windows_x86_64`, and so on). It records every package's version,
source URL, checksum, and build commands, so a pull request that changes the
closure shows the change as an ordinary reviewable diff. The lock also
carries a `generated` block recording the solve's own inputs (roots, the
pin-table identity), which is what lets the tooling re-run or verify the
solve later without anyone remembering the original command.

## Building the closure

Each locked package builds from its opam-repository recipe in its own
sandbox, and becomes its own cached object. The second build, and every
incremental build after an edit, reuses every object whose inputs are
unchanged; editing your source rebuilds your package and leaves the
dependency closure cached.

Object identities are recipe addresses: a hash of the build rule's content,
the `module@version`, and the slot, and the recipe embeds the project's own
namespace. Caches therefore serve a project line, and the mechanism that
pays off across machines is restoring against the project's own published
releases: CI builds the closure once, releases it, and every later build
(CI or a contributor's first checkout) seeds itself from that release.

## Prebuilt packages

The toolchain arrives prebuilt: the compiler, Dune, opam, and the build
utilities are fetched lazily as attested objects from published releases,
on every platform, including the Windows toolchain (an MSVC-based compiler,
MSYS2, and Git delivered the same way as any other cached package). For the
project's own dependency closure, any release that already built a locked
package can serve it: every release ships the exact lock it was built from,
and a consumer's locked `name.version` is served from a release whose lock
pins the same version and the same compiler.

## The inner loop

`dk1` rebuilds only what an edit invalidates. For the dune-native workflow,
the OpamVenv dialog materializes a real opam prefix from the already-built
closure into the project's `opam-venv/` directory, with activation scripts
for each shell. Inside it, `dune build -w` and the editor's merlin work
against the working tree exactly as they do in any opam switch.

## Adopting an opam+dune project

Adoption is scripted end to end. The launchers are vendored into the
repository with one command, a quickstart recipe scaffolds the workspace and
seeds the pin table for the chosen toolchain, and an adoption dialog solves
the lock, generates the build forms, and registers the workspace assets:

```sh
curl -fsSL https://diskuv.com/dk/vendor.sh | sh
./dk1 --trust-local-package CommonsLang_OCaml quickstart ocaml opam414
```

`quickstart ocaml opam414` selects the DkML 4.14 toolchain and
`quickstart ocaml opam550` selects OCaml 5.5; each seeds a matching pin
table. The [CommonsLang_OCaml package page](https://diskuv.com/dk/pkg/CommonsLang_OCaml)
documents the adoption dialog and the individual rules (solve, driver
generation, venv) with their current versions and parameters.
