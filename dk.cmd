@ECHO OFF
REM ##########################################################################
REM # File: dkcoder\dk.cmd                                                   #
REM #                                                                        #
REM # Copyright 2023 Diskuv, Inc.                                            #
REM #                                                                        #
REM # Licensed under the Open Software License version 3.0                   #
REM # (the "License"); you may not use this file except in compliance        #
REM # with the License. You may obtain a copy of the License at              #
REM #                                                                        #
REM #     https://opensource.org/license/osl-3-0-php/                        #
REM #                                                                        #
REM ##########################################################################

REM Recommendation: Place this file in source control.

REM The canonical way to run this script is: ./dk
REM That works in Powershell on Windows, and in Unix. Copy-and-paste works!

SETLOCAL ENABLEDELAYEDEXPANSION

REM Coding guidelines
REM 1. Microsoft way of getting around PowerShell permissions:
REM    https://github.com/microsoft/vcpkg/blob/71422c627264daedcbcd46f01f1ed0dcd8460f1b/bootstrap-vcpkg.bat
REM 2. Hygiene: Capitalize keywords, variables, commands, operators and options
REM 3. Detect errors with `%ERRORLEVEL% EQU` (etc). https://ss64.com/nt/errorlevel.html
REM 3. In nested blocks like `IF EXIST xxx ( ... )` use delayed !ERRORLEVEL!. https://stackoverflow.com/a/4368104/21513816
REM 4. Use functions ("subroutines"):
REM    https://learn.openwaterfoundation.org/owf-learn-windows-shell/best-practices/best-practices/#use-functions-to-create-reusable-blocks-of-code

REM Invoke-WebRequest guidelines
REM 1. Use $ProgressPreference = 'SilentlyContinue' always. Terrible slowdown w/o it.
REM    https://stackoverflow.com/questions/28682642

SET DK_7Z_MAJVER=23
SET DK_7Z_MINVER=01
SET DK_7Z_DOTVER=%DK_7Z_MAJVER%.%DK_7Z_MINVER%
SET DK_7Z_VER=%DK_7Z_MAJVER%%DK_7Z_MINVER%
SET DK_CMAKE_VER=3.25.3
SET DK_NINJA_VER=1.12.1
SET DK_BUILD_TYPE=Release
SET DK_PROJ_DIR=%~dp0
SET DK_PWD=%CD%

SET DK_CKSUM_7ZR=72c98287b2e8f85ea7bb87834b6ce1ce7ce7f41a8c97a81b307d4d4bf900922b
SET DK_CKSUM_7ZEXTRA=db3a1cbe57a26fac81b65c6a2d23feaecdeede3e4c1fe8fb93a7b91d72d1094c
SET DK_CKSUM_CMAKE=d129425d569140b729210f3383c246dec19c4183f7d0afae1837044942da3b4b
SET DK_CKSUM_NINJA=f550fec705b6d6ff58f2db3c374c2277a37691678d6aba463adcbb129108467a

REM --------- Quiet and Away Detection ---------
REM Enabled? If suffix of the first argument is "Quiet" or "Away"
REM Example: DkRun_Project.RunQuiet
REM Example: DkRun_Project.RunAway

SET DK_ARG1=%1
SET DK_QUIET=0
SET DK_AWAY=0
IF "%DK_ARG1:~-5%" == "Quiet" SET DK_QUIET=1
IF "%DK_ARG1:~-4%" == "Away" SET DK_AWAY=1
SET DK_ARG1=

REM --------- Data Home ---------

IF "%DKCODER_DATA_HOME%" == "" (
    SET DK_DATA_HOME=%LOCALAPPDATA%\Programs\DkCoder
) ELSE (
    SET DK_DATA_HOME=%DKCODER_DATA_HOME%
)

REM -------------- CMAKE --------------

