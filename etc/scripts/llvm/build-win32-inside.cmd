@ECHO OFF

SETLOCAL ENABLEDELAYEDEXPANSION

REM Some constants copied from dk.cmd, plus more
SET DK_7Z_MAJVER=23
SET DK_7Z_MINVER=01
SET DK_7Z_DOTVER=%DK_7Z_MAJVER%.%DK_7Z_MINVER%
SET DK_7Z_VER=%DK_7Z_MAJVER%%DK_7Z_MINVER%
SET DK_CKSUM_7ZR=72c98287b2e8f85ea7bb87834b6ce1ce7ce7f41a8c97a81b307d4d4bf900922b
SET DK_CKSUM_7ZEXE=9b6682255bed2e415bfa2ef75e7e0888158d1aaf79370defaa2e2a5f2b003a59
SET DK_CKSUM_LLVM_PROJECT=324d483ff0b714c8ce7819a1b679dd9e4706cf91c6caf7336dc4ac0c1d3bf636
SET DK_CKSUM_LIBXML2=353f3c83535d4224a4e5f1e88c90b5d4563ea8fec11f6407df640fd28fc8b8c6
SET DK_QUIET=0

ECHO.=============
ECHO.build-win32-inside.cmd
ECHO.=============
ECHO..
ECHO.------
ECHO.Inputs
ECHO.------
ECHO.DKML_COMPILE_CM_CONFIG=%DKML_COMPILE_CM_CONFIG%
ECHO.DKML_COMPILE_CM_MSVC_VCVARS_VER=%DKML_COMPILE_CM_MSVC_VCVARS_VER%
ECHO.LLVM_TARGETS_TO_BUILD=%LLVM_TARGETS_TO_BUILD%
ECHO..
ECHO.------
ECHO.Matrix
ECHO.------
ECHO.DKML_TARGET_ABI=%DKML_TARGET_ABI%
ECHO..

IF "%CMAKE_EXE%"=="" (
	ECHO.
	ECHO.CMAKE_EXE is required
	ECHO.
	EXIT /B 3
)
IF NOT EXIST "%CMAKE_EXE%" (
	ECHO.
	ECHO.CMAKE_EXE was not found at "%CMAKE_EXE%"
	ECHO.
	EXIT /B 3
)

IF "%DKML_TARGET_ABI%" == "windows_x86_64" (
	SET LLVMARCH=win64
	SET VAL_CMAKE_GENERATOR_PLATFORM=x64
	SET DK_CKSUM_LLVM=ad63bea52fd89f62a4f30ed87895a7d38b087f604564fe50c5cf226cee4274ff
) ELSE IF "%DKML_TARGET_ABI%" == "windows_x86" (
	SET LLVMARCH=win32
	SET VAL_CMAKE_GENERATOR_PLATFORM=Win32
	SET DK_CKSUM_LLVM=9bab022d175ff27e35db517b71d3e428027d75ffff0d0195ccc9f20ce5a20d4f
) ELSE (
	ECHO.
	ECHO.Unrecognized Windows target ABI. DKML_TARGET_ABI=%DKML_TARGET_ABI%
	ECHO.
	exit /b 1
)

IF NOT "%DKML_COMPILE_CM_MSVC_VCVARS_VER%" == "" (
	SET CMAKE_GENERATOR_TOOLSET=version=%DKML_COMPILE_CM_MSVC_VCVARS_VER%
	REM It would be nice if the Visual Studio installation can be auto-detected,
	REM but must set when CMAKE_GENERATOR_TOOLSET is used because:
	REM > Warning: Environment variable CMAKE_GENERATOR_TOOLSET will be ignored, because CMAKE_GENERATOR is not set.
	SET CMAKE_GENERATOR=Visual Studio 17 2022
)

IF "%DKML_COMPILE_CM_CONFIG%" == "" (
	SET CMAKE_CONFIGURATION_TYPES=Release
) ELSE (
	SET CMAKE_CONFIGURATION_TYPES=%DKML_COMPILE_CM_CONFIG%
)

IF "%LLVM_TARGETS_TO_BUILD%" == "" (
	SET VAL_LLVM_TARGETS_TO_BUILD=
) ELSE (
	REM Replace comma-separated with semicolon-separated
	SET VAL_LLVM_TARGETS_TO_BUILD=
	SET VAL_LLVM_TARGETS_TO_BUILD=-D LLVM_TARGETS_TO_BUILD=%LLVM_TARGETS_TO_BUILD:,=;%
)

