# Security

## Value Store

Vulnerabilities:

* Denial of Service
* Remote Code Execution
* Privilege Escalation

The `a` prefixed values contain OCaml [Marshal](https://ocaml.org/manual/4.14/api/Marshal.html)-ed abstract syntax trees (AST).
The purpose is to avoid reparsing the build files (ex. `values.json`) each build. Marshal acts like the Python `pickle` function.

Marshal can do remote code execution if `Closures` are enabled, but `Closures` are not enabled.

However, any bit flip in the Marshal-ed bytes can cause a segfault because Marshal reproduces a pointer graph. Through corrupted pointer dereferencing the ability to do Remote Code Execution and Privilege Escalation is possible.

The first protection is to prefix the Marshal-ed AST bytes with a SHA256 checksum. That protects against bit flips, and is implemented in `BuildValues.add_values_ast_exn`.

The second protection is to include the OCaml version and 32/64-bitness as part of the key. That protects against different OCaml implementations not being compatible with reading/writing other Marshal-ed values. That is implemented in `BuildCore.compatibility_tag ()` and becomes part of the key in `BuildCore.get_values_ast_value_id`.

The third protection is to sign the SHA256 checksum with OpenBSD signify (there is the MlFront_Signify implementation for OCaml) so that only trusted parties are read.
