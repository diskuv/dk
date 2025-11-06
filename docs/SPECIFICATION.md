# Specification

- [Specification](#specification)
  - [Introduction](#introduction)
    - [Concepts](#concepts)
    - [Early Limitations](#early-limitations)
  - [Assets](#assets)
    - [Local Paths](#local-paths)
    - [Zip Archive Reproducibility](#zip-archive-reproducibility)
    - [Remote Paths](#remote-paths)
    - [Saving Bundles](#saving-bundles)
  - [Forms](#forms)
    - [Form Variables](#form-variables)
      - [Variable Availability](#variable-availability)
      - [$(subcommand)](#subcommand)
      - [${SLOT.request}](#slotrequest)
      - [${SLOTNAME.request}](#slotnamerequest)
      - [${SLOT.SlotName}](#slotslotname)
      - [${MOREINCLUDES}](#moreincludes)
      - [${MORECOMMANDS}](#morecommands)
      - [${/} directory separator](#-directory-separator)
      - [${.exe}](#exe)
      - [${HOME}](#home)
      - [${CACHE}](#cache)
      - [${DATA}](#data)
      - [${CONFIG}](#config)
      - [${STATE}](#state)
      - [${RUNTIME}](#runtime)
    - [Precommands](#precommands)
    - [Environment Modifications](#environment-modifications)
      - [+NAME=VALUE](#namevalue)
      - [-NAME](#-name)
      - [\<NAME=VALUE](#namevalue-1)
    - [Order of Processing](#order-of-processing)
    - [Dynamic Functions](#dynamic-functions)
  - [Objects](#objects)
    - [Saving and Loading Objects](#saving-and-loading-objects)
    - [Object Slots](#object-slots)
  - [Values](#values)
    - [Value Shell Language (VSL)](#value-shell-language-vsl)
    - [VSL Lexical Rules](#vsl-lexical-rules)
      - [Types of Words](#types-of-words)
    - [Variables available in VSL](#variables-available-in-vsl)
    - [get-object MODULE@VERSION -s REQUEST\_SLOT (-f FILE | -d DIR/) -- CLI\_FORM\_DOC](#get-object-moduleversion--s-request_slot--f-file---d-dir----cli_form_doc)
    - [enter-object MODULE@VERSION -s REQUEST\_SLOT -- CLI\_FORM\_DOC](#enter-object-moduleversion--s-request_slot----cli_form_doc)
    - [install-object MODULE@VERSION -s REQUEST\_SLOT (-f FILE | -d DIR/) -- CLI\_FORM\_DOC](#install-object-moduleversion--s-request_slot--f-file---d-dir----cli_form_doc)
    - [pipe-object MODULE@VERSION -s REQUEST\_SLOT -x PIPE](#pipe-object-moduleversion--s-request_slot--x-pipe)
    - [get-asset MODULE@VERSION FILE\_PATH (-f FILE | -d DIR/)](#get-asset-moduleversion-file_path--f-file---d-dir)
    - [get-bundle MODULE@VERSION (-f FILE | -d DIR/)](#get-bundle-moduleversion--f-file---d-dir)
    - [Options: -f FILE and -d DIR](#options--f-file-and--d-dir)
    - [Option: \[-n STRIP\]](#option--n-strip)
    - [Option: \[-m MEMBER\]](#option--m-member)
    - [Object ID with Build Metadata](#object-id-with-build-metadata)
    - [Form Document](#form-document)
      - [Option Groups](#option-groups)
    - [JSON Files](#json-files)
    - [JSON Canonicalization](#json-canonicalization)
  - [Distributions](#distributions)
    - [Distributed Value Stores](#distributed-value-stores)
    - [OpenBSD signify keys](#openbsd-signify-keys)
    - [GitHub SLSA Level 2](#github-slsa-level-2)
    - [GitHub SLSA Level 3](#github-slsa-level-3)
  - [Graph](#graph)
    - [Nodes](#nodes)
      - [Values Nodes](#values-nodes)
      - [V256 - SHA256 of Values File](#v256---sha256-of-values-file)
      - [P256 - SHA256 of Asset](#p256---sha256-of-asset)
      - [Z256 - SHA256 of Zip Archive File](#z256---sha256-of-zip-archive-file)
      - [CT - Compatibility Tag](#ct---compatibility-tag)
      - [VCI - Values Canonical ID](#vci---values-canonical-id)
      - [VCK - Values Checksum](#vck---values-checksum)
    - [Dependencies](#dependencies)

## Introduction

### Concepts

In the `dk` build system, you submit *forms* that produce *objects* created from *assets*.

The **assets** are input materials. These are files and folders that may be remote: source code, data files, audio, image and video files.

A **form** is a document with fields and a submit button. *Tip for engineers*: A form does not need to be entered on a graphical user interface. If you are comfortable with the DOS or Unix terminal, the document is a command line in your terminal. That is, you type the name of an executable followed by options like `--username` as the fields, and then you press ENTER to submit the form. The `dk` scripting system (doc: <https://github.com/diskuv/dk>) is a simple way to make standalone executables/forms.

An **object** is a folder that the form produces.

---

We use the generic term **value** to mean an bundle, a form or an object.

All values have names like `YourLibrary_Std.YourPackage.YourThing`. Think of the name as if it were a serial number, as the name uniquely identifies each bundle, form and object.

All values also have versions like `1.0.0`. Making a change to a value means creating a new value with the same name but with an increased version. For example, if the text of your 2025-09-04 privacy policy is in the bundle `YourOrg_Std.StringsForWebSiteAndPrograms.PrivacyPolicy@1.0.20250904`, an end-of-year update to the privacy policy could be `YourOrg_Std.StringsForWebSiteAndPrograms.PrivacyPolicy@1.0.20251231`. These *semantic* versions offer a lot of flexibility and are industry-standard: [external link: semver 2.0](https://semver.org/). The important point is that values do not change; versions do.

### Early Limitations

Practically speaking, the early versions of the `dk` build system have serious limitations:

- only support forms with a single field (the slot field). Today that means you create new forms when you need more customization.
- have no graphical user interface or web page for forms (yet!). Everything today must be done from the terminal.

As these limits are removed, this specification document may be updated.

## Assets

Assets are remote or local files that are inputs to a build. All assets have SHA-256 checksums.

Bundles are a named collection of assets.

Assets are accessed with the [get-bundle](#get-bundle-moduleversion--f-file---d-dir) and [get-asset](#get-asset-moduleversion-file_path--f-file---d-dir) commands described in a later section of the document.

### Local Paths

A path, if it does not start with `https://` or `http://` is a *local* path.

A local path may be either:

- a file
- a directory

A local directory path is always zipped into a zip archive file.
The [Zip Archive Reproducibility (next section)](#zip-archive-reproducibility) standards will be followed.

### Zip Archive Reproducibility

 For reproducibility, the generated zip archive file will:

- have the zip last modification time to the earliest datetime (Jan 1, 1980 00:00:00)
- have each zip entry with its modification time to the earliest datetime (Jan 1, 1980 00:00:00)
- have each zip file entry set its extended attribute to be a "regular file" with `rw-r--r--` permissions
- use zip compression level 5. That is: "compression method: (2 bytes) ... 5 - The file is Reduced with compression factor 4" at [IANA application/zip]

[IANA application/zip]: https://www.iana.org/assignments/media-types/application/zip

### Remote Paths

A path, if it starts with `https://` or `http://` is a *remote* path.

### Saving Bundles

When a value shell command reads an bundle and saves it to a file (ex.
[get-bundle -f FILE](#get-bundle-moduleversion--f-file---d-dir)),
the members of the bundle are zipped and the zip archive bytes are copied directly to the file.
The standards of [Zip Archive Reproducibility](#zip-archive-reproducibility) will be followed.

When a value shell command reads an bundle and saves it to a directory (ex.
[get-bundle -d DIR](#get-bundle-moduleversion--f-file---d-dir)),
the members of the bundle are copied into the directory tree.

That sounds inefficient, but the build system is allowed to optimize a set of value shell commands.
For example, if one shell command saves output into a directory,
and a second shell command reads data from created by the first shell command,
the build system can give the second shell command a symlink to the first directory
**without** using a zip archive as an intermediate artifact.

## Forms

### Form Variables

#### Variable Availability

Some variables are available in the Value Shell Language (VSL); see [Variables available in VSL](#variables-available-in-vsl)

All variables are available in `.forms.function.args` and `.forms.function.envmods`.

#### $(subcommand)

The result of a subcommand. The subcommand can be one of two things:

- `get-object MODULE@VERSION -s REQUEST_SLOT (-f :file | -f :exe | -d :) -- CLI_FORM_DOC` which is the same as a normal [get-object (described in the Values section)](#get-object-moduleversion--s-request_slot--f-file---d-dir----cli_form_doc) except the destination must be `-f :file` or `-f :exe` or `-d :`.
- `get-asset MODULE@VERSION FILE_PATH (-f :file | -f :exe | -d :)` which is the same as a normal [get-asset (described in the Values section)](#get-asset-moduleversion-file_path--f-file---d-dir) except the destination must be `-f :file` or `-f :exe` or `-d :`.

When the destination `-f` is `:exe`, the file that will be created will be executable:

- it will have the executable bit set for running on Unix
- it will end in a `.exe` for running on Windows

#### ${SLOT.request}

The output directory for the *request slot*. The `-s REQUEST_SLOT` option (ex. `get-object MODULE@VERSION -s REQUEST_SLOT`) is the request slot.

If the command has no request slot (ex. `get-bundle MODULE@VERSION`) and you use `${SLOT.request}`, an error is reported.

#### ${SLOTNAME.request}

The name of the *request slot*. The `-s REQUEST_SLOT` option (ex. `get-object MODULE@VERSION -s REQUEST_SLOT`) is the request slot.

If the command has no request slot (ex. `get-bundle MODULE@VERSION`) and you use `${SLOT.request}`, an error is reported.

#### ${SLOT.SlotName}

The output directory for the form function for the slot named `SlotName`.

Output directories for the build system in install mode are the end-user installation directories, while for other modes the output directory may be a sandbox temporary directory.

Expressions are only evaluated if *all* the output types the expression uses are valid for the build system. For example, an expression that uses the output directory `${SLOT.Release.Darwin_arm64}` will be skipped by the build system in install mode if the end-user machine's ABI is not `darwin_arm64`.

More generally:

| Type                           | Expression Evaluated? | Immediate Thunk Controller |
| ------------------------------ | --------------------- | -------------------------- |
| `${SLOT.Release.Agnostic}`     | Always                | A sandbox directory        |
| `${SLOT.Release.Darwin_arm64}` | Always                | A sandbox directory        |

| Type                           | Expression Evaluated?              | Install Thunk Controller |
| ------------------------------ | ---------------------------------- | ------------------------ |
| `${SLOT.Release.Agnostic}`     | Always                             | The install directory    |
| `${SLOT.Release.Darwin_arm64}` | Only if the end-user machine's ABI | The install directory    |
|                                | is `darwin_arm64`                  |                          |

#### ${MOREINCLUDES}

The directory that the function can place new `*.values.json` values files into. These values will be available to [MORECOMMANDS](#morecommands).

There are some restrictions on the content of the values in these new ("more") `*.values.json`:

- There must be no *more* distributions.

See [dynamic functions](#dynamic-functions) for more information.

#### ${MORECOMMANDS}

A newline separated file containing [zero or more value shell commands](#value-shell-language-vsl) that the function can write into.

See [dynamic functions](#dynamic-functions) for more information.

#### ${/} directory separator

The directory separator. Except for one edge case (below), it is always `/` even on Windows. That is, form commands can assume the `/` separator, which can simplify function code when the function interacts with MSYS2.

There is a special edge case for the build system in install mode: the build system in install mode will set the directory separator to `\` on Windows and `/` on Unix.
This allows installation to canonicalized UNC paths for Windows like the remote file `\\Server2\Share\Test\Foo.txt` or [long-path capable](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=registry) `\\?\C:\Test\Foo.txt`.

#### ${.exe}

The executable suffix. Except for one edge case (below), it is always `.exe` even on Unix. This:

- reduces the need for seperate `.precommands` for Windows and Unix, and separate `.function.args`
- is a performance and space optimization since a common executable suffix increases the chances that non-ABI specific artifacts share the same hash across Windows and Unix.

There is a special edge case for the build system in install mode: the build system in install mode will set the executable suffix to `.exe` on Windows and `` on Unix.

#### ${HOME}

A temporary directory for the form function.

There is a special edge case for the build system in install mode: the build system in install mode will set the home directory to be the OS-specific home directory for the install end-user.

#### ${CACHE}

A temporary directory for the form function.

There is a special edge case for the build system in install mode: the build system in install mode will set the cache directory to be the OS-specific cache directory (ex. `Temporary Internet Files` on Windows, the XDG-compliant cache directory in Unix).

#### ${DATA}

A temporary directory for the form function.

There is a special edge case for the build system in install mode: the build system in install mode will set the data directory to be the OS-specific data directory (ex. `LocalAppData` on Windows, the XDG-compliant data directory in Unix).

#### ${CONFIG}

A temporary directory for the form function.

There is a special edge case for the build system in install mode: the build system in install mode will set the config directory to be the OS-specific config directory (ex. `LocalAppData` on Windows, the XDG-compliant config directory in Unix).

#### ${STATE}

A temporary directory for the form function.

There is a special edge case for the build system in install mode: the build system in install mode will set the state directory to be the OS-specific data directory (ex. `LocalAppData` on Windows, the XDG-compliant state directory in Unix).

#### ${RUNTIME}

A temporary directory for the form function.

There is a special edge case for the build system in install mode: the build system in install mode will set the runtime directory to be the OS-specific data directory (ex. `LocalAppData` on Windows, the XDG-compliant runtime directory in Unix).

### Precommands

The `precommands` are a **set** of commands run *before* an object's `function`. It is not a sequence of commands since you
cannot make assumptions about the order of the precommands.

The following optimizations are allowed:

- Precommands may be run in parallel.
- Precommands may be skipped if the requested slot does not match the precommand output slot.
  For example, let's say you issue the command `get-object THE_ID -s Release.Agnostic`.
  Let's also say `THE_ID` object has two precommands:
  1. `get-asset ... -f ${SLOT.Release.Agnostic}`
  2. `get-object ... -d ${SLOT.Something.Else}`
  Then the second precommand may be skipped because the requested slot `Release.Agnostic` does not match `Something.Else`.

### Environment Modifications

The names in the environment follow the [POSIX specification](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap08.html), except on Windows the environment names are folded to be case-insensitive.
The rules are:

- The character set for the environment names is the [Portable Character Set](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap06.html#tagtcjh_3) except `=` (`<U003D>`) and `NUL`.
- The environment name can't start with a digit
- MlFront restricts more strictly than POSIX for whitespace: the only whitespace accepted are spaces (`<U0020>`). Linefeeds and other non-space whitespace are not accepted.
- MlFront restricts more strictly than POSIX for control characters: the `BEL` (`<U0007>`) is not accepted.

The values in the environment are encoded as UTF-8 and may contain [variables](#form-variables).

Because the first character of an environment modification unambiguously determines the type of modification, like `+` in `+NAME=VALUE` or `-` in `-NAME`, no escaping of environment names or values is required.

#### +NAME=VALUE

Add or set the environment variable with name `NAME` to `VALUE`.

The `VALUE` may contain [variables](#form-variables).

You may use `NAME=` to set the environment variable to empty. It is preferable to use [-NAME](#-name) since programs have inconsistent behavior when environment variables are empty; some treat empty as an unset environment variable, while others treat empty as empty.

#### -NAME

Remove the environment variable with name `NAME`.

#### <NAME=VALUE

Prepends `VALUE` and a path separator to the environment variable with name `NAME`.
However, the path seperator (`;` or `:` on Windows or Unix, respectively) is not added if the environment variable is empty.

The `VALUE` may contain [variables](#form-variables).

For example, `PATH+=C:\Windows\system32` prepends `C:\Windows\system32;` to the PATH on Windows and prepends `C:\Windows\system32:` to the PATH on Unix.
In this example, the Unix prepending does not make sense, which is why the best practice is to use [variables](#form-variables) for the `VALUE`
like `PATH+=${CACHE}${/}bin` so the modification is portable across operating systems.

### Order of Processing

The order of processing is as follows:

1. The form's precommands are executed, in parallel if supported by the build system.
2. The form's subshells in the function `args` and `envmods` (if any) are executed, in parallel if supported by the build system.
3. If there is a breakpoint from the `enter-object` command, a system shell (PowerShell, bash, etc.) is invoked.
4. The form's function is executed.
5. If [${MORECOMMANDS}](#morecommands) is part of the form's arguments or precommands, then:
   1. The [${MOREINCLUDES}](#moreincludes) directory is scanned for `values.json[c]` and `*.values.json[c]` values files. However, the values files are *not* imported in the value store.
   2. The [${MOREINCLUDES}](#moreincludes) values files are [alpha-converted](#dynamic-functions) and imported as `valuesfile` values.
   3. The module ids in the [${MORECOMMANDS}](#morecommands) are [alpha-converted](#dynamic-functions) using `BOUND_MODULES` from the last step.
   4. The alpha-converted shell commands in [${MORECOMMANDS}](#morecommands) are run.
6. The form's output files are verified to exist.
7. The [`${SLOT.slotname}`](#slotslotname) that are part of the form's arguments and precommands are made available to other forms.

The trace and value store are updated as normal during the MORECOMMANDS, so if the same form id, form slot and form document are submitted the build system can re-use the cached values.

### Dynamic Functions

Use the [MOREINCLUDES](#moreincludes) and [MORECOMMANDS](#morecommands) to create a function which perform `get-object`, `get-bundle` and other commands dynamically.
You'll want to do this in the following scenarios:

1. (lazy evaluation) All `precommands` are executed, modulo some optimizations specific to the [object slot](#object-slots), and they can be expensive. Using a dynamic function you can do an expensive `get-object` or `get-asset` based on the function inputs.
2. (language builds) Many languages have a lock file which can be parsed and executed to build a project: npm and cargo lockfiles, etc. Using a dynamic function means you don't have to model that language in the dk build system. Instead, write a dynamic function that can read the lock file (use a `get-asset` in the precommand to grab a language parser) and create a [values.json](#json-files) from that lock file. You'll get incremental language builds cheaply.
3. (huge build graphs) You can shrink a build graph by delegating large parts of it to dynamic functions. The entire build graph (minus dynamic functions) must be kept in memory so using a dynamic function gives you a knob so you don't have to increase the memory. *nit: this requires garbage collection / cache eviction of dynamic functions from the in-memory trace store, which is not implemented yet in the reference implementation*

Any function, including dynamic functions, must enumerate all the output files it produces. This limits dynamic functions in (we believe) a good way: you must know the outputs before you run the dynamic function. This design choice was influenced by Buck2.

The rest of this section is the implementation. It requires a basic knowledge of [lambda calculus](https://en.wikipedia.org/wiki/Lambda_calculus).

---

There is an **alpha conversion** procedure to avoid name collisions:

1. The set of *more* form ids and *more* bundle ids that are defined is assigned to the set `DEFINED_MODULES`.
2. The set of *more* form ids and *more* bundle ids that are referenced is assigned to the set `REFERENCED_MODULES`.
3. The set `BOUND_MODULES` is calculated as `REFERENCED_MODULES - DEFINED_MODULES`.
4. A deterministic *more* namespace term is created from a hash of the form id, form slot and the form document. For example, the form id `SomeForm_Std.Example@1.0.0` and the form slot `Release.Agnostic` and the form document `{"username":"nobody"}` are SHA-256 hashed together and base32 encoded to create a *more* namespace term like `LMBnmfdhn7lw4wepx2qiunrmgm4o5lx4wwsf2yfj7xyxggkg5kdsltq` (it is allowed to be shorter, but must start with `LMB` representing anonynmous lambda functions).
5. Each *more* form id and each *more* bundle id that is *not* in `BOUND_MODULES` is appended with the *more* namespace term in memory (ex. `SomeForm_Std.Example@1.0.0` becomes `SomeForm_Std.Example.Hnmfdhn7lw4wepx2qiunrmgm4o5lx4wwsf2yfj7xyxggkg5kdsltq@1.0.0`).
6. The converted `.*.values.json` files are written to a cached directory and imported into the value store.

The above procedure is the conventional alpha conversion from lambda calculus.

There is **no beta reduction** because all function applications are parameter-less. That is, functions are thunks `f ()` as influenced by the design of Stanford's [gg] build system. Even the form document is not a lambda parameter; instead it is part of the function (form) body.

There are no partial functions (in contrast to Nix) and no passing functions as first class arguments to other functions. But everything-is-a-thunk is easy for implementors and (hopefully) easy for non-functional users to understand.

There are other trade-offs with this design choice. Given a repeated function application with the same form id, form slot and form document:

- the function is memoized (the second and subsequent applications are loaded from cache) since the function body (the alpha converted MOREINCLUDES) and results (the object) are stored by the same identifiers in the value and trace store
- the value and trace store can grow large since each function application is stored
- failures should be much easier to debug since the inputs to the function application are available in the value/trace store and the function application has its own function directory (ie. `enter-object` should work)

[gg]: https://www.usenix.org/system/files/atc19-fouladi.pdf

## Objects

An object is a BLOB, which is a sequence of bytes. The object may be categorized by how the object comes to exist:

- a "generated" object created by a [form](#forms)
- anything else is an "input" object. For example, a file in your project may be an "input" object.

But to re-iterate: There is no concept of an object being a "file" or a "directory".
The object is just a sequence of bytes.

In both cases the build system treats the objects as immutable,
and the objects may be cached and/or persisted to disk whenever necessary.

When a value shell command is being run (described in the upcoming [Value Shell Language](#value-shell-language-vsl) section),
an object is made available on disk. At this time an object is "realized" into either a file or a directory.
That is the subject of the next [Saving and Loading Objects](#saving-and-loading-objects) section.

> Design Note: Why blur the distinction between files and directories?
> These objects are meant to be *cloud-friendly* so they need to
> have a canonical representation on cloud value stores like AWS S3. We don't need strict typing everywhere!
> And using a compressed archive means accessing the multiple
> outputs of a form function is quite straightforward; in contrast, other build systems expose the user to added complexity
> (confer: [make: Handling Tools that Produce Many Outputs](https://www.gnu.org/software/automake/manual/html_node/Multiple-Outputs.html)).

### Saving and Loading Objects

When a value shell command reads an immutable object and saves it to a file (ex.
[get-object -f FILE](#get-object-moduleversion--s-request_slot--f-file---d-dir----cli_form_doc)),
the bytes of the immutable object are copied directly to the file.

When a value shell command reads an immutable object and saves it to a directory (ex.
[get-object -d DIR](#get-object-moduleversion--s-request_slot--f-file---d-dir----cli_form_doc)),
the bytes of the immutable object are:

- *when the bytes have a zip file header* uncompressed and unzipped into the directory
- *when the bytes do not have a zip file header* copied into the directory in a file named `OBJECT`

When a value shell command saves a file as an immutable object, the file's bytes are saved as-is.

When a value shell command saves a directory as an immutable object, the directory is zipped and the zip archive bytes are saved.
The standards of [Zip Archive Reproducibility](#zip-archive-reproducibility) will be followed.

That sounds inefficient, but the build system is allowed to optimize a set of value shell commands.
For example, if one shell command saves output into a directory,
and a second shell command reads data from created by the first shell command,
the build system can give the second shell command a symlink to the first directory
**without** using a zip archive as an intermediate artifact.

### Object Slots

Each object has one or more slots. Each slot is a container for the object's files.

There are no built-in slots. However, `Release.Agnostic` is the conventional slot for files that are ABI-agnostic.

The names of the slots are period-separated "MlFront standard namespace terms". Each of these terms:

- are drawn from the character set `'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_'`
- must start with a capital letter
- must not contain a double underscore (`__`)
- must not be a MlFront library identifier (ie. a double camel cased string followed by an underscore and another camel cased string, like `XyzAbc_Def`)

## Values

### Value Shell Language (VSL)

**All encodings of VSL are UTF-8 unless explicitly noted as different.**

There is a POSIX shell / PowerShell styled language to query for objects and assets.
For example, the "command":

```sh
get-object OurStd_Std.Build.Clang@1.0.0 -s Release.Agnostic -f clang.exe
```

will get the object with the id `OurStd_Std.Build.Clang@1.0.0` and place it in the `clang.exe` file.

There are two ways to run these shell commands:

1. Directly from the command line with the efficient `dk` implementation or the reference implementation `mlfront-shell`. For example, `dk get-object OurStd_Std.Build.Clang@1.0.0 -s Release.Agnostic -f clang.exe`.
2. Embedded as "precommands" in a values file. For example,

   ```json
   { // ...
    "precommands": {
      "private": [
        "get-object OurStd_Std.Build.Clang@1.0.0 -s Release.Agnostic -f clang.exe"
      ]
    },
    // ...
   }
   ```

All commands have a output path (ex. `-f echo.exe`). Most command have two forms:

- `-f FILE` (ex. `-f echo.exe`)
- `-d DIR` (ex. `-d target`)

but some commands may only have the `-d DIR` directory output.

The best practice for relative paths is to use the forward slash (`/`) as directory separator in the output paths for readability (no escaping in JSON) and portability (backslashes don't work on Unix).
However, when the path is an absolute directory, use the native format, including UNC paths on Windows (ex. `\\Server2\Share\Test\Foo.txt`).

For security, the commands may be evaluated in a sandbox or a chroot environment. Do not use `..` path segments or they may fail to resolve in sandboxes.

### VSL Lexical Rules

A value shell command is a **command line** that is split into **words**.

In a JSONC (JSON with comments) values file, each precommand is a command line:

```json
"precommands": {
  "private": [
    // command line 1
    "get-object OurStd_Std.Build.Clang@1.0.0 -s Release.Agnostic -f clang.exe",
    "...",
    // command line N
    "get-object OurStd_Std.Build.GCC@1.0.0 -s Release.Agnostic -f gcc.c"
  ]
}
```

The `get-object OurStd_Std.Build.Clang@1.0.0 -s Release.Agnostic -f clang.exe` command line has the words `get-object`, `OurStd_Std.Build.Clang@1.0.0`, `-s`, `Release.Agnostic`, `-f`, and `clang.exe`.

Words are directly used in other places in the values file:

```json
"function": {
    "args": [
      // word 1
      "sh",
      // word 2
      "-c",
      // word 3
      "\"find . > ${SLOT.Release.Agnostic}/some-file\""
    ],
    "envmods": [
      // word 4: ${CACHE}/dkcoder
      "+DKCODER_CTX_CACHE_DIR=${CACHE}/dkcoder"
    ]
}
```

so the individual words can be assembled into a command line.

Each function argument in `args` and each environment modification value in `envmods` must be one value shell word.
In word 3 we used double quotes to squash several words into one shell word. In the next section the different ways to form words are explained.

#### Types of Words

The `get-object OurStd_Std.Build.Clang@1.0.0 -s Release.Agnostic -f clang.exe` from the previous section had the words:

- `get-object`
- `OurStd_Std.Build.Clang@1.0.0`
- `-s`
- `Release.Agnostic`
- `-f`
- `clang.exe`

These are examples of **bare words**; that is, words without any surrounding quotes.

Each bare word is one or more of the following *components without any interleaving spaces*:

- literals like `clang.exe`
- variables like `${SLOT.Release.Agnostic}` that get expanded to the **string value** of the named variable from the next section [Variables available in VSL](#variables-available-in-vsl)
- subshells like `$(get-object OurStd_Std.Build.Clang@1.0.0 -s Release.Agnostic -d :)` that get expanded to a **temporary file or directory** output of the subshell expression

An example of a single bare word that has all three types of components is:

```sh
$(get-object OurStd_Std.Build.Clang@1.0.0 -s Release.Agnostic -d :)/clang${.exe}
```

which is compromised of a subshell which could expand to `some/dir/clang-1.0.0/bin`, the literal `/clang` and the variable `${.exe}` which could expand to `.exe`. That is, the bare word could expand to `some/dir/clang-1.0.0/bin/clang.exe`. No quotations were required.

The lexical rules allow for a subshell to be nested in another subshell, although nested subshells should not be required until form parameters are added. For completeness, the bare word `$(get-asset MyAssets_Std.Bundle@1.0.0 -p $(get-object OurStd_Std.Build.Clang@1.0.0 -s Release.Agnostic -d :) -d :)` is valid, although nonsensical.

VSL words can also have quotes surrounding them so that spaces can be handled. The three type of words are:

1. Bare words (we've already covered these) with characters that are not whitespace, single quotes (`'`), double quotes (`"`) or backticks (`` ` ``).
2. **Single-quoted** words like `'C:\My Documents'`
3. **Double-quoted** words like `"${CONFIG}\Floor Plans\Master Bedroom.rvt"`

Single-quoted words (`'...'`) evaluate *literally* to the text inside the single quotes, including any whitespace and newlines.

Double-quoted words (`"..."`) squash many *bare* words into a single word by:

- evaluating each "inner bare word" (each bare word inside the double-quotes) using the rules above. However, the inner bare words can contain single-quote (`'`) characters which are treated like any ordinary character.
- keeping the whitespace *between* each inner bare words

The inner bare words and the whitespace between the inner words are concatenated into a single word.

Within double-quotes, you should escape:

- all double-quote (`"`) characters using the `` ` `` (backtick, aka. grave accent) as the escape character
- all backtick (`` ` ``) characters using the `` ` `` (backtick, aka. grave accent) as the escape character

> *Historical reasoning: Backticks were chosen for compatibility with Windows paths and familiarity with PowerShell; carets `^` were rejected since in Windows Batch the caret has complex rules.*

### Variables available in VSL

- `${SLOT.slotname}`
- `${/}`
- `${SRC}`
- `${HOME}`
- `${DATA}`
- `${CONFIG}`
- `${STATE}`
- `${RUNTIME}`

### get-object MODULE@VERSION -s REQUEST_SLOT (-f FILE | -d DIR/) -- CLI_FORM_DOC

Get the contents of the slot `REQUEST_SLOT` for the object uniquely identified by `MODULE@VERSION`.

| Option      | Description                                                                   |
| ----------- | ----------------------------------------------------------------------------- |
| `-f FILE`   | Place object in `FILE`                                                        |
| `-d DIR/`   | The object must be a zip archive, and its contents are extracted into `DIR/`. |
| `-n STRIP`  | See [Option: [-n STRIP]](#option--n-strip)                                    |
| `-m MEMBER` | See [Option: [-m MEMBER](#option--m-member)]                                  |

See [Options: -f FILE and -d DIR](#options--f-file-and--d-dir) for output path restrictions.

See [Form Document](#form-document) for form parameters. If there are none, the `-- CLI_FORM_DOC` can be left out.

The object `ID` implicitly or explicitly contains build metadata; see [ID with Build Metadata](#object-id-with-build-metadata).

### enter-object MODULE@VERSION -s REQUEST_SLOT -- CLI_FORM_DOC

Enter a shell like PowerShell or `/bin/bash` that has the contents of the slot `REQUEST_SLOT` for the object uniquely identified by identifier `ID`.

The shell is meant only for debugging problems, and may not appear if the object `ID` has been successfully built.

See [Form Document](#form-document) for form parameters. If there are none, the `-- CLI_FORM_DOC` can be left out.

The object `MODULE@VERSION` implicitly or explicitly contains build metadata; see [ID with Build Metadata](#object-id-with-build-metadata).

### install-object MODULE@VERSION -s REQUEST_SLOT (-f FILE | -d DIR/) -- CLI_FORM_DOC

Install the contents of the slot `REQUEST_SLOT` for the object uniquely identified by `MODULE@VERSION`.

| Option      | Description                                                                                            |
| ----------- | ------------------------------------------------------------------------------------------------------ |
| `-f FILE`   | Install object to `FILE`                                                                               |
| `-d DIR/`   | Install contents of the zip archive to the install directory `DIR/`. The object must be a zip archive. |
| `-n STRIP`  | See [Option: [-n STRIP]](#option--n-strip)                                                             |
| `-m MEMBER` | See [Option: [-m MEMBER](#option--m-member)]                                                           |

**More than one `install-object` can use the same install directory `DIR`**.

See [Options: -f FILE and -d DIR](#options--f-file-and--d-dir) for output path restrictions.

See [Form Document](#form-document) for form parameters. If there are none, the `-- CLI_FORM_DOC` can be left out.

The object `MODULE@VERSION` implicitly or explicitly contains build metadata; see [ID with Build Metadata](#object-id-with-build-metadata).

### pipe-object MODULE@VERSION -s REQUEST_SLOT -x PIPE

> Deprecated. This command will be replaced by dynamic tasks.

Write the contents of the slot `REQUEST_SLOT` for the object uniquely identified by `MODULE@VERSION` to the pipe named `PIPE`.

| Option      | Description                                  |
| ----------- | -------------------------------------------- |
| `-m MEMBER` | See [Option: [-m MEMBER](#option--m-member)] |

The object `MODULE@VERSION` implicitly or explicitly contains build metadata; see [ID with Build Metadata](#object-id-with-build-metadata).

No two `pipe-object` commands may write to the same pipe `PIPE`.

The location of the pipe is available using the variable `${PIPE.name}`.

Typically, the pipe given to the form function will be a PIPE_ACCESS_OUTBOUND named pipe server on Windows (ex. `\\ServerName\pipe\SomePipe`) and a write-only fifo pipe on Unix. To be portable, you should:

- read from the pipe zero or one time. Do not re-read from the pipe.
- read the data sequentially from the pipe. Do not use random access read in the pipe.
- expect the read from the pipe, especially the first byte, to take a long time.
- use PowerShell or a library in your favorite language to detect and read from the named pipe on Windows

Piping is an **optimization**. If the build system does not support threading, the pipe *will* be a regular file. However, if pipeline is supported, then the build system only has to kick off the build of the form function dependency `ID SLOT` when you *first access the pipe*.

Key Optimization: If you don't access the pipe at all in your form function, then you have saved the cost (clock time, compute, space) of the build for your dependency `ID SLOT`.

So in situations where the content is conditional (ie. read by the form function only in certain situations) and expensive (ie. the `ID SLOT` is large or has a time-consuming build), use `pipe-object`.

Here is an example use of a pipe:

```json
{
  "$schema": "https://github.com/diskuv/dk/raw/refs/heads/1.0/etc/jsonschema/mlfront-thunk.json",
  "version": {
    "major": 1,
    "minor": 0
  },
  "precommands": [
    "install-object SomeScripting_Minimal.Env -s Release.Agnostic -d usr/"
    "get-asset MyAssets_Std.Scripts@1.0.0 -p script/get-size.cmd -s Release.Agnostic -f get-size.cmd",
    "get-asset MyAssets_Std.Scripts@1.0.0 -p script/get-size.sh  -s Release.Agnostic -f get-size.sh",
    "pipe-object    SomeContent_Std.DataFile -s Release.Agnostic -x data-file-pipe"
  ],
  "function": {
    "args": [
      "usr/bin/run-powershell-or-posix-script.exe",
      "--powershell3",
      "usr/bin/powershell.exe",
      "get-size.ps1",
      "--posix",
      "usr/bin/sh",
      "get-size.sh",
      "--",
      "${PIPE.data-file-pipe}",
      "${SLOT.Release.Agnostic}"
    ]
  },
  "bundles": [
    {
      "id": "MyAssets_Std.Scripts@1.0.0",
      "listing": {
        "origins": [ { "name": "project-tree", "mirrors": [ "." ] } ]
      },
      "assets": [
        {
          "origin": "project-tree",
          "path": "script/get-size.cmd",
          "checksum": {
            "sha256": "4cc4b5286084c1285d905801291d028471cc62ad441308c95b0c25a1c42064d7"
          }
        },
        {
          "origin": "project-tree",
          "path": "script/get-size.sh",
          "checksum": {
            "sha256": "3c5f810d5d04d256a671712012e1fffa089214886745523ac78e7b45f318c30b"
          } } ] }
  ],
  "outputs": [
    { "slots": ["Release.Agnostic"], "paths": ["size.txt"] }
  ]
}
```

with the PowerShell script `script/get-size.ps1`:

```powershell
# The usage is:
#   get-size.ps1 LOCATION_OF_DATA_FILE LOCATION_OF_OUTPUT_FILE

# Get LOCATION_OF_DATA_FILE (maybe a named pipe)
$dataFile = $args[0]

# Get LOCATION_OF_OUTPUT_FILE
$outputFile = $args[1]

# Create output directory
$outputDir = Split-Path -Path "$outputFile" -Parent
if (-not (Test-Path "$outputDir")) { New-Item -Type Directory "$outputDir" }

# Get the size
if ($dataFile -match ("^\\\\([.]|[A-Za-z0-9][A-Za-z0-9.-]*)\\pipe\\.*")) {
  # $dataFile is a local \\.\pipe\SomePipe or a remote \\ServerName\pipe\SomePipe

  # PICK EITHER Technique 1: Write to a temporary file.
  Get-Content "$dataFile" > "datafile.tmp"
  $dataSize = (Get-Item -Path "datafile.tmp").Length
  Remove-Item "datafile.tmp"
  "Size of data file is $dataSize bytes" | Out-File -FilePath "$outputFile"

  # OR Technique 2: Sequentially read from the pipe.
  try {
      $pipeClient = New-Object System.IO.Pipes.NamedPipeClientStream($dataFile)
      $pipeClient.Connect()

      $reader = New-Object System.IO.StreamReader($pipeClient)

      # Technique 2: Sequentially read from the pipe
      [int]$bytesTotal = 0
      [Char[]]$buffer = new-object char[] 16384
      [int]$bytesRead = $reader.ReadBlock($buffer, 0, $buffer.Length)
      while ($bytesRead -gt 0)
      {
          [int]$bytesRead = $reader.ReadBlock($buffer, 0, $buffer.Length)
          Write-Host "[progress] read $bytesRead more bytes ..."
          $bytesTotal += $bytesRead
      }
      $bytesTotal += $bytesRead

      "Size of data file is $bytesTotal bytes" | Out-File -FilePath "$outputFile"

      $reader.Close()
      $pipeClient.Close()
      $pipeClient.Dispose()
  } catch {
      Write-Error "Error connecting or reading from pipe: $($_.Exception.Message)"
  }
} else {
  # local file
  $dataSize = (Get-Item -Path "$dataFile").Length
  "Size of data file is $dataSize bytes" | Out-File -FilePath "$outputFile"
}
```

and the Unix shell script `script/get-size.sh`:

```sh
#!/bin/sh

# The usage is:
#   get-size.sh LOCATION_OF_DATA_FILE LOCATION_OF_OUTPUT_FILE

# Exit the script immediately on errors
set -euf

# Get LOCATION_OF_DATA_FILE (maybe a fifo pipe)
datafile=$1

# Get LOCATION_OF_OUTPUT_FILE
outputfile=$2

# Make the output directory
install -d $(dirname "$outputfile")

# Write the size of the data file into the output file.
# On Unix, we can treat a pipe like $datafile as if it were a regular file.
size=$(wc -c "$datafile")
echo "Size of data file is $size bytes" > "$outputfile"
```

### get-asset MODULE@VERSION FILE_PATH (-f FILE | -d DIR/)

Get the contents of the asset at `FILE_PATH` for the bundle `MODULE@VERSION`.

| Option      | Description                                                                  |
| ----------- | ---------------------------------------------------------------------------- |
| `-f FILE`   | Place asset in `FILE`                                                        |
| `-d DIR/`   | The asset must be a zip archive, and its contents are extracted into `DIR/`. |
| `-n STRIP`  | See [Option: [-n STRIP]](#option--n-strip)                                   |
| `-m MEMBER` | See [Option: [-m MEMBER](#option--m-member)]                                 |

See [Options: -f FILE and -d DIR](#options--f-file-and--d-dir) for output path restrictions.

### get-bundle MODULE@VERSION (-f FILE | -d DIR/)

Get the archive file for the bundle `MODULE@VERSION`.

| Option     | Description                                                                         |
| ---------- | ----------------------------------------------------------------------------------- |
| `-f FILE`  | Place bundle in `FILE`. `FILE` will be a zip archive with **all** the bundle files. |
| `-d DIR/`  | **All** the bundle files will be extracted into `DIR/`.                             |
| `-n STRIP` | See [Option: [-n STRIP]](#option--n-strip)                                          |

See [Options: -f FILE and -d DIR](#options--f-file-and--d-dir) for output path restrictions.

*What about the `-m MEMBER` option?*

Use [get-asset](#get-asset-moduleversion-file_path--f-file---d-dir) to get a specific asset.
Having a `-m MEMBER` option would be equivalent but redundant and slightly confusing since
not much about assets implies they are stored as archives.

### Options: -f FILE and -d DIR

FILEs in the format:

- `*.exe`
- `**/bin/*`
- `**/sbin/*`
- `bin/*`
- `sbin/*`

where the separator may be `/` or `\\` will all be written with a `chmod +x` (executable bit) on Unix.

No command may write to the same file. Specifically:

- It is an error to have more than one `get-object` or `get-bundle` or `get-asset` or `resume-object` or `install-object` use the same `FILE`.
- It is an error to have more than one `get-object` or `get-bundle` or `get-asset` or `resume-object` use the same `DIR` or otherwise overlap the same `DIR`. Overlapping means one command can't write to the subdirectory of another command's `DIR`.

Use [`install-object`](#install-
--s-request_slot--f-file---d-dir----cli_form_doc) when you want to write into the same directory.
Even so, no `install-object` may extracted the same file in the same install directory.

### Option: [-n STRIP]

`-n STRIP` defaults to zero.

`STRIP` is how many levels of the zip archive to strip. Many zip archives place all content under a versioned root directory:

```text
llvmorg-19.1.3-win32/
  LICENSE.txt
  README.txt
  src/
```

To leave the directory structure as-is, set `STRIP` to `0`. To strip away the top level `llvmorg-19.1.3-win32` directory, set `STRIP` to `1`.

### Option: [-m MEMBER]

Gets the zip file member from the object or asset, which must be a zip archive.

### Object ID with Build Metadata

These rules apply to the `*-object` commands **only**:

- `get-object MODULE@VERSION ...`
- `install-object MODULE@VERSION ...`
- `pipe-object MODULE@VERSION ...`
- `enter-object MODULE@VERSION ...`

The purpose of these rules is to ensure that unique builds can be uniquely and deterministically identified.

Versions can have explicit build metadata.
For example, the VERSION `1.0.0+bn-20250801235901.commit-054d5983` has the two dot-separated build metadata fields: `bn-20250801235901` and `commit-054d5983`.

If the version `VERSION` has explicit build metadata in the format `bn-*`, then the object is **locked** to that specific build number.
In the above example the object is locked to build number `20250801235901` because that is the build metadata with format `bn-*`.

When the version `VERSION` has no explicit build metadata, or the version `VERSION`'s build metadata does not include a `bn-*` field, then the first matching rule of the following rules determines what the build metadata will be:

1. If a lockfile (not available yet in the reference implementation) has a build metadata reference (ex. `1.0.0` = `bn-20250801235901+commit-054d5983`), the build metadata is used.
2. The constructive trace store list of traces `key(i), dependencies(i), result(i)` is scanned. If there is a trace `i` where the version of `key(i)` matches the `VERSION` and where `result(i)` is an object value, then the build metadata of the *latest* such `key(i)` will be used.
3. The build metadata will be constructed from mlfront-shell's or dk's `-t TIMESTAMP` command line option, with the `bn-YYYYMMDDhhmmss` format.
4. The build metadata will be `bn-20250101000000`.

Important: the system clock is never consulted.

In CI, the best practice is to use the `-t TIMESTAMP` option, and base it on either:

- the source control commit timestamp.
  - Pro: Very easy to go back to the source code.
  - Con: If you need to force a new build from existing source code, you must create an empty commit-
- a monotonically increasing build number (ex. `GITHUB_RUN_NUMBER` if you use GitHub Actions).
  - Pro: No empty commits.
  - Con: Depending on your CI provider, it may be hard to go from a build number back to the source code.

Here are some examples for using the source control commit timestamp:

```yaml
# file: .github/workflows/example-build.yml

# CI System: GitHub Actions
# Variable Name: github.event.head_commit-timestamp
- name: Build project
  run: mlfront-shell -t "${{ github.event.head_commit-timestamp }}" ...
```

```yaml
# file: .gitlab-ci.yml

# CI System: GitLab CI
# Docs: https://docs.gitlab.com/ci/variables/predefined_variables/#predefined-variables
# Variable Name: CI_COMMIT_TIMESTAMP
# Variable Example: 2022-01-31T16:47:55-08:00
job:
  script:
    - mlfront-shell -t "$CI_COMMIT_TIMESTAMP" ...
```

Here are some example of using a monotonically increasing build number:

```yaml
# GitHub Actions: GITHUB_RUN_NUMBER https://docs.github.com/en/actions/reference/workflows-and-actions/variables
# GitLab CI: CI_PIPELINE_IID https://docs.gitlab.com/ci/variables/predefined_variables/
# Azure Pipelines: Build.BuildId https://learn.microsoft.com/en-us/azure/devops/pipelines/build/variables?view=azure-devops&tabs=yaml

# FILLMEIN ... wait for `-n RUN_NUMBER` option to complement `-t TIMESTAMP`
# FILLMEIN ... `-n` includes leading zeroes so lexographic comparisons work
```

### Form Document

A form has a [request slot](#slotrequest) that must always be specified by the user as a parameter.

More information can be supplied to the form as a JSON document.

The primary way today to supply this JSON document is through the command line syntax `get-object MODULE@VERSION -s SLOT -- CLI_FORM_DOC`, where **CLI_FORM_DOC** is a CLI-based recipe to construct a JSON document.

The `CLI_FORM_DOC` is a command-line analog to <https://www.w3.org/TR/html-json-forms/>:

- `... -- name=Jane` creates the form document `{"name":"Jane"}`
- `... -- pet[species]=Dahut kids[0]=Ashley` creates the form document `{"pets":{"species":"Dahut"},"kids":["Ashley"]}`
- `... -- +customer=customer.json` creates the form document `{"customer":...}` where the `...` is the JSON contents of `customer.json` (this is an extension to the W3C HTML JSON Forms specification)

While the reference implementation does not do this, other build systems are free to accept the form document directly from a HTML form as defined in <https://www.w3.org/TR/html-json-forms/>, or directly from a JSON document.

The form has a `options` JSON object to describe how the JSON document submitted to a form maps to command line options, arguments and variables.

The top-level fields of the form document are available in variables:

- `${PARAM.fieldname}` is the text of the form field named `fieldname`, but it will error if the field is not a JSON string
- `${PARAMFILE.fieldname}` is the file path to the JSON value of the form field named `fieldname`

The form document also contributes to the command line invocation of the form's `function`, if it has one.

> Key Concept: The **group** is a layout of command line options and arguments that covers both the order of options and arguments, and also breaks like `--` or subcommand names in the command line.

The command line, if a form has a `function`, is constructed as the concatenation of:

1. The function arguments in `"function": { "args": ... }`
2. The `{"options": "fields": [...]}` without any `group` field
3. The arguments in `groups[0]` (if any)
4. The `{"options": "fields": [...]}` with a `group: 0` field (if any)
5. The arguments in `groups[1]` (if any)
6. The `{"options": "fields": [...]}` with a `group: 1` field (if any)
7. ... and so on up to and including group 9
8. If `{"options": "document": {...}}` is present, an option and a location of a file containing the entire JSON form document

#### Option Groups

Groups are necessary when you want some options and arguments to go before or after a `--` seperator:

```sh
cmake -E rm -f -- file1 file2
```

or if you want some options and arguments to go before or after a subcommand:

```sh
git -C some_directory log --oneline
```

or if you need to order some options like how `-L` is required to be first:

```sh
find /home/user -L -name "*.log" -type f -exec rm {} \;
```

Since Windows especially but all operating systems have limits on the size of the command line arguments, the schema may specify a `responsefile` which consolidates all of the command line arguments at the end into a single file that can be read by the program (the first argument of the function `args`). Both MSVC and clang support these responsefiles.

### JSON Files

The schema is at [etc/jsonschema/mlfront-value.json](../etc/jsonschema/mlfront-value.json).

On Windows the JSON files are expected to be terminated with LF not CRLF line endings.

The build system is resilient to CRLF line endings:

- The [values canonical id](#vci---values-canonical-id) normalizes the JSON with all carriage returns removed before calculating the canonical id
- The [values checksums](#vck---values-checksum) normalizes the JSON with all carriage returns removed before conversion to an AST

However, there is one limitation:

- The byte positions, lines and columns are embedded by the reference implementation in the AST for error reporting. The byte positions are Unix byte positions. During error reporting, the byte positions on Windows will not be accurate if the JSON file is checked out by `git` with CRLF endings. This limitation may be fixed in the future if the reference implementation moves exclusively to lines and columns.

### JSON Canonicalization

The form is reconstructed as JSON exactly with the following keys (and only the following keys) in the exact order:

1. `assets.files.checksum.sha1`
2. `assets.files.checksum.sha256`
3. `assets.files.path`
4. `assets.files.size`
5. `assets.id`
6. `forms.function.args`
7. `forms.function.envmods`
8. `forms.id`
9. `forms.outputs.files.paths`
10. `forms.outputs.files.slots`
11. `forms.precommands.private`
12. `forms.precommands.public`
13. `schema_version.major`
14. `schema_version.minor`

with:

- all whitespace between JSON tokens removed from the canonicalized JSON
- all non-existent array values replaced with empty arrays, and all non-existent boolean balues replaced with `false`
- all `assets.files` sorted by the ascending lexographical UTF-8 byte encoding of `assets.files.path`
- `assets.files.checksum.sha1` removed if `assets.files.checksum.sha256` is present

The above canonicalization should conform to [RFC 8785]; if there are any ambiguities [RFC 8785] must be followed.

Of particular note is that the `assets.listing.origins` and `assets.files.origin`
fields are not present in the canonicalization since
the bundle path, checksum and size uniquely identifiy an asset. In other words,
if you have a locally cached file with the same checksum as a remote bundle,
you can substitute the locally cached file without changing identifiers
in the value store.

[RFC 8785]: https://www.rfc-editor.org/rfc/rfc8785

For example, the form:

```json
{
  "schema_version":{"major":1,"minor":0},
  "forms": [
    {
      "id": "FooBar_Baz@0.1.0",
      "precommands": {
        "private": [
          "private1"
        ],
        "public": [
          "public1"
        ]
      },
      "function": {
        "args": [
          "arg1"
        ],
        "envmods": [
          "envmod1"
        ]
      },
      "outputs": {
        "assets": [
          {
            "paths": [
              "outpath1"
            ],
            "slots": [
              "output1"
            ]
          }
        ]
      }
    }
  ],
  "bundles": [
    {
      "id": "DkDistribution_Std.Bundle@2.4.202508011516-signed",
      "listing": {
        "origins": [
          {
            "name": "github-release",
            "mirrors": [
              "https://github.com/diskuv/dk/releases/download/2.4.202508011516-signed"
            ]
          }
        ]
      },
      "assets": [
        {
          "origin": "github-release",
          "path": "SHA256.sig",
          "size": 151,
          "checksum": {
            "sha256": "0d281c9fe4a336b87a07e543be700e906e728becd7318fa17377d37c33be0f75"
          }
        },
        {
          "origin": "github-release",
          "path": "SHA256",
          "size": 559,
          "checksum": {
            "sha256": "4bd73809eda4fb2bf7459d2e58d202282627bac816f59a848fc24b5ad6a7159e"
          }
        }
      ]
    }
  ]
}
```

is canonicalized to:

```json
{"bundles":[{"assets":[{"checksum":{"sha256":"4bd73809eda4fb2bf7459d2e58d202282627bac816f59a848fc24b5ad6a7159e"},"path":"SHA256"},{"checksum":{"sha256":"0d281c9fe4a336b87a07e543be700e906e728becd7318fa17377d37c33be0f75"},"path":"SHA256.sig"}],"id":"DkDistribution_Std.Bundle@2.4.202508011516-signed"}],"forms":[{"function":{"args":["arg1"],"envmods":["envmod1"]},"id":"FooBar_Baz@0.1.0","outputs":{"assets":[{"paths":["outpath1"],"slots":["output1"]}]},"precommands":{"private":["private1"],"public":["public1"]}}],"schema_version":{"major":1,"minor":0}}
```

## Distributions

A **distribution** is a build that generates [values](#values). In the build system, metadata about distributions can be collected in the values.jsonc files along with *attestations*:

- An *attestation* is a cryptographically verifiable statement (ex. "the build produced bundle A at time T") that is signed by a human (ex. you) or a machine (ex. GitHub Actions).

To increase supply chain security guarantees, the build system will reject assets and objects that are produced by humans or machines without attestations that you have explicitly trusted.

The following sources of attestation are recognized by the reference implementation:

- A human can sign a build by using an [OpenBSD signify key](https://www.openbsd.org/papers/bsdcan-signify.html).
- GitHub Actions can sign a build using one of two [SLSA security levels](https://slsa.dev/spec/v1.0/levels):
  - Level 2: <https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations#generating-artifact-attestations-for-your-builds>
  - Level 3: <https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/increase-security-rating>

Unfortunately, GitLab does not yet provide a [minimal level of attestation](https://gitlab.com/groups/gitlab-org/-/epics/15859#note_2540189548).

The build system maintains a *trust store*, with the dk OpenBSD signify key for the `CommonsBase_Std` packages as the only trusted entity by default.

### Distributed Value Stores

A distribution includes a `.zip` file of some or all of the value store. Entries in the zipfile must be `./{value_id}`;
for example, `./vnmfdhn7lw4wepx2qiunrmgm4o5lx4wwsf2yfj7xyxggkg5kdsltq`.

The following values must be present:

- the "j" values file for any values.json with a form or bundle having a library identical to the distribution library `id`
- the "w" parsed values ast for any values.json with a form or bundle having a library identical to the distribution library `id`
- the "o" object file for any object having a library identical to the distribution library `id`

The following values will be ignored if present:

- the "c" constants

A unoptimal implementation can simply zip up the value store directory, but done frequently that leads to wasted bandwidth, storage and lengthier builds.

An optimal implementation only includes the necessary values.

### OpenBSD signify keys

[Securing OpenBSD From Us To You]: https://www.openbsd.org/papers/bsdcan-signify.html

The security policy is described in [Securing OpenBSD From Us To You].
Signify builds keys are automatically created specific to the user (you) on a machine. The private keys should not be shared except among a small set of trusted co-signers (ex. your manager and a peer).

Any OpenBSD signify key and any GitHub repository encountered by the build system is automatically denied.
However, you are prompted if you want to accept or deny the key or repository, with the default as deny.

When accepting an OpenBSD signify public key embedded in a values.json build file, the

- accompanying continuations that were signed with the private key are accepted. These continuations are public keys for the next version, and imported once and never overwritten.
- accompanying builds that were signed with the private key are accepted
- *all* builds signed with the private key that with packages that share the major + minor parts of the accompanying build are accepted

Once a major and minor component of a package has been signed, no lower versioned distribution key can claim:

- that major and minor component
- any later versions to that major and minor component

That may be difficult to understand without an example. We'll use the Key Rotation example from [Securing OpenBSD From Us To You], where OpenBSD is about to release OpenBSD version 5.6. They:

- have an existing public/private key pair for version 5.6
- have generated public/private key pairs for version 5.7 *before* 5.6 is released
- have generated public/private key pairs for version 5.8 *before* 5.6 is released

In the build system the version 5.6 would be a distribution; let's say `OpenBSD_Std@5.6.0`:

```json
{
  "distributions": {
    "id": "OpenBSD_Std@5.6.0",
    "producer": {
      "openbsd_signify": {
        // key from https://ftp.eu.openbsd.org/pub/OpenBSD/signify/openbsd-56-base.pub
        "public_key": "untrusted comment: openbsd 5.6 base public key\nRWR0EANmo9nqhpPbPUZDIBcRtrVcRwQxZ8UKGWY8Ui4RHi229KFL84wV"
      }
    },
    "continuations": {
      "attestation": {
        "openbsd_signify": {
          // this is a (fake) signature of SHA256(plaintext), where
          // plaintext is `{"5.7":"...","5.8":"..."}` (see below)
          "signature": "untrusted comment: signature from signify secret key\nRWTAeKJJ1MTF3UpxzBCu6NaM6HPJNTj5CZ+M5XNJKNeEHBLQSsstzHGbSo8rPYNgw3Z98pN7WKiIwBIyRrKuIdKBRA6qlaci6wI="
        }
      },
      "continuations": {
        // https://ftp.eu.openbsd.org/pub/OpenBSD/signify/openbsd-57-base.pub
        "5.7": "untrusted comment: openbsd 5.7 base public key\nRWSvUZXnw9gUb70PdeSNnpSmodCyIPJEGN1wWr+6Time1eP7KiWJ5eAM",
        // https://ftp.eu.openbsd.org/pub/OpenBSD/signify/openbsd-58-base.pub
        "5.8": "untrusted comment: openbsd 5.8 base public key\nRWQNNZXtC/MqP3Eiu+6FBz/qrxiWQwDhd+9Yljzp62UP4KzFmmvzVk60"
      }
    }
  }
}
```

In the same distribution in values.jsonc we also must have at least one build:

```json
{
  "distributions": {
    "id": "OpenBSD_Std@5.6.0",
    "producer": { /* ... */ },
    "continuations": { /* ... */ },
    "build": {
      "attestation": {
        // this is a (fake) signature of SHA256(plaintext), where
        // plaintext is `{"modules":...,...}` (see below)
        "openbsd_signify": "untrusted comment: signed by key c078a249d4c4c5dd\nRWTAeKJJ1MTF3UpxzBCu6NaM6HPJNTj5CZ+M5XNJKNeEHBLQSsstzHGbSo8rPYNgw3Z98pN7WKiIwBIyRrKuIdKBRA6qlaci6wI="
      },
      "build_to_sign": {
        "modules": ["DkExe_Std.Form@1.0.202501010000"],
        /* other build fields described in the mlfront-values.json schema */
      }
    }
  }
}
```

The `OpenBSD_Std@5.6.0` public key has signed for `DkExe_Std.Form@1.0.202501010000`, but can also sign
for any `DkExe_Std.Form@1.0.*` (and no others!) since those all share the major and minor number of the `DkExe_Std.Form` in values.jsonc.

The `OpenBSD_Std@5.7.0` public key can sign for either `DkExe_Std.Form@1.0.*` or a later version (ex. `DkExe_Std.Form@1.1.*`), but
cannot sign for both. That is, once a `OpenBSD_Std@5.7.0` public key is seen to accompany `DkExe_Std.Form@1.1.*`, the association `OpenBSD_Std@5.7.0 may-sign DkExe_Std.Form@1.1.*` is stored in the trust store, and it can no longer
sign any other major + minor version.

Most important, the `OpenBSD_Std@5.7.0` public key **cannot** sign for an earlier version (ex. `DkExe_Std.Form@0.7.*`) than `OpenBSD_Std@5.6.0`.

The net effect is a tendency of the trust store to increase versions over time, so that these OpenBSD signify keys have an implicit rotation policy as these versions increase. You choose how many keys you want to keep alive at any time (the current key plus the number of keys in your `continuations`), and do a rotation by doing a new build using a key from one of your continuations.

So, let's say you keep 2 continuations alive (plus the current key) like OpenBSD does. When you start using a key from one of your continuations (ex. `OpenBSD_Std@5.7.0`), you should will keep `N-1 = 1` keys in rotation (ex. "continuations" should contain `OpenBSD_Std@5.8.0` still) **and** create one new key (ex. "continuations" should have a new `OpenBSD_Std@5.9.0` key).

### GitHub SLSA Level 2

When accepting a GitHub repository (SLSA Level 2), the:

- accompanying builds attested by GitHub are accepted
- *all* builds attested by GitHub are accepted

The build system will download the GitHub CLI (using the default trusted `CommonsBase_Std` library) to do verification of the builds.

### GitHub SLSA Level 3

When accepting a known, vetted GitHub Actions script (SLSA Level 3), the:

- accompanying builds attested by GitHub are accepted
- *all* builds produced by the GitHub Actions scripts that are attested by GitHub are accepted

The build system will download the GitHub CLI (using the default trusted `CommonsBase_Std` library) to do verification of the builds.

## Graph

### Nodes

Each node in the graph has a key, a value id, a value sha256 and the value itself:

- The **key** is one of two types:
  - A **module key** is what you -- the user -- specify in a shell command as the MODULE_ID and SLOT or PATH in the [Value Shell Language](#value-shell-language-vsl)
  - A **checksum key** is the SHA-256 of some content
- A **value id** is a string which is a *value type* (defined below) and a set of fields, concatenated together and then SHA-256 base32-encoded. The value id serves as a unique key for the value in a value store.
  - The **value type** is a single letter that categorizes what the value is:

    | Value Type | What                | Docs                      |
    | ---------- | ------------------- | ------------------------- |
    | `o`        | object              | [Objects](#objects)       |
    | `b`        | bundle              | [Assets](#assets)         |
    | `a`        | asset               | [Assets](#assets)         |
    | `j`        | values.json file    | [JSON Files](#json-files) |
    | `v`        | values (parsed AST) | [JSON Files](#json-files) |
    | `c`        | built-in constants  | [Objects](#objects)       |
    | `s`        | source file         | FILLMEIN                  |

    All value types are *lowercase* for support on case-insensitive file systems.

- A **value** is a file whose content matches the value type. A values file is a `value.json` build file itself. An object is a zip archive of the output of a [form](#forms). Form, bundle and asset value are serialized parsed abstract syntax trees.
- A **value sha256** is a SHA-256 hex-encoded string of the value. That is, if you ran `certutil` (Windows), `sha256sum` (Linux) or `shasum -a 256` (macOS) on the value file, the *value sha256* is what you would see.

| Value Type | Key                                   | Value Id before SHA256 and base32          | Value                                     |
| ---------- | ------------------------------------- | ------------------------------------------ | ----------------------------------------- |
| `j`        | [V256](#v256---sha256-of-values-file) | [V256](#v256---sha256-of-values-file)      | json `{schema_version:,forms:,assets:}`   |
| `v`        | [VCI](#vci---values-canonical-id)     | [VCK](#vck---values-checksum)              | parsed `{schema_version:,forms:,assets:}` |
| `a`        | asset                                 | [P256](#p256---sha256-of-asset)            | contents of asset                         |
| `b`        | bundle                                | [Z256](#z256---sha256-of-zip-archive-file) | contents of zip archive file              |

#### Values Nodes

A `values.json` is parsed into an AST, and the AST is persisted directly from OCaml memory blocks and signed with the local build key.

The build system will verify the signature of the AST before loading the AST into memory.
If the signature does not match the local build key, or if the AST is incompatible with the memory
layout of the current process (see [compatibility tag](#ct---compatibility-tag)), the `j` values.json file
is fetched and re-parsed into a new AST.

Currently in the reference implementation the `v` AST is present in the distributable valuestore.
Distribution is only beneficial when the memory layout of the remote build system is compatible with the memory layout of the local build system,
and even then the parse time must be greater than the added download time.

**Security Note**: Distributed parsed AST adds a direct entry point into the build system's memory layout.
So other implementations and a future reference implementation should keep the AST in a local, non-distributable cache
where the parsed AST can be generated on-demand. <https://github.com/diskuv/dk/issues/44>

#### V256 - SHA256 of Values File

The SHA-256 (raw, not hex-encoded) of the `values.json` file that contains the bundle (or form or asset).

#### P256 - SHA256 of Asset

The hex-encoded SHA-256 of the asset. It is the `checksum.sha256` in the following asset:

```json
{
  "origin": "github-release",
  "path": "SHA256.sig",
  "size": 151,
  "checksum": {
    "sha256": "0d281c9fe4a336b87a07e543be700e906e728becd7318fa17377d37c33be0f75"
  }
}
```

#### Z256 - SHA256 of Zip Archive File

The hex-encoded SHA-256 of the zip archive generated from either:

- the output directory of a form
- the bundle directory for one or more bundle files

#### CT - Compatibility Tag

A string with the format `oc<OCAMLVERSION>_ws<OCAMLWORDSIZE>`.

For example, `oc414_wd64` is OCaml 4.14 with a 64-bit word size.

#### VCI - Values Canonical ID

The hex-encoded SHA256 of the `values.json` *canonicalized* JSON, stripped of all carriage returns (ASCII CR 13).

#### VCK - Values Checksum

The hex-encoded SHA256 of the marshalled AST of the carriage-return-stripped `values.json`.

The stripping of carriage returns occurs before the CST and AST parsing, so that any serialized AST uses the byte positions of the Unix-encoded JSON.

### Dependencies

| Value Type From | Value Type To | Why                                                 |
| --------------- | ------------- | --------------------------------------------------- |
| `a`             | `v`           | Rebuild bundle if contents of `values.json` changes |
| `a`             | `w`           | Rebuild bundle if parsed `values.json` changes      |
| `f`             | `v`           | Rebuild form if contents of `values.json` changes   |
| `f`             | `w`           | Rebuild form if parsed `values.json` changes        |
| `p`             | `v`           | Rebuild asset if contents of `values.json` changes  |
| `p`             | `w`           | Rebuild asset if parsed `values.json` changes       |