REM uv.exe
REM Confer: https://docs.astral.sh/uv/concepts/tools/#the-bin-directory
IF "%UV_TOOL_BIN_DIR%" == "" (
	IF "%XDG_BIN_HOME%" == "" (
		IF "%XDG_DATA_HOME%" == "" (
			SET "Path=%USERPROFILE%\.local\bin;%Path%"
		) ELSE (
			SET "Path=%XDG_DATA_HOME%\..\bin;%Path%"
		)
	) ELSE (
		SET "Path=%XDG_BIN_HOME%;%Path%"
	)
) ELSE (
	SET "Path=%UV_TOOL_BIN_DIR%;%Path%"
)
ECHO.uv location
where.exe uv
if %ERRORLEVEL% neq 0 (
	ECHO.
	ECHO.uv was not found. uv is required to install Python 3
	ECHO.
	exit /b 1
)

@ECHO ON

REM Optional: pre-seeded asset locations
IF NOT "%LLVM_INSTALLER_EXE%" == "" (
	IF EXIST "%LLVM_INSTALLER_EXE%" (
		COPY /Y "%LLVM_INSTALLER_EXE%" "%TEMP%\LLVM.exe" >NUL
		SET LLVM_INSTALLER_PRESEEDED=1
	)
)
IF NOT "%LLVM_PROJECT_TAR_XZ%" == "" (
	IF EXIST "%LLVM_PROJECT_TAR_XZ%" (
		COPY /Y "%LLVM_PROJECT_TAR_XZ%" "%TEMP%\llvm-project.src.tar.xz" >NUL
		SET LLVM_PROJECT_PRESEEDED=1
	)
)
IF NOT "%LIBXML2_TAR_XZ%" == "" (
	IF EXIST "%LIBXML2_TAR_XZ%" (
		COPY /Y "%LIBXML2_TAR_XZ%" "%TEMP%\libxml2-2.14.2.tar.xz" >NUL
		SET LIBXML2_PRESEEDED=1
	)
)

REM Download 7z. Adapted from dk.cmd
IF NOT EXIST "build\7z%DK_7Z_VER%\7z.exe" (
	REM Download 7zr.exe (and then 7z.exe) to do unzipping.
	REM     Q: Can't we just download 7z.exe to do unzipping?
	REM     Ans: That needs DLLs so we would need two downloads regardless.
	REM          7zr.exe can do un7z of 7z*.exe which is 2 downloads as well.
	REM          But it is easier to audit this using 7zr.exe and 7z*.exe software
	REM          from public download sites.
	REM     Q: Why redirect stdout to NUL?
	REM     Ans: It reduces the verbosity and errors will still be printed.
	REM          Confer: https://sourceforge.net/p/sevenzip/feature-requests/1623/#0554
	IF %DK_QUIET% EQU 0 ECHO.7z prerequisite:
	CALL :downloadFile ^
		7zr ^
		"7zr %DK_7Z_DOTVER%" ^
		"https://github.com/ip7z/7zip/releases/download/%DK_7Z_DOTVER%/7zr.exe" ^
		7zr-%DK_7Z_DOTVER%.exe ^
		%DK_CKSUM_7ZR%
	REM On error the error message was already displayed.
	IF !ERRORLEVEL! NEQ 0 EXIT /B !ERRORLEVEL!

	REM Download 7z.exe full version to do unzipping of LLVM installer.
	CALL :downloadFile ^
		7zexe ^
		"7z%DK_7Z_VER%.exe" ^
		"https://github.com/ip7z/7zip/releases/download/%DK_7Z_DOTVER%/7z%DK_7Z_VER%.exe" ^
		7z%DK_7Z_VER%.exe ^
		%DK_CKSUM_7ZEXE%
	REM On error the error message was already displayed.
	IF !ERRORLEVEL! NEQ 0 EXIT /B !ERRORLEVEL!

	REM Extract 7z*.exe installer
	IF EXIST "build\7z%DK_7Z_VER%" (
		RMDIR /S /Q "build\7z%DK_7Z_VER%"
	)
	"%TEMP%\7zr-%DK_7Z_DOTVER%.exe" x -o"build\7z%DK_7Z_VER%" "%TEMP%\7z%DK_7Z_VER%.exe" >NUL
	IF !ERRORLEVEL! NEQ 0 (
		ECHO.
		ECHO.Could not extract 7z%DK_7Z_VER%.exe installer.
		ECHO.
		EXIT /B 3
	)
)

