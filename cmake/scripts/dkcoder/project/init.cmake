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

Installs ./dk, ./dk.cmd and __dk.cmake in the current directory.

If there is a .git/ directory and no .gitattributes then a
default .gitattributes configuration file is added.

And if there is a .git/ directory the .gitattributes, ./dk, ./dk.cmd
and __dk.cmake are added to Git.

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

     git clone https://github.com/diskuv/dkcoder.git
     dkcoder/dk @ARG_COMMAND@

   Experienced user? Get more help with:

     dkcoder/dk @ARG_COMMAND@ MOREHELP
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
    if(ARG_QUIET)
        set(dk_run DkRun_V2_1.RunQuiet)
    else()
        set(dk_run DkRun_V2_1.Run)
        string(APPEND init_OPTIONS " -verbose")
    endif()

    # Run the command as a post script. Why?
    # 1. We don't want to run ./dk inside of ./dk. Not sure how the environment variables (etc.) interact.
    # 2. Makes it easy for DkStd_Std.Project.Init to erase the dkcoder/ project directory on Windows (no erasing a script or executable that is in use).
    if(CMAKE_HOST_WIN32)
        cmake_path(NATIVE_PATH dk_cmd dk_cmd_NATIVE)
        cmake_path(NATIVE_PATH DKCODER_PWD DKCODER_PWD_NATIVE)
        file(CONFIGURE OUTPUT "${DKCODER_POST_SCRIPT}" CONTENT [[@ECHO OFF
CALL "@dk_cmd_NATIVE@" @dk_run@ --generator dune -- DkStd_Std.Project.Init @init_OPTIONS@ "@DKCODER_PWD_NATIVE@"
IF %ERRORLEVEL% NEQ 0 EXIT /B %ERRORLEVEL%
ECHO dkcoder: project installed.
]]
            @ONLY NEWLINE_STYLE DOS)
    else()
        file(CONFIGURE OUTPUT "${DKCODER_POST_SCRIPT}" CONTENT [[#!/bin/sh
set -euf
'@dk_cmd@' @dk_run@ --generator dune -- DkStd_Std.Project.Init @init_OPTIONS@ '@DKCODER_PWD@'
ECHO "dkcoder: project installed."
]]
            @ONLY NEWLINE_STYLE UNIX)
    endif()
endmacro()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues HELP MOREHELP QUIET)
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
