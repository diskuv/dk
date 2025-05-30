##########################################################################
# File: dkcoder\cmake\scripts\dksdk\project\inspect.cmake                 #
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
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")

    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()

    message(${ARG_MODE} "usage: ./dk dksdk.project.inspect <command> [options]

Inspect the project.

Directory Structure
===================

The project folder is expected to contain at least:

./
├── dk
├── dk.cmd
└── dkproject.jsonc

Commands
========

VARIABLES
    Show variables available to `dkproject.jsonc`.

DEPENDENCIES
    Show dependencies defined by `dkproject.jsonc`. May contain sensitive
    data like authentication credentials so do not dump to CI console or
    any log file without a URL masker.

HELP
  Print this help message.

Common Options
==============

QUIET
  Do not print CMake STATUS messages.

SOURCE_DIR <dir>
  Sets the directory assigned to the \${sourceDir} variable that is used
  within `dkproject.jsonc`.
  The \${sourceParentDir} will be assigned to the parent of \${sourceDir}.
  The SOURCE_DIR may start with a tilde (~) which will be treated as the home
  directory on Unix or the USERPROFILE directory on Windows.
  Defaults to the directory containing `./dk` and `dkproject.jsonc`.
  Relative paths are interpreted relative to `dkproject.jsonc`.

")
endfunction()

function(dksdk_project_inspect_variables)
    set(noValues NONINTERACTIVE)
    set(singleValues LOG_LEVEL CONFIG_FILE SOURCE_DIR)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    set(source_dir_OPTS)
    if(ARG_SOURCE_DIR)
        set(source_dir_OPTS -D "SOURCE_DIR=${ARG_SOURCE_DIR}")
    endif()

    # Fetch dksdk-access
    FetchContent_Populate(dksdk-access
            QUIET
            GIT_REPOSITORY https://gitlab.com/diskuv/dksdk-access.git
            GIT_TAG main
            GIT_SUBMODULES_RECURSE OFF)

    # Do get
    execute_process(
            COMMAND
            "${CMAKE_COMMAND}"
            -D "CONFIG_FILE=${ARG_CONFIG_FILE}"
            ${source_dir_OPTS}
            -D COMMAND_DUMP_VARIABLES=1
            -P "${dksdk-access_SOURCE_DIR}/cmake/run/get.cmake"
            COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()

function(dksdk_project_inspect_dependencies)
    set(noValues NONINTERACTIVE)
    set(singleValues LOG_LEVEL CONFIG_FILE SOURCE_DIR)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    set(source_dir_OPTS)
    if(ARG_SOURCE_DIR)
        set(source_dir_OPTS -D "SOURCE_DIR=${ARG_SOURCE_DIR}")
    endif()

    # Fetch dksdk-access
    FetchContent_Populate(dksdk-access
            QUIET
            GIT_REPOSITORY https://gitlab.com/diskuv/dksdk-access.git
            GIT_TAG main
            GIT_SUBMODULES_RECURSE OFF)

    # Do get
    execute_process(
            COMMAND
            "${CMAKE_COMMAND}"
            -D "CONFIG_FILE=${ARG_CONFIG_FILE}"
            ${source_dir_OPTS}
            -D COMMAND_DUMP_DEPENDENCIES=1
            -P "${dksdk-access_SOURCE_DIR}/cmake/run/get.cmake"
            COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues HELP QUIET VARIABLES DEPENDENCIES)
    set(singleValues SOURCE_DIR)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    if(ARG_HELP)
        help(MODE NOTICE)
        return()
    endif()

    # QUIET
    if(ARG_QUIET)
        set(logLevel DEBUG)
    else()
        set(logLevel STATUS)
    endif()

    # SOURCE_DIR
    set(expand_SOURCE_DIR)
    if(ARG_SOURCE_DIR)
        # Do not do any translation of SOURCE_DIR since <dksdk-access>/cmake/run/get.cmake
        # has transformations for relative paths and expanding tildes.
        set(expand_SOURCE_DIR SOURCE_DIR "${ARG_SOURCE_DIR}")
    endif()

    # configFile
    set(configFile dkproject.jsonc)
    cmake_path(ABSOLUTE_PATH configFile BASE_DIRECTORY "${CMAKE_SOURCE_DIR}" NORMALIZE
            OUTPUT_VARIABLE configFileAbs)

    if(ARG_VARIABLES)
        dksdk_project_inspect_variables(LOG_LEVEL ${logLevel}
                CONFIG_FILE "${configFileAbs}" ${expand_SOURCE_DIR})
    endif()
    if(ARG_DEPENDENCIES)
        dksdk_project_inspect_dependencies(LOG_LEVEL ${logLevel}
                CONFIG_FILE "${configFileAbs}" ${expand_SOURCE_DIR})
    endif()
endfunction()
