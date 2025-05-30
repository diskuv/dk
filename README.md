# dk - A script runner and cross-compiler

> A few clicks from your web browser and four (4) minutes
> later you and your Windows and macOS users can start
> scripting with **DkCoder**. And all users,
> including glibc-based Linux desktop users, can use their
> Unix shells or Windows PowerShell. Nothing needs to be
> pre-installed on Windows and macOS. Just copy and paste
> two lines (you'll see examples soon) and your script is
> running and your project is editable with an LSP-capable
> IDE like Visual Studio Code.
>
> Unlike most scripting frameworks, DkCoder solves the problem of scale: you start with small scripts that do immediately useful things for you and your team, and when inevitably you need to expand, distribute or embed those scripts to make full-featured applications, you don't need to throw out what you have already written. DkCoder is a re-imagining of the scripting experience that re-uses the best historical ideas:
>
> 1. You don't write build files. *If that sounds like Unix /bin/sh or the Windows Command Prompt, that is intentional.*
> 1. Most files you write can be immediately run. *If that sounds like how Python scripts are almost indistinguishable from Python modules, or like JavaScript modules, that is intentional.*
> 1. Most files you write can be referenced with a fully-qualified name. *If that sounds like Java packages and how that has been proven to scale to large code bases, that is intentional.*
> 1. Your scripts play well together and don't bit rot. *It is conventional to add static typing (Typescript, mypy) when scripting projects get large. DkCoder has type-safety from Day One that is safer and easier to use.*

That quote was from the main documentation site <https://diskuv.com/dksdk/coder/2024-intro-scripting/>.
**You are highly encouraged to visit that site!**

## Quick Start

The recommended way to execute DkCoder scripts is with the help of the `./dk` tool.
The `./dk` tool runs the build script you specify, downloading support files beforehand if necessary.
As a result, you can get up and running quickly without having to follow manual installation steps.
*Gradle users: If that sounds like the easy-to-use Gradle Wrapper, that is intentional.*

The `./dk` tool is compatible with Windows PowerShell, macOS and glibc-based desktop Linux. It can also run on Windows Command Prompt if you invoke it with `.\dk` rather than `./dk`.

Example 1. The game of Snoke as a set of scripts:

```sh
git clone --branch V0_2 https://gitlab.com/diskuv/samples/dkcoder/SanetteBogue.git

./SanetteBogue/dk SanetteBogue_Snoke.Snoke
```

Example 2. The documentation site as a set of scripts (on Windows there is an alpha bug; rerun the `--serve` command if it fails the first time):

```sh
git clone --branch V0_3 https://gitlab.com/diskuv/samples/dkcoder/DkHelloScript.git

./DkHelloScript/dk DkHelloScript_Std.Y33Article --serve
```

Example 3. A production webhook microservice as a set of scripts:

```sh
git clone --branch V0_3 https://gitlab.com/diskuv/samples/devops/DkSubscribeWebhook.git

./DkSubscribeWebhook/dk DkSubscribeWebhook_Std.Subscriptions subscriptions-serve --help
```

## Installing

In Windows PowerShell, macOS and desktop Linux:

```sh
git clone https://github.com/diskuv/dk.git
dk/dk user.dkml.wrapper.upgrade HERE
./dk dkml.wrapper.upgrade DONE
```

In Windows Command Prompt:

```dosbatch
git clone https://github.com/diskuv/dk.git
dk\dk user.dkml.wrapper.upgrade HERE
.\dk dkml.wrapper.upgrade DONE
```

## Known Issues

The `dk` executable on Windows requires Visual C++ redistributables. They are typically already
present on PCs, except brand-new PCs. You may need to download and install
the [Visual C++ redistributables from Microsoft](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#latest-microsoft-visual-c-redistributable-version).

## Quiet Mode

Any command that ends in `Quiet`, like `./dk RunQuiet`, will not print messages while dk initializes itself.
However, if `sudo` is required for elevation, then commands will be echoed to the terminal.

## Licenses

Copyright 2023 Diskuv, Inc.

The `./dk` and `./dk.cmd` build scripts ("dk") are
available under the Open Software License version 3.0,
<https://opensource.org/license/osl-3-0-php/>.
A guide to the Open Software License version 3.0 is available at
<https://rosenlaw.com/OSL3.0-explained.htm>.

`dk.cmd` downloads parts of the 7-Zip program. 7-Zip is licensed under the GNU LGPL license.
The source code for 7-Zip can be found at <www.7-zip.org>. Attribute requirements are available at <https://www.7-zip.org/faq.html>.

"dk" downloads OCaml, codept and other binaries at first run and on each version upgrade.
OCaml has a [LPGL2.1 license with Static Linking Exceptions](./LICENSE-LGPL21-ocaml).
codept has a [LPGL2.1 license with Static Linking Exceptions](./LICENSE-LGPL21-octachron).
The other binaries are DkSDK Coder Runtime Binaries © 2023 by Diskuv, Inc.
These DkSDK Coder Runtime Binaries are licensed under Attribution-NoDerivatives 4.0 International.
To view a copy of this license, visit <http://creativecommons.org/licenses/by-nd/4.0/>.

"dk" acts as a package manager; you run `./dk` and tell it what packages you want to download
and run. These packages have independent licenses and you may be prompted to accept a license.
Those licenses include but are not limited to:

- The [DkSDK SOFTWARE DEVELOPMENT KIT LICENSE AGREEMENT](./LICENSE-DKSDK)
