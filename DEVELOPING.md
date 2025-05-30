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

SECOND, make a file `$env:TEMP\komac.env.ps1`:

```powershell
$env:GITHUB_TOKEN = "...the..public_repo..token..described..at..https://github.com/russellbanks/Komac?tab=readme-ov-file#github-token..."
```

THIRD, run in Powershell:

```powershell
& "$env:TEMP\komac.env.ps1"
Remove-Item "$env:TEMP\komac.env.ps1"
```

FOURTH, run in Powershell:

```powershell
# If you have already forked `winget-pkgs` then its `master` branch must be
# in sync with its upstream https://github.com/microsoft/winget-pkgs.
# If this command fails, do it manually from github.com/[yourname]/winget-pkgs.
komac sync

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
