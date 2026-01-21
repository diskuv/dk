@ECHO OFF
SETLOCAL

SET CODEGEN_DIR=%1
SET OUT_DIR=%2

IF "%CODEGEN_DIR%"=="" EXIT /B 1
IF "%OUT_DIR%"=="" EXIT /B 1

IF NOT EXIST "%OUT_DIR%\bin" MKDIR "%OUT_DIR%\bin"
IF NOT EXIST "%OUT_DIR%\lib" MKDIR "%OUT_DIR%\lib"

IF EXIST "%CODEGEN_DIR%\bin\clang.exe" COPY /Y "%CODEGEN_DIR%\bin\clang.exe" "%OUT_DIR%\bin\" >NUL
IF EXIST "%CODEGEN_DIR%\bin\clang++.exe" COPY /Y "%CODEGEN_DIR%\bin\clang++.exe" "%OUT_DIR%\bin\" >NUL
IF EXIST "%CODEGEN_DIR%\bin\clang-cl.exe" COPY /Y "%CODEGEN_DIR%\bin\clang-cl.exe" "%OUT_DIR%\bin\" >NUL

IF EXIST "%CODEGEN_DIR%\bin\*.dll" COPY /Y "%CODEGEN_DIR%\bin\*.dll" "%OUT_DIR%\bin\" >NUL

IF EXIST "%CODEGEN_DIR%\lib\clang" (
  XCOPY /E /I /Y "%CODEGEN_DIR%\lib\clang" "%OUT_DIR%\lib\clang" >NUL
)

IF EXIST "%CODEGEN_DIR%\lib\libclang*.dll" COPY /Y "%CODEGEN_DIR%\lib\libclang*.dll" "%OUT_DIR%\bin\" >NUL
IF EXIST "%CODEGEN_DIR%\lib\libLLVM*.dll" COPY /Y "%CODEGEN_DIR%\lib\libLLVM*.dll" "%OUT_DIR%\bin\" >NUL

EXIT /B 0
