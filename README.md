# dk - a parameterizable, incremental, remote-cacheable build system

You distribute source code to users. You may be a package maintainer, a contractor who must give source to their customers, an educator with students, etc. Getting users to *build* it is hard; not every user is a software engineer with Administrator/root access, on Linux, or comfortable with language SDKs, Docker, or nix.

With `dk` your users clone your project and run one command on Windows, macOS or
Linux. `dk` fetches the toolchain, builds, and runs the software - with SHA-256
checksums and signify signatures across the supply chain - and deleting the
generated `t/` directory removes every trace of it.

- Full guides + specification: <https://diskuv.com/dk/help/latest/>
- In this repository: [SPECIFICATION.md](docs/SPECIFICATION.md) (the formal spec) and
  [DK0-REFERENCE.md](docs/DK0-REFERENCE.md) (the `dk0` reference implementation).

## Commands

| Command                                                  | What it does                                                   |
| -------------------------------------------------------- | -------------------------------------------------------------- |
| `get-object FORM -s SLOT [-m MEMBER] [-f FILE] [-d DIR]` | Build an object from a form rule into a new file or directory  |
| `merge-object FORM -s SLOT [-d DIR]`                     | Build an object and merge its files into an existing directory |
| `get-asset BUNDLE -p PATH [-f FILE] [-d DIR]`            | Retrieve one asset from a bundle                               |
| `get-bundle BUNDLE [-f FILE] [-d DIR]`                   | Retrieve all assets in a bundle as one archive                 |
| `run-function RULE ...`                                  | Run a function rule and write its object out                   |
| `run-object FORM [-s SLOT]`                              | Run an executable built by a form rule                         |
| `run-asset ASSET ...`                                    | Run an executable fetched from an asset                        |
| `enter-object OBJECT -s SLOT`                            | Open an incomplete or failed object for debugging              |

The full command reference and options live at <https://diskuv.com/dk/help/latest/>.

## Comparisons

*Italics* are a pending feature.

| Tool      | Features better with the tool | Features better with `dk`          |
| --------- | ----------------------------- | ---------------------------------- |
| Nix       | Huge set of packages          | Works on Windows. Static types.    |
| (contd.)  |                               | *Signify-backed supply chain*      |
| Buck2 +   | Scales to millions of files   | Works well outside of monorepo     |
| ... Bazel | Backed by Big Tech            | Easier to adopt                    |
| Ninja     | Integrated with CMake. Fast   | Cloud-friendly, sharable artifacts |
| (contd.)  | Rules to simplify build files | *Pending integration in scripts*   |
| (contd.)  | Multithreading                | *Pending integration in dk*        |
| Docker    | Huge set of images            | Works well on Windows              |
| (contd.)  | Works very well in CI         | Works in CI and *during installs*  |

## Licenses

Copyright 2023 Diskuv, Inc.

The `./dk`, `./dk0`, `./dk.cmd` and `./dk0.cmd` build scripts ("dk") are
available under the Open Software License version 3.0,
<https://opensource.org/license/osl-3-0-php/>.
A guide to the Open Software License version 3.0 is available at
<https://rosenlaw.com/OSL3.0-explained.htm>.

"dk" downloads parts of the 7-Zip program. 7-Zip is licensed under the GNU LGPL license.
The source code for 7-Zip can be found at <www.7-zip.org>. Attribute requirements are available at <https://www.7-zip.org/faq.html>.

`./dk` and `./dk.cmd` download OCaml, codept and other binaries at first run and on each version upgrade.
OCaml has a [LGPL2.1 license with Static Linking Exceptions](./LICENSE-LGPL21-ocaml).
codept has a [LGPL2.1 license with Static Linking Exceptions](./LICENSE-LGPL21-octachron).
The other binaries are DkSDK Coder Runtime Binaries © 2023 by Diskuv, Inc.
These DkSDK Coder Runtime Binaries are licensed under Attribution-NoDerivatives 4.0 International.
To view a copy of this license, visit <http://creativecommons.org/licenses/by-nd/4.0/>.

"dk" acts as a package manager: you tell it what packages you want to download and run.
Those packages have independent licenses and you may be prompted to accept licenses.
Those licenses include but are not limited to:

- The [DkSDK SOFTWARE DEVELOPMENT KIT LICENSE AGREEMENT](./LICENSE-DKSDK)

## Related Open Source

- DkML compiler: <https://github.com/diskuv/dkml-compiler> and <https://gitlab.com/dkml/distributions/dkml>
- MlFront: Apache 2.0 core build libraries. <https://gitlab.com/dkml/build-tools/MlFront>. Used for 3rd party, dk-compatible build systems.
- DkZero: OSL 3.0. <https://gitlab.com/dkml/build-tools/MlFront>. Source code executable (ie. `dk0.exe`) used by `./dk0` and `./dk0.cmd`.