REM Download cmake-xxx.zip
REM     Why not CMAKE.MSI? Because we don't want to mess up the user's existing
REM     installation. `./dk` is meant to be isolated.
IF NOT EXIST "%DK_DATA_HOME%\cmake-%DK_CMAKE_VER%-windows-x86_64\bin\cmake.exe" (
    IF %DK_QUIET% EQU 0 ECHO.cmake prerequisite:
    CALL :downloadFile ^
        cmake ^
        "CMake %DK_CMAKE_VER%" ^
        "https://github.com/Kitware/CMake/releases/download/v%DK_CMAKE_VER%/cmake-%DK_CMAKE_VER%-windows-x86_64.zip" ^
        cmake-%DK_CMAKE_VER%-windows-x86_64.zip ^
        %DK_CKSUM_CMAKE%
    REM On error the error message was already displayed.
    IF !ERRORLEVEL! NEQ 0 EXIT /B !ERRORLEVEL!
)

REM Unzip cmake-xxx.zip
IF NOT EXIST "%DK_DATA_HOME%\cmake-%DK_CMAKE_VER%-windows-x86_64\bin\cmake.exe" (
    REM Remove any former partially completed extraction
    IF EXIST "%DK_DATA_HOME%\cmake-%DK_CMAKE_VER%-windows-x86_64" (
        RMDIR /S /Q %DK_DATA_HOME%\cmake-%DK_CMAKE_VER%-windows-x86_64
    )

    CALL :unzipFile ^
        "CMake %DK_CMAKE_VER%" ^
        cmake-%DK_CMAKE_VER%-windows-x86_64.zip ^
        "%DK_DATA_HOME%"
    REM On error the error message was already displayed.
    IF !ERRORLEVEL! NEQ 0 EXIT /B !ERRORLEVEL!
)
SET "DK_CMAKE_EXE=%DK_DATA_HOME%\cmake-%DK_CMAKE_VER%-windows-x86_64\bin\cmake.exe"

REM Validate cmake.exe
"%DK_CMAKE_EXE%" -version >NUL 2>NUL
if %ERRORLEVEL% NEQ 0 (
	ECHO.
	ECHO.%DK_CMAKE_EXE%
	ECHO.is not responding to the -version option. Make sure that
	ECHO.CMake is installed correctly.
	ECHO.
	EXIT /B 1
)

REM -------------- NINJA --------------

REM Download ninja-win.zip
IF NOT EXIST "%DK_DATA_HOME%\ninja-%DK_NINJA_VER%-windows-x86_64\bin\ninja.exe" (
    IF %DK_QUIET% EQU 0 ECHO.ninja prerequisite:
    CALL :downloadFile ^
        ninja ^
        "Ninja %DK_NINJA_VER%" ^
        "https://github.com/ninja-build/ninja/releases/download/v%DK_NINJA_VER%/ninja-win.zip" ^
        ninja-%DK_NINJA_VER%-windows-x86_64.zip ^
        %DK_CKSUM_NINJA%
    REM On error the error message was already displayed.
    IF !ERRORLEVEL! NEQ 0 EXIT /B !ERRORLEVEL!
)

REM Unzip ninja-win.zip
IF NOT EXIST "%DK_DATA_HOME%\ninja-%DK_NINJA_VER%-windows-x86_64\bin\ninja.exe" (
    CALL :unzipFile ^
        "Ninja %DK_NINJA_VER%" ^
        ninja-%DK_NINJA_VER%-windows-x86_64.zip ^
        "%DK_DATA_HOME%\ninja-%DK_NINJA_VER%-windows-x86_64\bin"
    REM On error the error message was already displayed.
    IF !ERRORLEVEL! NEQ 0 EXIT /B !ERRORLEVEL!
)
SET "DK_NINJA_EXE=%DK_DATA_HOME%\ninja-%DK_NINJA_VER%-windows-x86_64\bin\ninja.exe"

REM Validate ninja.exe
"%DK_NINJA_EXE%" --version >NUL 2>NUL
if %ERRORLEVEL% NEQ 0 (
	ECHO.
	ECHO.%DK_NINJA_EXE%
	ECHO.is not responding to the --version option. Make sure that
	ECHO.Ninja is installed correctly.
	ECHO.
	EXIT /B 1
)

