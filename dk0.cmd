@ECHO OFF
REM ##########################################################################
REM # File: dk\dk0.cmd                                                       #
REM #                                                                        #
REM # Copyright 2025 Diskuv, Inc.                                            #
REM #                                                                        #
REM # Licensed under the Open Software License version 3.0                   #
REM # (the "License"); you may not use this file except in compliance        #
REM # with the License. You may obtain a copy of the License at              #
REM #                                                                        #
REM #     https://opensource.org/license/osl-3-0-php/                        #
REM #                                                                        #
REM ##########################################################################

REM Recommendation: Place this file in source control.
REM
REM Manifest-driven, self-updating dk0 launcher for Windows. Pure batch on the
REM hot path -- PowerShell is used only as a last-resort download fallback (after
REM curl and BITSADMIN), never for logic -- so it runs on locked-down machines.
REM   1. download the pinned mlfront-signify verifier, check it against the
REM      SHA-256 baked below (the anchor -- not the manifest, so no circularity);
REM   2. verify the signify signature over the manifest with the baked pubkey;
REM   3. read the manifest's dk0 SHA-256 (plain key=value, no JSON), download and
REM      cache dk0.exe, then exec it.
REM This file never rewrites itself.

SETLOCAL ENABLEDELAYEDEXPANSION

SET "DK_PROJECT_DIR=%~dp0"
SET "DKCODER_PWD=%CD%"

REM ===== BAKED TRUST ROOT (rotates rarely; updated only on key/verifier rotation) =====
SET "SIGNIFY_PUBKEY_B64=RWTMq/GqeeJ06ACy7By/H05vvtpc3ZPEKlbnDm9fIQxpkgTV92is6YHD"
SET "DK_CKSUM_SIGNIFY=ebe1aa87a3eb87ed6769782a31916fab72bbdf0ced22d6ddd9a7a455e23e2c68"
REM The verifier is pinned by version+checksum and fetched from its GitLab package
REM (a direct download, not the throttled listing API); the site serves only the
REM signed manifest and the wrappers.
SET "SIGNIFY_PKG_VER=2.4.2.271"
IF "%DK0_BASE_URL%"=="" (SET "DK_BASE_URL=https://diskuv.com/dk") ELSE (SET "DK_BASE_URL=%DK0_BASE_URL%")
REM ====================================================================================

IF "%DKCODER_DATA_HOME%"=="" (SET "DK_DATA_HOME=%LOCALAPPDATA%\Programs\dk0") ELSE (SET "DK_DATA_HOME=%DKCODER_DATA_HOME%")
SET "DK_VDIR=%DK_DATA_HOME%\verifier"
IF NOT EXIST "%DK_VDIR%" MKDIR "%DK_VDIR%" >NUL 2>&1

REM 1. Pinned verifier from GitLab, checked against the baked SHA-256 (the anchor).
SET "DK_SIGNIFY=%DK_VDIR%\mlfront-signify-%DK_CKSUM_SIGNIFY%.exe"
IF NOT EXIST "%DK_SIGNIFY%" (
    CALL :fetch "https://gitlab.com/api/v4/projects/60486861/packages/generic/mlfront-signify/%SIGNIFY_PKG_VER%/mlfront-signify-windows_x86_64.exe" "%DK_SIGNIFY%"
    IF !ERRORLEVEL! NEQ 0 EXIT /B 1
)
CALL :sha256 "%DK_SIGNIFY%" DK_SIG_ACTUAL
IF /I NOT "!DK_SIG_ACTUAL!"=="%DK_CKSUM_SIGNIFY%" (
    ECHO dk0: mlfront-signify checksum mismatch ^(verifier not trusted^) 1>&2
    EXIT /B 1
)

REM 2. Write the baked public key (pure batch; signify accepts the CRLF form).
> "%DK_VDIR%\dk0.pub" ECHO untrusted comment: dk0 signify public key
>> "%DK_VDIR%\dk0.pub" ECHO %SIGNIFY_PUBKEY_B64%

