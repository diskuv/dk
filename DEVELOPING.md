# Developing

## Rebasing

Do **not rebase**. some scripts in `cmake/` rely on `FetchContent`,
which in turn relies on `git` fast forward pulls. You will **break everybody**
if you rebase and then push.

> If a pushed rebase does happen, restore the HEAD to the old commit and then do a force push.

## Local `user.` prefix

When running dkcoder scripts inside a git clone of `dkcoder`, the
commands will be prefixed with `user.`.

For example, run `./dk user.dksdk.cmake.link` within a git clone of 'dkcoder'
to test it. Then, after your change is committed and push, other projects
will see that command as `./dk dksdk.cmake.link`.

## Publishing a winget package

### Publishing the first time

FIRST, install Komac Manifest Creator:

```sh
winget install komac
```

It is available for [Linux and macOS](https://github.com/russellbanks/Komac?tab=readme-ov-file) as well.

SECOND, komac needs a classic GitHub token to submit PRs to `winget-pkgs`.

This should be a classic token with the `public_repo` scope.

![Screenshot of classic token being created with public_repo scope selected](https://github.com/russellbanks/komac/assets/74878137/fbe4472e-dc53-4caf-ad2b-3bef75c47b07)

Adding to komac:

```bash
komac token add
```

THIRD, run in Powershell:

```powershell
# If you have already forked `winget-pkgs` then its `master` branch must be
# in sync with its upstream https://github.com/microsoft/winget-pkgs.
# If this command fails, do it manually from github.com/[yourname]/winget-pkgs.
komac sync

# The version was a mistake. It should have used DKSDK_WIN32_ASSEMBLY_VERSION not DKSDK_ASSET_VERSION
komac new Diskuv.dk `
    --version 2.3.202505282324 `
    --release-notes-url "https://github.com/diskuv/dk/releases/tag/2.3.202505282324" `
    --urls "https://diskuv.com/a/dk-distribution/2.3.202505282324/dist/dk-windows_x86_64.exe" `
    --moniker dk `
    --license "DkSDK SOFTWARE DEVELOPMENT KIT LICENSE AGREEMENT" `
    --license-url "https://diskuv.com/legal/" `
    --publisher "Diskuv, Inc." `
    --publisher-url "https://diskuv.com" `
    --publisher-support-url "https://github.com/diskuv/dk/issues" `
    --copyright "Copyright 2021 Diskuv, Inc." `
    --author "Diskuv, Inc. and contributors" `
    --short-description "A script runner and cross-compiler, written in OCaml." `
    --description "A script runner and cross-compiler, written in OCaml. Designed to produce CLIs and installers, to embed scripts in applications, and to configure software environments." `
    --package-locale en-US `
    --package-name dk `
    --package-url "https://github.com/diskuv/dk"
```

### Publishing new versions

| Value                        | Example                   | Where                                                                  |
| ---------------------------- | ------------------------- | ---------------------------------------------------------------------- |
| DKSDK_ASSET_VERSION          | `2.4.202506130531-signed` | Do PROCEDURE 1                                                         |
| DKSDK_WIN32_ASSEMBLY_VERSION | `2.4.25164.1`             | The `DKSDK_WIN32_ASSEMBLY_VERSION` in the `dksdk-constants` CI job [2] |

---

PROCEDURE 1:

Run `$env:DK_FACADE_TRACE="1"; $env:DK_FACADE="UPGRADE_ALWAYS"; ./dk --version`.

The `DKSDK_ASSET_VERSION` is the first "public_version" in the summary.json that is HEALTHY.

---

PROCEDURE 2:

> nit: This is overcomplicated. This value is visible in `DKSDK_WIN32_ASSEMBLY_VERSION` of the `dksdk-constants` CI job, so it can and should go into the SBOM.

Open the [Visual Studio Developer Command Prompt or Visual Studio Developer PowerShell](https://learn.microsoft.com/en-us/visualstudio/ide/reference/command-prompt-powershell):

```powershell
$DKSDK_ASSET_VERSION = "..."

mkdir "$env:TEMP\manifest"
iwr -OutFile "$env:TEMP\manifest\dk-windows_x86_64.exe" https://diskuv.com/a/dk-exe/$DKSDK_ASSET_VERSION/dk-windows_x86_64.exe
#   This is the version of the distribution (stdexport archive) not the dk.exe asset version. Run it to make sure it works.
& "$env:TEMP\manifest\dk-windows_x86_64.exe" --version

mt.exe -inputresource:"$env:TEMP\manifest\dk-windows_x86_64.exe;1" -out:"$env:TEMP\manifest\extracted.manifest" -validate_manifest
gc "$env:TEMP\manifest\extracted.manifest"
```

The DKSDK_WIN32_ASSEMBLY_VERSION will be in `<assemblyIdentity type="win32" name="DkDriver_Exec.Entry" version="XXXXX">`

---

```powershell
$DKSDK_ASSET_VERSION = "..."
$DKSDK_WIN32_ASSEMBLY_VERSION = "..."
komac update Diskuv.dk `
    --version "$DKSDK_WIN32_ASSEMBLY_VERSION" `
    --urls "https://diskuv.com/a/dk-exe/$DKSDK_ASSET_VERSION/dk-windows_x86_64.exe" `
    --release-notes-url "https://github.com/diskuv/dk/releases/tag/$DKSDK_ASSET_VERSION" `
    --submit
```