REM -------------- DkML PATH ---------
REM We get "git-sh-setup: file not found" in Git for Windows because
REM Command Prompt has the "Path" environment variable, while PowerShell
REM and `with-dkml` use the PATH environment variable. Sadly both
REM can be present in Command Prompt at the same time. Git for Windows
REM (called by FetchContent in CMake) does not comport with what Command
REM Prompt is using. So we let Command Prompt be the source of truth by
REM removing any duplicated PATH twice and resetting to what Command Prompt
REM thinks the PATH is.

SET _DK_PATH=%PATH%
SET PATH=
SET PATH=
SET PATH=%_DK_PATH%
SET _DK_PATH=

REM -------------- Escape command line --------------
REM We pack the entire command line into a double-quoted CMake -D option.
REM So we need to escape the double quotes for the CMake command line parser: " --> \"
SET DK_CMDLINE=%*
IF NOT "%DK_CMDLINE%" == "" SET DK_CMDLINE=%DK_CMDLINE:"=\"%

REM --- Create an 8-byte nonce ---
REM We should rely on Command Prompt not being compromised. Obviously
REM there is nothing we can do if it is compromised. But if it is
REM obviously compromised (ex. someone sets RANDOM) then fail fast.

SET DK_NONCE=%RANDOM%%RANDOM%%RANDOM%%RANDOM%
SET DK_NONCE2=%RANDOM%%RANDOM%%RANDOM%%RANDOM%
IF "%DK_NONCE%" == "%DK_NONCE2%" (
	ECHO.The RANDOM variable was preset rather than random.
	ECHO.This typically means your terminal session has been
	ECHO.compromised by malware. Consult with:
    ECHO.  https://consumer.ftc.gov/articles/how-recognize-remove-avoid-malware
	EXIT /B 1
)
SET DK_NONCE2=

REM -------------- Clear environment -------

SET DK_QUIET=

REM --------------- Console ----------------
REM Until https://github.com/ocaml/ocaml/pull/1408 fixed
REM Confer: https://stackoverflow.com/a/52139735
2>NUL >NUL TIMEOUT /T 0 && (
  REM stdin not redirected or piped
  CHCP 65001 >NUL
  SET DK_TTY=1
) || (
  REM stdin has been redirected or is receiving piped input
  SET DK_TTY=0
)

REM -------------- Run finder --------------

SET DK_WORKDIR=%DK_DATA_HOME%\work

IF %DK_AWAY% EQU 0 CD /D %DK_PROJ_DIR%
"%DK_CMAKE_EXE%" -D CMAKE_GENERATOR=Ninja -D "CMAKE_MAKE_PROGRAM=%DK_NINJA_EXE%" -D "DKCODER_PWD:FILEPATH=%DK_PWD%" -D "DKCODER_DATA_HOME:FILEPATH=%DK_DATA_HOME%" -D "DKCODER_WORKDIR:FILEPATH=%DK_WORKDIR%" -D "DKCODER_NONCE:STRING=%DK_NONCE%" -D "DKCODER_TTY:STRING=%DK_TTY%" -D "DKCODER_CMDLINE:STRING=%DK_CMDLINE%" -P "%DK_PROJ_DIR%__dk.cmake"
IF %ERRORLEVEL% NEQ 0 EXIT /B %ERRORLEVEL%

REM --------------- Execute post-command outside of CMake --------------
REM Sometimes a command wants to own the terminal or the command line arguments.
REM CMake, for example, intercepts the Ctrl-C signal in buggy ways:
REM https://stackoverflow.com/questions/75071180/pass-ctrlc-to-cmake-custom-command-under-vscode

REM     Both DK_WORKDIR and DK_NONCE can be zeroed by the nonce script so capture it
SET DKTEMP_NONCE=%DK_WORKDIR%\%DK_NONCE%.cmd

REM     We don't use nested parentheses or else we'd have to be concerned about delayed
REM     variable expansion. https://stackoverflow.com/questions/24866477/if-call-exit-and-errorlevel-in-a-bat
IF EXIST "%DKTEMP_NONCE%" CALL "%DKTEMP_NONCE%" %*
@ECHO OFF
SET CALLERROR=%ERRORLEVEL%
IF EXIST "%DKTEMP_NONCE%" DEL /Q /F "%DKTEMP_NONCE%"
SET DKTEMP_NONCE=
EXIT /B %CALLERROR%