REM 3. Read the dk.u pin: the version between quotes on the actual_version line.
SET "DK_PIN="
IF EXIST "%DK_PROJECT_DIR%dk.u" CALL :readpin

REM --self-update handled by dk0.exe (it edits dk.u safely); see below after resolve.
SET "DK_SELFUPDATE=0"
IF "%~1"=="--self-update" SET "DK_SELFUPDATE=1"

REM 4. Verify the manifest and resolve the version + dk0 checksum. Self-update and
REM    an unpinned project both use the latest manifest.
IF "%DK_SELFUPDATE%"=="1" (SET "DK_WANT=") ELSE (SET "DK_WANT=%DK_PIN%")
CALL :getmanifest "%DK_WANT%"
IF !ERRORLEVEL! NEQ 0 EXIT /B 1
IF "%DK_WANT%"=="" (
    CALL :mval version DK_VER
    IF "%DK_SELFUPDATE%"=="0" IF "%DK_PIN%"=="" ECHO dk0: no actual_version pin in dk.u; using latest !DK_VER! ^(run "dk0 --self-update" to pin^) 1>&2
) ELSE (
    SET "DK_VER=%DK_PIN%"
)
IF "!DK_VER!"=="" (ECHO dk0: could not resolve a dk0 version 1>&2 & EXIT /B 1)
CALL :mval dk0_windows_x86_64 DK_CKSUM
IF "!DK_CKSUM!"=="" (ECHO dk0: manifest has no dk0 build for windows_x86_64 ^(version !DK_VER!^) 1>&2 & EXIT /B 3)

REM 5. Cache + download dk0.exe (version-keyed dir; never overwrite a running exe).
SET "DK_EXEDIR=%DK_DATA_HOME%\dk0exe-!DK_VER!-windows_x86_64"
IF NOT EXIST "!DK_EXEDIR!" MKDIR "!DK_EXEDIR!" >NUL 2>&1
SET "DK_EXE=!DK_EXEDIR!\dk0.exe"
SET "DK_NEED_EXE=1"
IF EXIST "!DK_EXE!" (
    CALL :sha256 "!DK_EXE!" DK_EXE_ACTUAL
    IF /I "!DK_EXE_ACTUAL!"=="!DK_CKSUM!" SET "DK_NEED_EXE=0"
)
IF !DK_NEED_EXE! EQU 1 (
    CALL :fetch "https://gitlab.com/api/v4/projects/60486861/packages/generic/dk0/!DK_VER!/dk0-windows_x86_64.exe" "!DK_EXE!"
    IF !ERRORLEVEL! NEQ 0 EXIT /B 1
    CALL :sha256 "!DK_EXE!" DK_EXE_ACTUAL
    IF /I NOT "!DK_EXE_ACTUAL!"=="!DK_CKSUM!" (ECHO dk0: dk0.exe checksum mismatch 1>&2 & EXIT /B 1)
)

REM 6. Launcher store GC. Every dk0 version installs into its own dk0exe-*
REM    directory and old versions accumulate forever. Mark the pinned version
REM    (and the current verifier) as used, then remove version directories and
REM    superseded verifier binaries no launcher has used in 30 days. Everything
REM    here re-downloads on demand from its signed manifest, so deletion is
REM    always safe; pruning must never break the launch, so every step
REM    suppresses errors. Pure batch: the mtime bump is a create+delete of a
REM    marker file (updates the directory timestamp), the verifier bump is the
REM    batch copy-touch idiom, and the age test is FORFILES /D.
>"!DK_EXEDIR!\.dk0-touch" ECHO OK
DEL /Q "!DK_EXEDIR!\.dk0-touch" >NUL 2>&1
COPY /B "%DK_SIGNIFY%"+,, "%DK_SIGNIFY%" >NUL 2>&1
FORFILES /P "%DK_DATA_HOME%" /M dk0exe-* /D -30 /C "cmd /c if @isdir==TRUE rd /s /q @path" >NUL 2>&1
FORFILES /P "%DK_VDIR%" /M mlfront-signify-*.exe /D -30 /C "cmd /c del /q @path" >NUL 2>&1

