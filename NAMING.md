# Naming

## CommonsBase

The `CommonsBase_*` libraries are for community supported, semi-official packages. This is the only centrally maintained set of packages.

Every other library can and should be distributed using the dk build keys.

## Conventions

### Stages

Stage "0" is for a shrinking set of binaries used to bootstrap C and other language compilers.

For example:

- `CommonsBase_Build.Ninja0` are prebuilt Ninja executables used to bootstrap the `clang` C compiler
- `CommonsBase_Build.Ninja` will be Ninja executables compiled from source

### Official names

We use the official name, including the official capitalization, unless:

1. There is a simpler widely-accepted alternative. For example, it is preferable to use the very widely-accepted "Postgres" naming rather than PostgreSQL because
   Postgres is easier to pronounce and to type.
2. The official name does not fit the [lexical rules](#workarounds-around-lexical-rules).

### Workarounds around lexical rules

The allowed character set is `[A-Z]` for the first character and `[A-Za-z0-9_]` for the second and subsequent characters. The `_` underscore character has further restrictions when it is part of a library id. The rules are described elsewhere.

Sometimes you have a package that can't fit the pattern. "7-zip" is a great example. We follow the conventions where:

1. A leading digit is replaced by the first character of the digit's name ("S" for seven (7)) followed by the leading digit.
2. Use Pascal casing to replace `-` dashes in a library id (`MyOrg_S7Zip`)
3. Replace `-` dashes with underscores in a namespace term (`MyOrg_Unit.S7_zip`)

## Categories

The "Xyz" in `CommonsBase_Xyz` is a category. The categories come from Rust crates.io¹.

### Std

The packages that are needed in almost all other packages.

### DBMS

<https://crates.io/categories/database-implementations>:

> Databases allow clients to store and query large amounts of data in an efficient manner. This category is for database management systems ~~implemented in Rust~~.

The capitalization `DBMS` rather than `Dbms` is to reflect the conventional practice of all-caps for DBMS.

### Db

<https://crates.io/categories/database>:

> ~~Crates~~*Packages* to interface with database management systems.

## Footnotes

¹ Why crates.io? It was the only widely-used categorization scheme I could find that [did not artificially differentiate applications from libraries](https://github.com/rust-lang/crates.io/pull/488#issuecomment-272651364), so it fits the unification of apps and libraries that I'm trying to bring online with the dk build+package system.