REM ------ SUBROUTINE [downloadFile]
REM Usage: downloadFile ID "FILE DESCRIPTION" "URL" FILENAME SHA256
REM
REM Procedure:
REM   1. Download from <quoted> URL ARG3 (example: "https://github.com/ninja-build/ninja/releases/download/v%DK_NINJA_VER%/ninja-win.zip")
REM      to the temp directory with filename ARG4 (example: something-x64.zip)
REM   2. SHA-256 integrity check from ARG5 (example: 524b344a1a9a55005eaf868d991e090ab8ce07fa109f1820d40e74642e289abc)
REM
REM Error codes:
REM   1 - Can't download from the URL.
REM   2 - SHA-256 verification failed.

:downloadFile

REM Replace "DESTINATION" double quotes with single quotes
SET DK_DOWNLOAD_URL=%3
SET DK_DOWNLOAD_URL=%DK_DOWNLOAD_URL:"='%

REM 1. Download from <quoted> URL ARG3 (example: "https://github.com/ninja-build/ninja/releases/download/v%DK_NINJA_VER%/ninja-win.zip")
REM    to the temp directory with filename ARG4 (example: something-x64.zip)
IF %DK_QUIET% EQU 0 ECHO.  Downloading %3
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest %DK_DOWNLOAD_URL% -OutFile '%TEMP%\%4'" >NUL
IF %ERRORLEVEL% NEQ 0 (
    REM Fallback to BITSADMIN because sometimes corporate policy does not allow executing PowerShell.
    REM BITSADMIN overwhelms the console so user-friendly to do PowerShell then BITSADMIN.
    IF %DK_QUIET% EQU 0 (
        BITSADMIN /TRANSFER dkcoder-%1 /DOWNLOAD /PRIORITY FOREGROUND ^
            %3 "%TEMP%\%4"
    ) ELSE (
        BITSADMIN /TRANSFER dkcoder-%1 /DOWNLOAD /PRIORITY FOREGROUND ^
            %3 "%TEMP%\%4" >NUL
    )
    REM Short-circuit return with error code from function if can't download.
    IF !ERRORLEVEL! NEQ 0 (
        ECHO.
        ECHO.Could not download %2.
        ECHO.
        EXIT /B 1
    )
)

REM 2. SHA-256 integrity check from ARG5 (example: 524b344a1a9a55005eaf868d991e090ab8ce07fa109f1820d40e74642e289abc)
IF %DK_QUIET% EQU 0 ECHO.  Performing SHA-256 validation of %4
FOR /F "tokens=* usebackq" %%F IN (`certutil -hashfile "%TEMP%\%4" sha256 ^| findstr /v hash`) DO (
    SET "DK_CKSUM_ACTUAL=%%F"
)
IF /I NOT "%DK_CKSUM_ACTUAL%" == "%5" (
    ECHO.
    ECHO.Could not verify the integrity of %2.
    ECHO.Expected SHA-256 %5
    ECHO.but received %DK_CKSUM_ACTUAL%.
    ECHO.Make sure that you can access the Internet, and there is nothing
    ECHO.intercepting network traffic.
    ECHO.
    EXIT /B 2
)

REM Return from [downloadFile]
EXIT /B 0

REM ------ SUBROUTINE [unzipFile]
REM Usage: unzipFile "FILE DESCRIPTION" ZIPFILE "DESTINATION"
REM
REM Procedure:
REM   1. Use PowerShell `Expand-Archive` to expand zipfile ARG2 (example: something-x64.zip)
REM      in the temp directory to the destination directory <quoted> ARG3 (example: %DK_DATA_HOME%\some-folder).
REM   2. Fallback on failure to:
REM   2a. Downloading 7zip
REM   2b. Use 7za to unzip
REM
REM Error codes:
REM   3 - Could not extract the 7z "extra" package.
REM   4 - Could not unzip the file.

:unzipFile