REM 7. Run it (same contract as the POSIX wrapper). dk0 --self-update rewrites the
REM    dk.u actual_version line itself (dk0.exe edits dk.u safely; this launcher
REM    never does file surgery on dk.u).
SET "DKCODER_ARG0=dk0"
IF "%DK_SELFUPDATE%"=="1" (
    REM dk0.exe repins the dk.u actual_version line to the resolved (latest) version.
    "!DK_EXE!" -isystem "%DK_PROJECT_DIR%etc\dk\i" self-update !DK_VER!
) ELSE (
    "!DK_EXE!" -isystem "%DK_PROJECT_DIR%etc\dk\i" %*
)
EXIT /B %ERRORLEVEL%

REM ================= subroutines =================

REM :fetch URL DEST  -- download without a checksum (the manifest is verified by
REM signature). curl first, then BITSADMIN, then PowerShell -- so no PowerShell
REM dependency on machines that ship curl (Windows 10 1803+).
:fetch
IF EXIST "%SystemRoot%\System32\curl.exe" (
    "%SystemRoot%\System32\curl.exe" -fsSL "%~1" -o "%~2" && EXIT /B 0
)
BITSADMIN /TRANSFER dk0fetch /DOWNLOAD /PRIORITY FOREGROUND "%~1" "%~2" >NUL 2>&1 && EXIT /B 0
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri '%~1' -OutFile '%~2'" >NUL 2>&1 && EXIT /B 0
ECHO dk0: could not download %~1 1>&2
EXIT /B 1

REM :sha256 FILE OUTVAR  -- set OUTVAR to the lowercased SHA-256 of FILE.
:sha256
SET "%~2="
FOR /F "usebackq tokens=* delims=" %%H IN (`certutil -hashfile "%~1" SHA256 ^| findstr /R "^[0-9a-fA-F][0-9a-fA-F]*$"`) DO (
    IF NOT DEFINED %~2 SET "%~2=%%H"
)
IF DEFINED %~2 SET "%~2=!%~2: =!"
EXIT /B 0

REM :getmanifest VER  -- fetch manifest[-VER].txt + .sig into %DK_VDIR%, signify-verify.
:getmanifest
IF "%~1"=="" (SET "DK_MURL=%DK_BASE_URL%/manifest.txt") ELSE (SET "DK_MURL=%DK_BASE_URL%/manifest-%~1.txt")
CALL :fetch "!DK_MURL!" "%DK_VDIR%\manifest"
IF !ERRORLEVEL! NEQ 0 EXIT /B 1
CALL :fetch "!DK_MURL!.sig" "%DK_VDIR%\manifest.sig"
IF !ERRORLEVEL! NEQ 0 EXIT /B 1
"%DK_SIGNIFY%" -V -q -p "%DK_VDIR%\dk0.pub" -m "%DK_VDIR%\manifest" -x "%DK_VDIR%\manifest.sig"
IF !ERRORLEVEL! NEQ 0 (ECHO dk0: manifest signature INVALID for !DK_MURL! -- refusing to continue 1>&2 & EXIT /B 1)
EXIT /B 0

REM :mval KEY OUTVAR  -- read key=value from the verified %DK_VDIR%\manifest.
:mval
SET "%~2="
FOR /F "usebackq tokens=1,* delims==" %%A IN ("%DK_VDIR%\manifest") DO (
    IF /I "%%A"=="%~1" SET "%~2=%%B"
)
EXIT /B 0

REM :readpin  -- set DK_PIN to the version between the quotes on the dk.u
REM actual_version line. The caret-escaped FOR options are how batch uses a
REM double-quote as a delimiter (a quoted "delims=^"" options string does not work).
:readpin
FOR /F usebackq^ tokens^=2^ delims^=^" %%V IN (`findstr /L /C:"actual_version" "%DK_PROJECT_DIR%dk.u"`) DO SET "DK_PIN=%%V"
EXIT /B 0
