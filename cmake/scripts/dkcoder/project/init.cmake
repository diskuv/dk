##########################################################################
# File: dkcoder\cmake\scripts\dksdk\coder\run.cmake                       #
#                                                                        #
# Copyright 2024 Diskuv, Inc.                                            #
#                                                                        #
# Licensed under the Open Software License version 3.0                   #
# (the "License"); you may not use this file except in compliance        #
# with the License. You may obtain a copy of the License at              #
#                                                                        #
#     https://opensource.org/license/osl-3-0-php/                        #
#                                                                        #
##########################################################################

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE;COMMAND" "")

    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()
    if(NOT ARG_COMMAND)
        set(ARG_COMMAND dkcoder.project.init)
    endif()

    set(msg [[usage: ./dk @ARG_COMMAND@ <options>

Installs ./dk and ./dk.cmd in the current directory.

If there is a .git/ directory and no .gitattributes then a
default .gitattributes configuration file is added.

And if there is a .git/ directory the .gitattributes, ./dk
and ./dk.cmd are added to Git.

Arguments
=========

HELP
  Print the Getting Started message.

MOREHELP
  Print this help message.

QUIET
  Print fewer messages.
]])
    string(CONFIGURE "${msg}" msg @ONLY)
    message(${ARG_MODE} ${msg})
endfunction()