REM Install codegen to staging area codegen\
IF NOT "%CPKG_CODEGEN%" == "DISABLE" (
	IF NOT EXIST build\llvm-installer\bin\lld.exe (
		REM Download LLVM installer
		IF "%LLVM_INSTALLER_PRESEEDED%" == "1" (
			ECHO.  Using pre-seeded LLVM installer at %TEMP%\LLVM.exe
		) ELSE (
			CALL :downloadFile ^
				llvm ^
				"LLVM-19.1.3 %LLVMARCH% installer" ^
				"https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.3/LLVM-19.1.3-%LLVMARCH%.exe" ^
				LLVM.exe ^
				%DK_CKSUM_LLVM%
		)
		REM On error the error message was already displayed.
		IF !ERRORLEVEL! NEQ 0 EXIT /B !ERRORLEVEL!

		IF %DK_QUIET% EQU 0 ECHO.  Extracting binaries and libraries from LLVM installer
		MKDIR build\llvm-installer
		"build\7z%DK_7Z_VER%\7z" x -obuild\llvm-installer "%TEMP%\LLVM.exe"
	)

	REM 	libxml2-2.14.2/result/xmlid/id_tst4.xml.err is last file in tarball
	IF NOT EXIST build\libxml2-2.14.2\result\xmlid\id_tst4.xml.err (
		REM Download llvm-project
		IF "%LIBXML2_PRESEEDED%" == "1" (
			ECHO.  Using pre-seeded libxml2 tarball at %TEMP%\libxml2-2.14.2.tar.xz
		) ELSE (
			CALL :downloadFile ^
				libxml2 ^
				"libxml2-2.14.2" ^
				"https://download.gnome.org/sources/libxml2/2.14/libxml2-2.14.2.tar.xz" ^
				libxml2-2.14.2.tar.xz ^
				%DK_CKSUM_LIBXML2%
		)
		REM On error the error message was already displayed.
		IF !ERRORLEVEL! NEQ 0 EXIT /B !ERRORLEVEL!

		IF %DK_QUIET% EQU 0 ECHO.  Extracting libxml2 source to build\libxml2-2.14.2
		MKDIR build\libxml2-tar
		"build\7z%DK_7Z_VER%\7z" x -y -obuild\libxml2-tar "%TEMP%\libxml2-2.14.2.tar.xz"
		"build\7z%DK_7Z_VER%\7z" x -y -obuild "build\libxml2-tar\libxml2-2.14.2.tar"
	)

	REM 	llvm-project-19.1.3.src/utils/bazel/vulkan_sdk.bzl is last file in tarball
	IF NOT EXIST build\llvm-project-19.1.3.src\utils\bazel\vulkan_sdk.bzl (
		REM Download llvm-project
		IF "%LLVM_PROJECT_PRESEEDED%" == "1" (
			ECHO.  Using pre-seeded LLVM source tarball at %TEMP%\llvm-project.src.tar.xz
		) ELSE (
			CALL :downloadFile ^
				llvm-project ^
				"llvm-project-19.1.3" ^
				"https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.3/llvm-project-19.1.3.src.tar.xz" ^
				llvm-project.src.tar.xz ^
				%DK_CKSUM_LLVM_PROJECT%
		)
		REM On error the error message was already displayed.
		IF !ERRORLEVEL! NEQ 0 EXIT /B !ERRORLEVEL!

		IF %DK_QUIET% EQU 0 ECHO.  Extracting LLVM sources to build\llvm-project-19.1.3.src
		MKDIR build\llvm-project-tar
		"build\7z%DK_7Z_VER%\7z" x -y -obuild\llvm-project-tar "%TEMP%\llvm-project.src.tar.xz"
		"build\7z%DK_7Z_VER%\7z" x -y -obuild "build\llvm-project-tar\llvm-project.src.tar"
	)

	ECHO.Configuring libxml2...
	REM Recommended options at https://gitlab.gnome.org/GNOME/libxml2#cmake-mainly-for-windows
	REM Except DLIBXML2_WITH_ZLIB=OFF since we don't need to read/write compressed xml files.
	"%CMAKE_EXE%" ^
		-S build\libxml2-2.14.2 ^
		-B build\libxml2 ^
		-DCMAKE_GENERATOR_PLATFORM=%VAL_CMAKE_GENERATOR_PLATFORM% ^
		-DBUILD_SHARED_LIBS=OFF ^
		-DLIBXML2_WITH_ICONV=OFF ^
		-DLIBXML2_WITH_PYTHON=OFF ^
		-DLIBXML2_WITH_ZLIB=OFF ^
		-DCMAKE_INSTALL_PREFIX=%CD%\build\libxml2-install
	IF !ERRORLEVEL! NEQ 0 (
		ECHO.
		ECHO.Could not configure libxml2.
		ECHO.
		EXIT /B 3
	)

	ECHO.Building libxml2...
	"%CMAKE_EXE%" --build build\libxml2 --config %CMAKE_CONFIGURATION_TYPES%
	IF !ERRORLEVEL! NEQ 0 (
		ECHO.
		ECHO.Could not build libxml2.
		ECHO.
		EXIT /B 3
	)

	ECHO.Installing libxml2...
	"%CMAKE_EXE%" --install build\libxml2 --config %CMAKE_CONFIGURATION_TYPES%
	IF !ERRORLEVEL! NEQ 0 (
		ECHO.
		ECHO.Could not install libxml2.
		ECHO.
		EXIT /B 3
	)

	REM Install Python 3 for LLVM install
	uv.exe python install 3.12

	REM See src/build-llvm.sh to explain most of the variables.
	REM No projects, no runtimes. Just LLVM
	REM No Ninja. Let cmake auto-detect Visual Studio: -G Ninja -DCMAKE_MAKE_PROGRAM=.ci\ninja\bin\ninja ^
	REM CMAKE_FIND_PACKAGE_PREFER_CONFIG=true so we can supply our own cmake configs like libxml2 for Alpine
	ECHO.Configuring LLVM Core...
	uv.exe run --python 3.12 ^
		"%CMAKE_EXE%" ^
		-S build\llvm-project-19.1.3.src\llvm ^
		-B build\llvm-core ^
		-DCMAKE_GENERATOR_PLATFORM=%VAL_CMAKE_GENERATOR_PLATFORM% ^
		-DCMAKE_BUILD_TYPE=Release ^
		-DCMAKE_FIND_LIBRARY_SUFFIXES=.lib ^
		-DLLVM_ENABLE_PROJECTS= ^
		-DLLVM_ENABLE_RUNTIMES= ^
		-DLLVM_ENABLE_LIBXML2=FORCE_ON ^
		%VAL_LLVM_TARGETS_TO_BUILD% ^
		-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=true ^
		-DCMAKE_INSTALL_PREFIX=%CD%\build\llvm-install --debug-find-pkg=zstd
	REM --trace-expand --trace-redirect=ci\win32.log
	IF !ERRORLEVEL! NEQ 0 (
		ECHO.
		ECHO.Could not configure LLVM Core.
		ECHO.
		EXIT /B 3
	)

	ECHO.-----------
	ECHO.Diagnostics
	ECHO.-----------
	powershell.exe -NoProfile -ExecutionPolicy Bypass ci\diagnostics.ps1
	ECHO..

	ECHO.Building LLVM Core...
	"%CMAKE_EXE%" --build build\llvm-core --config %CMAKE_CONFIGURATION_TYPES%
	IF !ERRORLEVEL! NEQ 0 (
		ECHO.
		ECHO.Could not build LLVM Core.
		ECHO.
		EXIT /B 3
	)

	ECHO.Installing LLVM Core...
	"%CMAKE_EXE%" --install build\llvm-core --config %CMAKE_CONFIGURATION_TYPES%
	IF !ERRORLEVEL! NEQ 0 (
		ECHO.
		ECHO.Could not install LLVM Core.
		ECHO.
		EXIT /B 3
	)

	ECHO.Reorganizing LLVM installer...
	IF EXIST "codegen\%DKML_TARGET_ABI%" (
		RMDIR /S /Q "codegen\%DKML_TARGET_ABI%"
	)
	REM headers (from source build)
	XCOPY /e /i build\llvm-install\include\* codegen\%DKML_TARGET_ABI%\include
	REM libraries (from source build)
	MKDIR codegen\%DKML_TARGET_ABI%\lib\
	XCOPY /e /i build\llvm-install\lib\* codegen\%DKML_TARGET_ABI%\lib
	REM lld.exe  (from official release) (all lld-link.exe, etc. are just copies of lld.exe)
	MKDIR codegen\%DKML_TARGET_ABI%\tools\
	XCOPY build\llvm-installer\bin\lld.exe codegen\%DKML_TARGET_ABI%\tools\
	REM clang tools and runtime DLLs
	MKDIR codegen\%DKML_TARGET_ABI%\bin\
	IF EXIST build\llvm-installer\bin\clang.exe XCOPY build\llvm-installer\bin\clang.exe codegen\%DKML_TARGET_ABI%\bin\
	IF EXIST build\llvm-installer\bin\clang++.exe XCOPY build\llvm-installer\bin\clang++.exe codegen\%DKML_TARGET_ABI%\bin\
	IF EXIST build\llvm-installer\bin\clang-cl.exe XCOPY build\llvm-installer\bin\clang-cl.exe codegen\%DKML_TARGET_ABI%\bin\
	IF EXIST build\llvm-installer\bin\*.dll XCOPY build\llvm-installer\bin\*.dll codegen\%DKML_TARGET_ABI%\bin\
)

EXIT /B 0

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
