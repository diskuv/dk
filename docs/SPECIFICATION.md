# Specification

- [Specification](#specification)
  - [Object](#object)
    - [Saving and Loading Objects](#saving-and-loading-objects)
    - [Thunk Variables](#thunk-variables)
      - [Variable Availability](#variable-availability)
      - [${SLOT.slotname}](#slotslotname)
      - [${NEWTHUNKS}](#newthunks)
      - [${/} directory separator](#-directory-separator)
      - [${.exe}](#exe)
      - [${HOME}](#home)
      - [${CACHE}](#cache)
      - [${DATA}](#data)
      - [${CONFIG}](#config)
      - [${STATE}](#state)
      - [${RUNTIME}](#runtime)
    - [Object Slots](#object-slots)
    - [Precommands](#precommands)
  - [Assets](#assets)
    - [Local Paths](#local-paths)
    - [Remote Paths](#remote-paths)
  - [Thunk Shell Language (TSL)](#thunk-shell-language-tsl)
    - [Variables available in TSL](#variables-available-in-tsl)
      - [get-object ID -s SLOT (-f FILE | -d DIR/)](#get-object-id--s-slot--f-file---d-dir)
      - [install-object ID -s SLOT (-f FILE | -d DIR/)](#install-object-id--s-slot--f-file---d-dir)
      - [pipe-object ID -s SLOT -x PIPE](#pipe-object-id--s-slot--x-pipe)
      - [get-asset-file ID FILE\_PATH (-f FILE | -d DIR/)](#get-asset-file-id-file_path--f-file---d-dir)
      - [get-asset ID (-f FILE | -d DIR/)](#get-asset-id--f-file---d-dir)
      - [Options: -f FILE and -d DIR](#options--f-file-and--d-dir)
      - [Option: \[-n STRIP\]](#option--n-strip)
      - [Option: \[-m MEMBER\]](#option--m-member)
  - [Thunk](#thunk)
    - [Thunk JSON Schema](#thunk-json-schema)
    - [Thunk Canonicalization](#thunk-canonicalization)
  - [Environment Modifications](#environment-modifications)
    - [+NAME=VALUE](#namevalue)
    - [-NAME](#-name)
    - [\<NAME=VALUE](#namevalue-1)
  - [Computations](#computations)

## Object

An object is a BLOB, which is a sequence of bytes. The object may be categorized by how the object comes to exist:

- a "generated" object created by a function (aka. "thunk"; more on these later!)
- anything else is an "input" object. For example, a file in your project may be an "input" object.

But to re-iterate: There is no concept of an object being a "file" or a "directory".
The object is just a sequence of bytes.

In both cases the thunk system treats the objects as immutable,
and the objects may be cached and/or persisted to disk whenever necessary.

When a thunk shell command is being run (described in the upcoming [Thunk Shell Language](#thunk-shell-language-tsl) section),
an object is made available on disk. At this time an object is "realized" into either a file or a directory.
That is the subject of the next [Saving and Loading Objects](#saving-and-loading-objects) section.

> Design Note: Why blur the distinction between files and directories?
> These objects are meant to be *cloud-friendly* so they need to
> have a canonical representation on cloud object stores like AWS S3. We don't need strict typing everywhere!
> And using a compressed archive means accessing the multiple
> outputs of a thunk is quite straightforward; in contrast, other build systems expose the user to added complexity
> (confer: [make: Handling Tools that Produce Many Outputs](https://www.gnu.org/software/automake/manual/html_node/Multiple-Outputs.html)).

### Saving and Loading Objects

When a thunk shell command reads an immutable object and saves it to a file (ex.
[get-object -f FILE](#get-object-id--s-slot--f-file---d-dir)),
the bytes of the immutable object are copied directly to the file.

When a thunk shell command reads an immutable object and saves it to a directory (ex.
[get-object -d DIR](#get-object-id--s-slot--f-file---d-dir)),
the bytes of the immutable object are:

- *when the bytes have a zip file header* uncompressed and unzipped into the directory
- *when the bytes do not have a zip file header* copied into the directory in a file named `THUNKOBJ`

When a thunk shell command saves a file as an immutable object, the file's bytes are saved as-is.

When a thunk shell command saves a directory as an immutable object, the directory is zipped and the zip archive bytes are saved.

That sounds inefficient, but the thunk system is allowed to optimize a set of thunk shell commands.
For example, if one shell command saves output into a directory,
and a second shell command reads data from created by the first shell command,
the thunk system can give the second shell command a symlink to the first directory
**without** using a zip archive as an intermediate artifact.

### Thunk Variables

#### Variable Availability

Some variables are available in the Thunk Shell Language (TSL); see [Variables available in TSL](#variables-available-in-tsl)

All variables are available in thunk `.function.args` and `.function.envmods`.

#### ${SLOT.slotname}

The output directory for the thunk.

User-specified types are registered with a thunk controller while built-in types are recognized by thunk controllers.

As of August 2025 the only built-in type is the `File.Agnostic` and `File._abi_` types.

Output directories for the install thunk controller are the end-user installation directories, while for other thunk controllers the output directory may be a sandbox temporary directory.

Expressions are only evaluated if *all* the output types the expression uses are valid for the thunk controller. For example, an expression that uses the output directory `${SLOT.File.Darwin_arm64}` will be skipped by the install thunk controller if the end-user machine's ABI is not `darwin_arm64`.

More generally:

| Type                        | Expression Evaluated? | Immediate Thunk Controller |
| --------------------------- | --------------------- | -------------------------- |
| `${SLOT.File.Agnostic}`     | Always                | A sandbox directory        |
| `${SLOT.File.Darwin_arm64}` | Always                | A sandbox directory        |

| Type                        | Expression Evaluated?              | Install Thunk Controller |
| --------------------------- | ---------------------------------- | ------------------------ |
| `${SLOT.File.Agnostic}`     | Always                             | The install directory    |
| `${SLOT.File.Darwin_arm64}` | Only if the end-user machine's ABI | The install directory    |
|                             | is `darwin_arm64`                  |                          |

#### ${NEWTHUNKS}

The directory that the thunk can place new `*.thunk.json` thunk object files into. These thunks are executed before the output files are evaluated.

It is an error to use `${NEWTHUNKS}` if `.function.newthunks` was not set to `true`.

#### ${/} directory separator

The directory separator. Except for one edge case (below), it is always `/` even on Windows. That is, thunk commands can assume the `/` separator, which can simplify thunk code when the thunk interacts with MSYS2.

There is a special edge case for the install thunk controller: the install thunk controller will set the directory separator to `\` on Windows and `/` on Unix.
This allows installation to canonicalized UNC paths for Windows like the remote file `\\Server2\Share\Test\Foo.txt` or [long-path capable](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=registry) `\\?\C:\Test\Foo.txt`.

#### ${.exe}

The executable suffix. Except for one edge case (below), it is always `.exe` even on Unix. This:

- reduces the need for seperate `.precommands` for Windows and Unix, and separate `.function.args`
- is a performance and space optimization since a common executable suffix increases the chances that non-ABI specific artifacts share the same hash across Windows and Unix.

There is a special edge case for the install thunk controller: the install thunk controller will set the executable suffix to `.exe` on Windows and `` on Unix.

#### ${HOME}

A temporary directory for the thunk.

There is a special edge case for the install thunk controller: the install thunk controller will set the home directory to be the OS-specific home directory for the install end-user.

#### ${CACHE}

A temporary directory for the thunk.

There is a special edge case for the install thunk controller: the install thunk controller will set the cache directory to be the OS-specific cache directory (ex. `Temporary Internet Files` on Windows, the XDG-compliant cache directory in Unix).

#### ${DATA}

A temporary directory for the thunk.

There is a special edge case for the install thunk controller: the install thunk controller will set the data directory to be the OS-specific data directory (ex. `LocalAppData` on Windows, the XDG-compliant data directory in Unix).

#### ${CONFIG}

A temporary directory for the thunk.

There is a special edge case for the install thunk controller: the install thunk controller will set the config directory to be the OS-specific config directory (ex. `LocalAppData` on Windows, the XDG-compliant config directory in Unix).

#### ${STATE}

A temporary directory for the thunk.

There is a special edge case for the install thunk controller: the install thunk controller will set the state directory to be the OS-specific data directory (ex. `LocalAppData` on Windows, the XDG-compliant state directory in Unix).

#### ${RUNTIME}

A temporary directory for the thunk.

There is a special edge case for the install thunk controller: the install thunk controller will set the runtime directory to be the OS-specific data directory (ex. `LocalAppData` on Windows, the XDG-compliant runtime directory in Unix).

### Object Slots

Each object has one or more slots. Each slot is a container for the object's files.

There are no built-in slots. However, `File.Agnostic` is the conventional slot for files that are ABI-agnostic.

The names of the slots are period-separated "MlFront standard namespace terms". Each of these terms:

- are drawn from the character set `'A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_'`
- must start with a capital letter
- must not contain a double underscore (`__`)
- must not be a MlFront library identifier (ie. a double camel cased string followed by an underscore and another camel cased string, like `XyzAbc_Def`)

### Precommands

The `precommands` are a **set** of commands run *before* an object's `function`. It is not a sequence of commands since you
cannot make assumptions about the order of the precommands.

The following optimizations are allowed:

- Precommands may be run in parallel.
- Precommands may be skipped if the requested slot does not match the precommand output slot.
  For example, let's say you issue the command `get-object THE_ID -s File.Agnostic`.
  Let's also say `THE_ID` object has two precommands:
  1. `get-asset-file ... -f ${SLOT.File.Agnostic}`
  2. `get-object ... -d ${SLOT.Something.Else}`
  Then the second precommand may be skipped because the requested slot `File.Agnostic` does not match `Something.Else`.

## Assets

Assets are remote or local files that are inputs to a build. All assets have SHA-256 checksums.

Assets are accessed with the [get-asset](#get-asset-id--f-file---d-dir) and [get-asset-file](#get-asset-file-id-file_path--f-file---d-dir) commands described in a later section of the document.

### Local Paths

A path, if it does not start with `https://` or `http://` is a *local* path.

A local path may be either:

- a file
- a directory

A local directory path is always zipped into a zip archive file. For reproducibility, the generated zip archive file will:

- have the zip last modification time to the earliest datetime (Jan 1, 1980 00:00:00)
- have each zip entry with its modification time to the earliest datetime (Jan 1, 1980 00:00:00)
- have each zip file entry set its extended attribute to be a "regular file" with `rw-r--r--` permissions
- use zip compression level 5. That is: "compression method: (2 bytes) ... 5 - The file is Reduced with compression factor 4" at [IANA application/zip]

[IANA application/zip]: https://www.iana.org/assignments/media-types/application/zip

### Remote Paths

A path, if it starts with `https://` or `http://` is a *remote* path.

## Thunk Shell Language (TSL)

**All encodings of TSL are UTF-8 unless explicitly noted as different.**

There is a POSIX shell styled language to query for objects and assets.
For example, the "command":

```sh
get-object OurStd_Std.Build.Clang@1.0.0 -s File.Agnostic -f clang.exe
```

will get the object with the id `OurStd_Std.Build.Clang@1.0.0` and place it in the `clang.exe` file.

There are two ways to run these shell commands:

1. Directly from the command line with the efficient `dk` implementation or the reference implementation `mlfront-shell`. For example, `dk get-object OurStd_Std.Build.Clang@1.0.0 -s File.Agnostic -f clang.exe`.
2. Embedded as "precommands" in a thunk file. For example,

   ```json
   { // ...
    "precommands": {
      "private": [
        "get-object OurStd_Std.Build.Clang@1.0.0 -s File.Agnostic -f clang.exe"
      ]
    },
    // ...
   }
   ```

When embedded as precommands in a thunk file, the command line (which is a JSON string) is split into arguments (a list of strings) using the [POSIX quoting rules at IEEE Std 1003.1-2024 / Shell & Utilities / Shell Command Language / 2.2 Quoting](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html#tag_19_02). However, no Here-Documents are accepted. The splitting is similar to Python's [shlex.split](https://docs.python.org/3/library/shlex.html#shlex.split).

All commands have a output path (ex. `-f echo.exe`). Most command have two forms:

- `-f FILE` (ex. `-f echo.exe`)
- `-d DIR/` or `-d DIR\\` (ex. `-d target/`)

but some commands may only have the `-d DIR/` or `-d DIR\\` directory output.

The best practice is to use the forward slash (`/`) as directory separator in the output paths for readability (no escaping in JSON) and portability (forward slashes don't work on Unix).
However, when the directory is a UNC path on Windows (ex. `\\Server2\Share\Test\Foo.txt`) you should use backward slashes.

For security, the commands may be evaluated in a sandbox or a chroot environment. Do not use `..` path segments or they may fail to resolve in sandboxes.

### Variables available in TSL

- `${SLOT.slotname}`
- `${/}`
- `${SRC}`
- `${HOME}`
- `${DATA}`
- `${CONFIG}`
- `${STATE}`
- `${RUNTIME}`

#### get-object ID -s SLOT (-f FILE | -d DIR/)

Get the contents of the slot `SLOT` for the object with identifier `ID`.

| Option      | Description                                                                   |
| ----------- | ----------------------------------------------------------------------------- |
| `-f FILE`   | Place object in `FILE`                                                        |
| `-d DIR/`   | The object must be a zip archive, and its contents are extracted into `DIR/`. |
| `-n STRIP`  | See [Option: [-n STRIP]](#option--n-strip)                                    |
| `-m MEMBER` | See [Option: [-m MEMBER](#option--m-member)]                                  |

See [Options: -f FILE and -d DIR](#options--f-file-and--d-dir) for output path restrictions.

#### install-object ID -s SLOT (-f FILE | -d DIR/)

Install the contents of the slot `SLOT` for the object with identifier `ID`.

| Option      | Description                                                                                            |
| ----------- | ------------------------------------------------------------------------------------------------------ |
| `-f FILE`   | Install object to `FILE`                                                                               |
| `-d DIR/`   | Install contents of the zip archive to the install directory `DIR/`. The object must be a zip archive. |
| `-n STRIP`  | See [Option: [-n STRIP]](#option--n-strip)                                                             |
| `-m MEMBER` | See [Option: [-m MEMBER](#option--m-member)]                                                           |

**More than one `install-object` can use the same install directory `DIR`**.

See [Options: -f FILE and -d DIR](#options--f-file-and--d-dir) for output path restrictions.

#### pipe-object ID -s SLOT -x PIPE

Write the contents of the slot `SLOT` for the object with identifier `ID` to the pipe named `PIPE`.

| Option      | Description                                  |
| ----------- | -------------------------------------------- |
| `-m MEMBER` | See [Option: [-m MEMBER](#option--m-member)] |

No two `pipe-object` commands may write to the same pipe `PIPE`.

The location of the pipe is available using the variable `${PIPE.name}`.

Typically, the pipe given to the thunk will be a PIPE_ACCESS_OUTBOUND named pipe server on Windows (ex. `\\ServerName\pipe\SomePipe`) and a write-only fifo pipe on Unix. To be portable, you should:

- read from the pipe zero or one time. Do not re-read from the pipe.
- read the data sequentially from the pipe. Do not use random access read in the pipe.
- expect the read from the pipe, especially the first byte, to take a long time.
- use PowerShell or a library in your favorite language to detect and read from the named pipe on Windows

Piping is an **optimization**. If a thunk controller implementation does not support threading, the pipe *will* be a regular file. However, if pipeline is supported, then the thunk controller only has to kick off the build of the thunk dependency `ID SLOT` when you *first access the pipe*.

Key Optimization: If you don't access the pipe at all in your thunk, then you have saved the cost (clock time, compute, space) of the build for your dependency `ID SLOT`.

So in situations where the content is conditional (ie. read by the thunk only in certain situations) and expensive (ie. the `ID SLOT` is large or has a time-consuming build), use `pipe-object`.

Here is an example use of a pipe:

```json
{
  "$schema": "https://github.com/diskuv/dk/raw/refs/heads/1.0/etc/jsonschema/mlfront-thunk.json",
  "version": {
    "major": 1,
    "minor": 0
  },
  "precommands": [
    "install-object SomeScripting_Minimal.Env -s File.Agnostic -d usr/"
    "get-asset-file MyAssets_Std.Scripts@1.0.0 -p script/get-size.cmd -s File.Agnostic -f get-size.cmd",
    "get-asset-file MyAssets_Std.Scripts@1.0.0 -p script/get-size.sh  -s File.Agnostic -f get-size.sh",
    "pipe-object    SomeContent_Std.DataFile -s File.Agnostic -x data-file-pipe"
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
      "${SLOT.File.Agnostic}"
    ]
  },
  "assets": [
    {
      "listing_unencrypted": {
        "spec_version": 2,
        "name": "MyAssets_Std.Scripts",
        "version": "1.0.0"
      },
      "listing": {
        "origins": [ { "name": "project-tree", "mirrors": [ "." ] } ]
      },
      "files": [
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
    { "slots": ["File.Agnostic"], "paths": ["size.txt"] }
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

#### get-asset-file ID FILE_PATH (-f FILE | -d DIR/)

Get the contents of the asset file at `FILE_PATH` for the asset with identifier `ID`.

NOTE: If the version of the asset's `ID` is just a `MAJOR.MINOR` then the **latest** asset patch number for that major, minor combination is fetched.

| Option      | Description                                                                       |
| ----------- | --------------------------------------------------------------------------------- |
| `-f FILE`   | Place asset file in `FILE`                                                        |
| `-d DIR/`   | The asset file must be a zip archive, and its contents are extracted into `DIR/`. |
| `-n STRIP`  | See [Option: [-n STRIP]](#option--n-strip)                                        |
| `-m MEMBER` | See [Option: [-m MEMBER](#option--m-member)]                                      |

See [Options: -f FILE and -d DIR](#options--f-file-and--d-dir) for output path restrictions.

#### get-asset ID (-f FILE | -d DIR/)

Get the archive file for the asset with identifier `ID`.

NOTE: If the version of the asset's `ID` is just a `MAJOR.MINOR` then the **latest** asset patch number for that major, minor combination is fetched.

| Option     | Description                                                                       |
| ---------- | --------------------------------------------------------------------------------- |
| `-f FILE`  | Place asset in `FILE`. `FILE` will be a zip archive with **all** the asset files. |
| `-d DIR/`  | **All** the asset files will be extracted into `DIR/`.                            |
| `-n STRIP` | See [Option: [-n STRIP]](#option--n-strip)                                        |

See [Options: -f FILE and -d DIR](#options--f-file-and--d-dir) for output path restrictions.

*What about the `-m MEMBER` option?*

Use [get-asset-file](#get-asset-file-id-file_path--f-file---d-dir) to get a specific asset file.
Having a `-m MEMBER` option would be equivalent but redundant and slightly confusing since
not much about assets implies they are stored as archives.

#### Options: -f FILE and -d DIR

No command may write to the same file. Specifically:

- It is an error to have more than one `get-object` or `get-asset` or `get-asset-file` or `resume-object` or `install-object` use the same `FILE`.
- It is an error to have more than one `get-object` or `get-asset` or `get-asset-file` or `resume-object` use the same `DIR` or otherwise overlap the same `DIR`. Overlapping means one command can't write to the subdirectory of another command's `DIR`.

Use [`install-object`](#install-object-id--s-slot--f-file---d-dir) when you want to write into the same directory.
Even so, no `install-object` may extracted the same file in the same install directory.

#### Option: [-n STRIP]

`-n STRIP` defaults to zero.

`STRIP` is how many levels of the zip archive to strip. Many zip archives place all content under a versioned root directory:

```text
llvmorg-19.1.3-win32/
  LICENSE.txt
  README.txt
  src/
```

To leave the directory structure as-is, set `STRIP` to `0`. To strip away the top level `llvmorg-19.1.3-win32` directory, set `STRIP` to `1`.

#### Option: [-m MEMBER]

Gets the zip file member from the object or asset file, which must be a zip archive.

## Thunk

### Thunk JSON Schema

The schema is at [src/MlFront_Thunk/json/schema.json](json/schema.json).

### Thunk Canonicalization

The thunk is reconstructed as JSON exactly with the following keys (and only the following keys) in the exact order:

1. `assets.files.checksum.sha256`
2. `assets.files.path`
3. `assets.listing_unencrypted.name`
4. `assets.listing_unencrypted.version`
5. `function.args`
6. `function.envmods`
7. `function.newthunks`
8. `module_id.name`
9. `module_id.package`
10. `module_id.version`
11. `outputs.files.paths`
12. `outputs.files.slots`
13. `precommands.private`
14. `precommands.public`
15. `schema_version.major`
16. `schema_version.minor`

with:

- all whitespace between JSON tokens removed from the canonicalized JSON
- all non-existent array values replaced with empty arrays, and all non-existent boolean balues replaced with `false`
- all `assets.files` sorted by the ascending lexographical UTF-8 byte encoding of `assets.files.path`

The above canonicalization should conform to [RFC 8785]; if there are any ambiguities [RFC 8785] must be followed.

Of particular note is that the `assets.origins`, `assets.files.origin` and `assets.files.size` fields are not present in the canonicalization
since the asset path and checksum uniquely identifiy an asset file. In other words, if you have a locally cached file
with the same checksum as a remote asset, you can substitute the locally cached file without changing identifiers
in the object store.

[RFC 8785]: https://www.rfc-editor.org/rfc/rfc8785

For example, the thunk:

```json
{
  "$schema": "https://github.com/diskuv/dk/raw/refs/heads/1.0/etc/jsonschema/mlfront-thunk.json",
  "schema_version":{
    "major":1,
    "minor":0
  },
  "module_id":{
    "name": "example",
    "version":{
      "major":1,
      "minor":0
    }
  },
  "precommands": {
    "private": [ "VDSo_TM=gcc" ]
  },
  "function": {
    "args": ["first"],
    "envmods": [
      "+OCAMLRUNPARAM=b"
    ]
  },
  "outputs": {
    "files": [ ["hello.i"] ]
  }
}
```

is canonicalized to:

```json
{"assets":[],"function":{"args":["first"],"envmods":["+OCAMLRUNPARAM=b"],"newthunks":false},"module_id":{"name":"example","version":{"major":1,"minor":0}},"outputs":[["hello.i"]],"precommands":{"private":["VDSo_TM=gcc"],"public":[]},"schema_version":{"major":1,"minor":0}}
```

## Environment Modifications

The names in the environment follow the [POSIX specification](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap08.html), except on Windows the environment names are folded to be case-insensitive.
The rules are:

- The character set for the environment names is the [Portable Character Set](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap06.html#tagtcjh_3) except `=` (`<U003D>`) and `NUL`.
- The environment name can't start with a digit
- MlFront restricts more strictly than POSIX for whitespace: the only whitespace accepted are spaces (`<U0020>`). Linefeeds and other non-space whitespace are not accepted.
- MlFront restricts more strictly than POSIX for control characters: the `BEL` (`<U0007>`) is not accepted.

The values in the environment are encoded as UTF-8 and may contain [variables](#thunk-variables).

Because the first character of an environment modification unambiguously determines the type of modification, like `+` in `+NAME=VALUE` or `-` in `-NAME`, no escaping of environment names or values is required.

### +NAME=VALUE

Add or set the environment variable with name `NAME` to `VALUE`.

The `VALUE` may contain [variables](#thunk-variables).

You may use `NAME=` to set the environment variable to empty. It is preferable to use [-NAME](#-name) since programs have inconsistent behavior when environment variables are empty; some treat empty as an unset environment variable, while others treat empty as empty.

### -NAME

Remove the environment variable with name `NAME`.

### <NAME=VALUE

Prepends `VALUE` and a path separator to the environment variable with name `NAME`.
However, the path seperator (`;` or `:` on Windows or Unix, respectively) is not added if the environment variable is empty.

The `VALUE` may contain [variables](#thunk-variables).

For example, `PATH+=C:\Windows\system32` prepends `C:\Windows\system32;` to the PATH on Windows and prepends `C:\Windows\system32:` to the PATH on Unix.
In this example, the Unix prepending does not make sense, which is why the best practice is to use [variables](#thunk-variables) for the `VALUE`
like `PATH+=${CACHE}${/}bin` so the modification is portable across operating systems.

## Computations

Only the [`${SLOT.slotname}`](#slotslotname) referenced in a thunk files are available to other thunks.