function(getting_started_help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE;COMMAND" "")

    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()
    if(NOT ARG_COMMAND)
        set(ARG_COMMAND dkcoder.project.init)
    endif()

    set(msg [[usage: ./dk @ARG_COMMAND@ <options>

Getting Started
===============

1. Open a shell and cd to your home directory.

   On Linux or Mac:

     cd

   On Windows use **PowerShell** not Command Prompt:

     cd "$env:USERPROFILE"

2. Create an "ok" directory for your first DkCoder source code.

   For example, use the following commands:

     mkdir ok
     cd ok

3. Enable local development for your code.

   You will install "wrappers" which are scripts for Windows, Linux and macOS
   that invokes a version of DkCoder, downloading it beforehand if necessary.
   As a result, you and other developers can get up and running with a DkCoder
   project quickly.

   You will also create a local Git repository to keep track of your scripts.

   Use the following commands:

     git clone https://github.com/diskuv/dk.git
     dk/dk @ARG_COMMAND@

   Experienced user? Get more help with:

     dk/dk @ARG_COMMAND@ MOREHELP
]])
    string(CONFIGURE "${msg}" msg @ONLY)
    message(${ARG_MODE} ${msg})
endfunction()

macro(dkcoder_project_init)
    # Default LOGLEVEL
    if(NOT ARG_LOGLEVEL)
        set(ARG_LOGLEVEL "NOTICE")
    endif()

    # Find the dk/dk.cmd command to run
    if(CMAKE_HOST_WIN32)
        set(dk_cmd "${CMAKE_SOURCE_DIR}/dk.cmd")
    else()
        set(dk_cmd "${CMAKE_SOURCE_DIR}/dk")
    endif()

    set(init_OPTIONS)
    # all DkStd_Std commands must run in old versions of DkCoder. Confer dkcoder/src/DkStd_Std/README.md
    #   SYNC: src/DkStd_Std/README.md, .vscode/settings.json, cmake/scripts/dkcoder/project/init.cmake
    set(dk_run DkRun_V2_2.RunAway)
    if(NOT ARG_QUIET)
        string(APPEND init_OPTIONS " -verbose")
    endif()

    set(init_ARGS)
    set(postinstall_WIN32)
    set(postinstall_UNIX)
    if(NOT ARG_NOSRC)
        string(APPEND init_ARGS " MyScripts_Std.StartHere=")
        set(postinstall_WIN32 "ECHO suggestion: Run with `./dk MyScripts_Std.StartHere`\nECHO suggestion: Open project in VSCode and install the recommended plugins.")
        set(postinstall_UNIX  "echo 'suggestion: Run with `./dk MyScripts_Std.StartHere`'\necho 'suggestion: Open project in VSCode and install the recommended plugins.'")
    endif()

    # Run the command as a post script. Why?
    # 1. We don't want to run ./dk inside of ./dk. Not sure how the environment variables (etc.) interact.
    # 2. Makes it possible for DkStd_Std.Project.Init to erase the dkcoder/ project directory on Windows
    #    (no erasing the currently running dk.cmd script or executable that is in use).
    if(CMAKE_HOST_WIN32)
        cmake_path(NATIVE_PATH dk_cmd dk_cmd_NATIVE)
        cmake_path(NATIVE_PATH DKCODER_PWD DKCODER_PWD_NATIVE)
        cmake_path(NATIVE_PATH CMAKE_SOURCE_DIR CMAKE_SOURCE_DIR_NATIVE)
        cmake_path(NATIVE_PATH CMAKE_CURRENT_BINARY_DIR CMAKE_CURRENT_BINARY_DIR_NATIVE)
        file(CONFIGURE OUTPUT "${DKCODER_POST_SCRIPT}" CONTENT [[
CD /D "@CMAKE_CURRENT_BINARY_DIR_NATIVE@"

REM 1. We copy the dk.cmd to the new project directory
CALL "@dk_cmd_NATIVE@" @dk_run@ --generator dune --you-dir "@CMAKE_SOURCE_DIR_NATIVE@\src" -- DkStd_Std.Project.Init -windows-boot @init_OPTIONS@ "@DKCODER_PWD_NATIVE@" "@CMAKE_SOURCE_DIR_NATIVE@"
IF %ERRORLEVEL% NEQ 0 EXIT /B %ERRORLEVEL%

REM 2. We do the dkcoder/ project deletion and src/ construction from the new project directory.
REM The deletion will not erase the running dk.cmd script and cause 'The system cannot find the path specified.'
CALL "@DKCODER_PWD_NATIVE@\dk.cmd" @dk_run@ --generator dune --you-dir "@CMAKE_SOURCE_DIR_NATIVE@\src" -- DkStd_Std.Project.Init -delete-dkcoder-after @init_OPTIONS@ "@DKCODER_PWD_NATIVE@" "@CMAKE_SOURCE_DIR_NATIVE@" @init_ARGS@
IF %ERRORLEVEL% NEQ 0 EXIT /B %ERRORLEVEL%

ECHO dkcoder: project installed.
@postinstall_WIN32@

REM The parent dk.cmd script was deleted, and if it continued then
REM we would get 'The system cannot find the path specified.' so exit
REM the CMD.EXE interpreter right now (not just the current /B batch script).
EXIT 0
]]
            @ONLY NEWLINE_STYLE DOS)
    else()
        file(CONFIGURE OUTPUT "${DKCODER_POST_SCRIPT}" CONTENT [[#!/bin/sh
set -euf
cd '@CMAKE_CURRENT_BINARY_DIR@'
'@dk_cmd@' @dk_run@ --generator dune --you-dir '@CMAKE_SOURCE_DIR@/src' -- DkStd_Std.Project.Init -delete-dkcoder-after @init_OPTIONS@ '@DKCODER_PWD@' '@CMAKE_SOURCE_DIR@' @init_ARGS@
echo "dkcoder: project installed."
@postinstall_UNIX@
]]
            @ONLY NEWLINE_STYLE UNIX)
    endif()
endmacro()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues HELP MOREHELP QUIET NOSRC)
    set(singleValues LOGLEVEL)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    cmake_path(COMPARE "${DKCODER_PWD}" EQUAL "${CMAKE_SOURCE_DIR}" in_dkcoder_project)
    if(in_dkcoder_project)
        set(help_ARGS)
    else()
        set(help_ARGS COMMAND user.dkcoder.project.init)
    endif()

    if(ARG_HELP)
        getting_started_help(MODE NOTICE ${help_ARGS})
        return()
    endif()
    if(ARG_MOREHELP)
        help(MODE NOTICE ${help_ARGS})
        return()
    endif()

    if(in_dkcoder_project)
        getting_started_help(MODE NOTICE ${help_ARGS})
        message(FATAL_ERROR "You must run dkcoder/dk from the directory you want to create the project.")
        return()
    endif()

    # Get other helper functions (which overrides help())

    dkcoder_project_init()
endfunction()
