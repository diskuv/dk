# dkjs Reference Implementation

`dkjs` is the JavaScript implementation of the dk build system. It runs on
Node.js with no native binary: the whole build engine is compiled to a single
JavaScript bundle that Node executes directly. `dkjs` is a **fallback** path -
the signed, fast native `dk1` is always tried first, and `dkjs` exists for hosts
where installing or running that native binary is blocked or unavailable but
Node.js is present.

`dkjs` shares the exact command-line dispatch, commands, options, and build
engine of the single-threaded reference implementation `dk0` and the
multi-threaded `dk1`. **This document only describes what is different in
`dkjs`.** For the invocation form, every command, and every option, see the
[dk0 Reference]. For the `-j` / `--jobs` option it shares with `dk1`, see the
[dk1 Reference]. For the implementation-agnostic build model (projects, assets,
bundles, forms, objects, values, subshells, distributions and scripts) see the
[Specification].

[dk0 Reference]: DK0-REFERENCE.md
[dk1 Reference]: DK1-REFERENCE.md
[Specification]: SPECIFICATION.md

## When to use dkjs

`dkjs` is a **conditional fallback, not the default surface**. Prefer the native
`dk1` binary: it is signed, fast, and complete. Reach for `dkjs` only when both
of these hold:

- installing or running the native `dk0` / `dk1` binary is blocked or
  unavailable (for example a download or tool classifier that refuses
  executables), and
- the host already has Node.js.

Node.js and npm are common on developer machines, but AI agent harnesses do not
bundle them, so `dkjs` is a conditional fallback rather than a universal path.
Because it shares the build engine, a build `dkjs` produces is byte-identical to
the same build under `dk0` / `dk1` (see [Determinism](#determinism)).

## Invocation

```text
dkjs [global options] [--] command [command args]
```

`dkjs` takes the same argv as `dk0` and `dk1`. It runs as a single JavaScript
bundle under Node.js: there is no native executable and nothing to compile on the
host. The invocation form, the workspace and project-directory rules, and every
command are identical to `dk0` - see [Invocation](DK0-REFERENCE.md#invocation)
and [Commands](DK0-REFERENCE.md#commands).

## Execution ABI

Every dk build runs under an **execution ABI** that names the host it runs on.
Because `dkjs` always runs on Node.js, its execution ABI is always `js_nodejs`,
with an operating-system value of `JS` and an OS family of `js`. `dkjs` does not
probe the machine underneath Node: it never resolves native per-ABI artifacts, so
the host CPU and operating system do not change how it runs.

A build may still **cross-compile** to another target by setting a target ABI
(`--target-abi`); `js_web` names a web-bundler target for producing browser
output. The execution ABI (where `dkjs` runs, always `js_nodejs`) and the target
ABI (what the build produces) are independent.

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

`dkjs` matches the native implementations byte-for-byte: for the same inputs, a
supported build under `dkjs` produces **byte-identical output** to `dk0` and
`dk1`, and identical output for any `-j`. This is the point of the shared engine:
the build model, hashing, signing, archive layout, and trace store are the same
code paths, differing only in the host runtime. Changing `-j` changes only
wall-clock time, never the produced values or the trace store. See
[Determinism](DK1-REFERENCE.md#determinism) for the same guarantee stated for
`dk1`.

## Known limitations

`dkjs` trades some of the native binary's completeness for running with no native
code. The differences a user can observe:

- **No coordination with a concurrently running native dk.** Node.js has no
  advisory file locks (`fcntl` / `flock`), so `dkjs` coordinates the cache and
  trace-store locks between `dkjs` processes with lock files, yet cannot
  coordinate with a `dk0` / `dk1` running at the same time against the same cache
  or workspace. Run `dkjs` alone against a given cache and workspace.
- **Command coverage is still being completed.** `dkjs` is a fallback still
  reaching full parity with the native command surface; where a command is
  supported it is byte-identical, and the native `dk1` remains the complete
  surface.
- **Archives.** The streaming archive writer does not support append mode or
  prefixed self-extracting archives.
- **Downloads.** HTTP downloads have no separate connection timeout.

## Everything else

Every command, every other option, the debug modes, the build-metadata options,
security behavior, and the operational guide are identical to `dk0`. See the
[dk0 Reference], the [dk1 Reference], and the [Specification]. `dkjs` is the same
reference dispatch and build engine compiled to JavaScript and bound to a Node.js
execution context; only the runtime, the `js_nodejs` execution ABI, and the
fallback role are new.