REM Replace "DESTINATION" double quotes with single quotes
SET DK_UNZIP_DEST=%3
SET DK_UNZIP_DEST=%DK_UNZIP_DEST:"='%

REM 1. Use PowerShell `Expand-Archive` to expand zipfile ARG2 (example: something-x64.zip)
REM    in the temp directory to the destination directory ARG3 (example: %DK_DATA_HOME%\some-folder).
IF %DK_QUIET% EQU 0 ECHO.  Unzipping %2
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ProgressPreference = 'SilentlyContinue'; Expand-Archive -Path '%TEMP%\%2' -DestinationPath %DK_UNZIP_DEST% -Force" >NUL
IF %ERRORLEVEL% NEQ 0 (
    REM 2. Fallback on failure to:
    IF %DK_QUIET% EQU 0 ECHO.  PowerShell failed to unzip. Will use 7za instead.

    REM 2a. Downloading 7z
    IF NOT EXIST "%DK_DATA_HOME%\7z%DK_7Z_VER%-extra\7za.exe" (
        REM Download 7zr.exe (and then 7z*-extra.7z) to do unzipping.
        REM     Q: Can't we just download 7za.exe to do unzipping?
        REM     Ans: That needs a dll so we would need two downloads regardless.
        REM          7zr.exe can do un7z of 7z*-extra.7z which is 2 downloads as well.
        REM          I guess we could repackage cmake.zip as cmake.7z and publish to GitLab CI.
        REM          But it is easier to audit this using 7zr.exe and 7z*-extra.7z software
        REM          from public download sites.
        REM     Q: Why redirect stdout to NUL?
        REM     Ans: It reduces the verbosity and errors will still be printed.
        REM          Confer: https://sourceforge.net/p/sevenzip/feature-requests/1623/#0554
        IF %DK_QUIET% EQU 0 ECHO.7za prerequisite:
        CALL :downloadFile ^
            7zr ^
            "7zr %DK_7Z_DOTVER%" ^
            "https://github.com/ip7z/7zip/releases/download/%DK_7Z_DOTVER%/7zr.exe" ^
            7zr-%DK_7Z_DOTVER%.exe ^
            %DK_CKSUM_7ZR%
        REM On error the error message was already displayed.
        IF !ERRORLEVEL! NEQ 0 EXIT /B !ERRORLEVEL!

        REM Download 7z*-extra.7z to do unzipping.
        CALL :downloadFile ^
            7zextra ^
            "7z%DK_7Z_VER%-extra.7z" ^
            "https://github.com/ip7z/7zip/releases/download/%DK_7Z_DOTVER%/7z%DK_7Z_VER%-extra.7z" ^
            7z%DK_7Z_VER%-extra.7z ^
            %DK_CKSUM_7ZEXTRA%
        REM On error the error message was already displayed.
        IF !ERRORLEVEL! NEQ 0 EXIT /B !ERRORLEVEL!

        REM Extract 7z*-extra.7z
        IF EXIST "%DK_DATA_HOME%\7z%DK_7Z_VER%-extra" (
            RMDIR /S /Q "%DK_DATA_HOME%\7z%DK_7Z_VER%-extra"
        )
        "%TEMP%\7zr-%DK_7Z_DOTVER%.exe" x -o"%DK_DATA_HOME%\7z%DK_7Z_VER%-extra" "%TEMP%\7z%DK_7Z_VER%-extra.7z" >NUL
        IF !ERRORLEVEL! NEQ 0 (
            ECHO.
            ECHO.Could not extract 7z%DK_7Z_VER%-extra.7z.
            ECHO.
            EXIT /B 3
        )
    )

    REM 2b. Use 7za to unzip
    IF %DK_QUIET% EQU 0 ECHO.  Redoing unzip of %2 with 7za.
    "%DK_DATA_HOME%\7z%DK_7Z_VER%-extra\7za" x -o%3 "%TEMP%\%2" >NUL

    REM Short-circuit return with error code from function if can't download.
    IF !ERRORLEVEL! NEQ 0 (
        ECHO.
        ECHO.Could not unzip %1.
        ECHO.
        EXIT /B 4
    )
)

REM Return from [unzipFile]
EXIT /B 0
