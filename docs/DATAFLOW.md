# Value id formulas, executed

- [Context](#context)
- [Setup](#setup)
- [VCI, the values canonical id](#vci-the-values-canonical-id)
- [BASE32L, the id encoding](#base32l-the-id-encoding)
- [What this file does not yet pin](#what-this-file-does-not-yet-pin)


## Context

`SPECIFICATION.md` states the value id formulas as literal pseudocode under
**Data Flow / Value Id Formulas**. Nothing verified them. Between 2026-07 and
2026-08 the object id formula was answered four incompatible ways while the
specification sat unchanged, because a formula written as prose cannot go red.

This document computes the ids **by calling the engine**, not by restating the
formula. Every id below is produced by `MlFront_Thunk.ThunkAst`, and the outputs
are diffed against this file by `@ext/dk/docs/runtest`. Change how an id is
built and this file stops matching, which is the whole point of it existing.

The distinction matters more than it looks. A document that recomputed
`SHA256_HEX(VCI || "|form|" || MODVER)` in its own code would agree with itself
forever and would notice nothing. These call `canonical_id`, so the engine's
answer is what is written down.

## Setup

The execution context an id is computed in.


```ocaml
(* >>> *) let ctx =
  MlFront_Thunk.ThunkExecutionContext.create_literal
    ~created_for:"DATAFLOW.md" ()
```


```text
val ctx : MlFront_Thunk.ThunkExecutionContext.t = <abstr>
```


Errors are reported through an observer, and a values document is parsed from a
CST. `ThunkCst.noop` is the empty document, which is enough to pin the
canonical id of a values file itself.


```ocaml
(* >>> *) module Observer =
  MlFront_Thunk.ThunkParsers.Results.MakeObserverWithErrorReporter
```


```text
module Observer =
  MlFront_Thunk.ThunkParsers.Results.MakeObserverWithErrorReporter
```



```ocaml
(* >>> *) let parse cst =
  MlFront_Thunk.ThunkAst.parse_values_json ~origin:None ~on_warning:ignore
    (module Observer) ctx cst
```


```text
val parse :
  MlFront_Thunk.ThunkCst.t ->
  (MlFront_Thunk.ThunkAst.t, MlFront_Thunk.ThunkResults.Semantic.t) result =
  <fun>
```


## VCI, the values canonical id

`SPECIFICATION.md` calls this **VCI - Values Canonical ID**. It is computed at
parse time and read back with `canonical_id`.


```ocaml
(* >>> *) let vci =
  match parse MlFront_Thunk.ThunkCst.noop with
  | Ok ast -> MlFront_Thunk.ThunkAst.canonical_id ast
  | Error _ -> "PARSE FAILED"
```


```text
val vci : string =
  "674a337413ccc1453c27ddf1f0a58de3a7693f0ebbc29549fd18f37eda5c25a6"
```


## BASE32L, the id encoding

The formulas end in `BASE32L(...)`, a lowercase unpadded base32. The engine's
encoder is what the ids are built from, so it is called rather than described.


```ocaml
(* >>> *) let base32l s =
  MlFront_Thunk.ThunkStrings.base32_encode ~no_pad:() ~lowercase:() s
```


```text
val base32l : string -> string = <fun>
```



```ocaml
(* >>> *) base32l "dk"
```


```text
- : string = "mrvq"
```


## What this file does not yet pin

`o_id` adds `SLOT` and the cross-build `XT` term, and that half is assembled in
`DkZero_Base`, which this document does not load. So the object id formula is
**not** gated here yet, and the four-way flip that motivated this work is in
that half. Extending to it means proving `DkZero_Base` can be loaded by
`UCramRunner`, which has C stubs and is a separate question from this file.

Stating the boundary rather than implying whole-formula coverage: what is gated
here is VCI and the encoding every id ends in, which is the part reachable from
the libraries already loaded.
