# dk1 Reference Implementation

`dk1` is the multi-threaded implementation of the dk build system. It runs the
build with a worker pool so that independent external steps (compilers,
subcommands, spawned tools) execute concurrently, capped by a `-j` / `--jobs`
job count.

`dk1` shares the exact command-line dispatch, commands, options, build engine,
and consumer trust model of the single-threaded reference implementation `dk0`,
so a producer key it denies names the same remedies `dk0` names. **This document
only describes what is different in `dk1`.** For everything else - the
invocation form, every command, and every option other than `-j` - see the
[dk0 Reference]. For the implementation-agnostic build model (projects, assets,
bundles, forms, objects, values, subshells, distributions and scripts) see the
[Specification].

[dk0 Reference]: DK0-REFERENCE.md
[Specification]: SPECIFICATION.md

## Invocation

```text
dk1 [global options] [--] command [command args]
```

The invocation form, the workspace and project-directory rules, and every
command are identical to `dk0` - see [Invocation](DK0-REFERENCE.md#invocation)
and [Commands](DK0-REFERENCE.md#commands). The project directory is the one
containing the `dk1` shell script and the `dk1.cmd` Windows batch script.

`dk1` accepts one option that `dk0` does not: `-j` / `--jobs` (see
[Parallel builds](#parallel-builds) below). Every other global option and
command option behaves exactly as documented in
[Options](DK0-REFERENCE.md#options). `dk0` rejects `-j` as an unknown option; it
is always serial.

## Parallel builds

`dk1` adds a single global option that controls how many external build
processes run at once:

- `-j JOBS`, `--jobs JOBS` - cap the number of external processes (compilers,
  subcommands, function commands, subshells, and `request.ui` spawns) that run
  concurrently. `JOBS` must be a positive integer; `-j 0` or a negative value is
  rejected and `dk1` exits non-zero.

When `-j` is not given, `dk1` defaults `JOBS` to the **detected CPU count**: the
`NUMBER_OF_PROCESSORS` environment variable on Windows, and
`getconf _NPROCESSORS_ONLN` on Unix, falling back to `1` when detection fails.
Pass `-j 1` to force fully serial execution (equivalent to `dk0`).

`-j` caps *external processes in flight*, not the size of the internal worker
pool. The worker pool is sized with headroom above `JOBS` so that non-process
work (I/O, hashing) does not starve behind the capped process jobs.

## Concurrency model

`dk1` uses **one engine thread plus N worker threads**:

- All scheduler continuations and all build-state and trace-store mutations run
  on the single engine thread - exactly as `dk0` runs everything, and exactly as
  a JavaScript event loop would. The worker pool only runs the blocking leaves:
  spawning an external process and waiting for it to exit.
- Because the engine thread makes the same scheduling decisions as `dk0`, `dk1`
  builds the same objects in the same order; parallelism only overlaps the
  *timing* of independent leaves. No locks are taken in the build core.
- Interrupts (Ctrl-C / `SIGINT`, and `SIGTERM`) are handled on the engine thread
  - worker threads mask them - so the resumability trace-store flush still runs
  when a build is interrupted.

## Determinism

`dk1` is deterministic with respect to the job count: for the same inputs,

- `dk1 -j N` produces **byte-identical output** to `dk0`, and
- `dk1 -j 1` produces byte-identical output to `dk1 -j N` for any `N`.

The engine confines every ordering-sensitive decision to the engine thread;
workers only perform independent leaf work whose results are applied back on the
engine thread in a deterministic order. Changing `-j` therefore changes only
wall-clock time, never the produced values or the trace store. The one visible
effect of higher `-j` is that interleaved progress output and captured
stdout/stderr from concurrent steps may arrive in a different real-time order;
the build outputs themselves do not change.

Which objects a `distribute` publishes is settled by the run's execution and
target ABIs together with how each object's slot was written, so `-j` never
moves it. A `dk1 distribute` whose `--target-abi` names an ABI other than its
`--execution-abi` withholds the objects whose slot came from the
`execution_abi` wildcard, at every job count. See
[Object Slots](SPECIFICATION.md#object-slots) for the rule.

## Everything else

Every command, every other option, the debug modes, the build-metadata options,
security behavior, the operational guide, and the bootstrap scripts are
identical to `dk0`. See the [dk0 Reference] and the [Specification]. `dk1` is the
same reference dispatch and build engine bound to a concurrent execution
context; only the multi-threaded worker pool and the `-j` flag are new.
