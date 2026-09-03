# dkjs Reference Implementation

`dkjs` is the JavaScript build system in the dk family. It runs on Node.js and
builds JavaScript and web projects: its execution ABI is `js_nodejs`, and a build
targets `js_nodejs` or, through a web bundler, `js_web`. The whole dk build engine
is compiled to a single JavaScript bundle that Node executes directly, with no
native binary.

`dkjs` shares the exact command-line dispatch, commands, options, and build
engine of the reference implementation `dk0` and the multi-threaded `dk1`. **This
document only describes what is different in `dkjs`.** For the invocation form,
every command, and every option, see the [dk0 Reference]. For the `-j` / `--jobs`
option it shares with `dk1`, see the [dk1 Reference]. For the
implementation-agnostic build model (projects, assets, bundles, forms, objects,
values, subshells, distributions and scripts) see the [Specification].

[dk0 Reference]: DK0-REFERENCE.md
[dk1 Reference]: DK1-REFERENCE.md
[Specification]: SPECIFICATION.md

## Scope

`dkjs` builds projects whose execution ABI is `js_nodejs` (a build running on
Node.js) and whose targets are JavaScript or web (`js_web`). It does not yet
generate native code. The native `dk0` / `dk1` binaries compile native (for
example C) code for the platform they run on; for `dkjs` to do the same, dk needs
C toolchains packaged as dk objects. That packaging is under way -
`CommonsBase_GNU.Toolchain.W64dev` is one such package - but the set is not yet
complete. Today, use `dkjs` for JavaScript and web builds and `dk1` for native
builds.

## Invocation

```text
dkjs [global options] [--] command [command args]
```

`dkjs` takes the same argv as `dk0` and `dk1`. It runs as a single JavaScript
bundle under Node.js: there is no native executable and nothing to compile on the
host. The invocation form, the workspace and project-directory rules, and every
command are identical to `dk0` - see [Invocation](DK0-REFERENCE.md#invocation)
and [Commands](DK0-REFERENCE.md#commands).

## Execution ABI and targets

Every dk build runs under an **execution ABI** that names the host it runs on, and
resolves objects for a **target ABI**. Because `dkjs` always runs on Node.js, its
execution ABI is always `js_nodejs`, with an operating-system value of `JS` and an
OS family of `js`. `dkjs` does not probe the machine underneath Node: it never
resolves native per-ABI artifacts, so the host CPU and operating system do not
change how it runs.

A build targets `js_nodejs` by default, or `js_web` (set with `--target-abi`) to
produce web-bundler output. Native target ABIs are not available yet (see
[Scope](#scope)).

A build targeting `js_web` runs with a target ABI other than its `js_nodejs`
execution ABI, which makes it a cross run for publishing purposes. A
`dkjs distribute` from such a build publishes the objects whose slot a literal
`execution_slot` named, and withholds the objects whose slot came from the
`execution_abi` wildcard, since those are `js_nodejs` slots that a build
targeting `js_nodejs` publishes. See
[Object Slots](SPECIFICATION.md#object-slots) for the rule.

## Parallel builds

`dkjs` accepts the same `-j` / `--jobs` option as `dk1`, which `dk0` rejects. It
caps the number of external processes (`child_process.spawn` leaves) that run at
once. Unlike `dk1`, whose default is the detected CPU count, `dkjs` **defaults to
`-j 1`** (fully serial); pass a higher `-j` to overlap independent external
steps. The option semantics are otherwise identical to
[Parallel builds](DK1-REFERENCE.md#parallel-builds).

## Runtime and concurrency model

`dkjs` runs the build on the **Node.js event loop**, which plays exactly the role
of `dk0`'s single engine thread and `dk1`'s engine thread: every scheduler
continuation and every build-state and trace-store mutation happens there, in the
same order `dk0` would choose. The only concurrency is external-process leaves -
each `child_process.spawn` and the wait for it to exit - admitted up to the `-j`
cap and applied back on the event loop in a deterministic order. No native
threads are used.

## Determinism

`dkjs` is deterministic: for the same inputs it produces the same output, and `-j`
changes only wall-clock time. It runs the same engine, hashing, signing, and
archive code as `dk0` and `dk1`, so a build that resolves the same values is
byte-identical across all three (a `get-object` under `dkjs` produces the same
bytes as under `dk0`). Values that depend on the execution ABI differ, since
`dkjs`'s execution ABI is `js_nodejs`.

## Known limitations

`dkjs` runs with no native code, which is where its two user-visible limits come
from:

- **Native compilation is not available yet.** `dkjs` builds JavaScript and web
  targets. Generating native (for example C) code depends on a fuller set of C
  toolchains packaged as dk objects; that packaging is under way but incomplete
  (see [Scope](#scope)). Use `dk1` for native builds.
- **Run `dkjs` alone against a given cache and workspace.** Node.js has no OS
  advisory file locks (`fcntl` / `flock`), so `dkjs` serializes its own processes
  with lock files but cannot coordinate with a `dk0` / `dk1` running at the same
  time against the same cache or workspace.

Otherwise `dkjs` runs the same commands as [dk0](DK0-REFERENCE.md#commands).

## Everything else

Every command, every other option, the debug modes, the build-metadata options,
security behavior, and the operational guide are identical to `dk0`. See the
[dk0 Reference], the [dk1 Reference], and the [Specification]. `dkjs` is the same
reference dispatch and build engine compiled to JavaScript and bound to a Node.js
execution context; only the runtime, the `js_nodejs` execution ABI, and the
JavaScript and web target scope are new.
