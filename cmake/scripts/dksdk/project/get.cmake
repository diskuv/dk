##########################################################################
# File: dkcoder\cmake\scripts\dksdk\project\get.cmake                     #
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

    message(${ARG_MODE} "usage: ./dk dksdk.project.get

Get the dependencies stated in the `dkproject.jsonc` file.

Directory Structure
===================

The dependencies will be placed in the FETCH_DIR directory which
defaults to `fetch/`.
The version of DkSDK will be placed into the .z-dk/dk-version/
folder for both the Major.Minor and Major.Minor.Patch formats.

./
├── .z-dk/
│   └── dk-version/
│       └── majminpat
│       └── majmin
├── __dk.cmake
├── dk
├── dk.cmd
├── dkproject.jsonc
└── fetch/
    ├── .gitignore
    ├── dune
    ├── project1/
    ├── project2/
    ├── ...
    └── projectN/

If `fetch/.gitignore` does not exist, it will be created but not overwritten.
The file will instruct Git to not look at the contents of the `fetch/` directory
during a `git add`.

If `fetch/dune` does not exist, it will be created but not overwritten.
The file will instruct Dune to not scan the `fetch/` directory during a `dune build`.

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print CMake STATUS messages.

FETCH_DIR <dir>
  The directory to place the dependencies. Defaults to `fetch/`.
  Relative paths are interpreted relative to the `./dk` and `./dk.cmd` scripts.

SOURCE_DIR <dir>
  Sets the directory assigned to the \${sourceDir} variable that is used
  within `dkproject.jsonc`.
  The \${sourceParentDir} will be assigned to the parent of \${sourceDir}.
  The SOURCE_DIR may start with a tilde (~) which will be treated as the home
  directory on Unix or the USERPROFILE directory on Windows.
  Defaults to the directory containing `./dk` and `dkproject.jsonc`.
  Relative paths are interpreted relative to `dkproject.jsonc`.

  Use when you want to preserve the local development environment of <dir>;
  the convention inside `dkproject.jsonc` is that local overrides will be
  optionally available either in <dir>'s sibling directories or <dir>/fetch's
  subdirectories.
  The typical use case is when <dir> is on a host machine (perhaps a Windows
  host) and `dkproject.jsonc` (etc.) has been checked out in a guest machine
  (perhaps WSL2 or Docker) through a mounted drive or volume. Often the
  performance of the mount is quite poor (could be 100X slowdown on WSL2
  I/O), so a copy of the local development environment speeds up builds
  tremendously.

  The local development environment will be copied in this version, although
  future versions may use symlinks when the I/O speed to read <dir> is fast.

SANDBOX
  Skip any URLs that use \${sourceParentDir} or \${projectParentDir}.

ONLY_DKSDK_VERSION
  Only fetch enough dependencies to calculate the DkSDK version accurately.
  Currently the dksdk-cmake dependency is the only dependency needed.

NONINTERACTIVE
  Best effort attempt to stop `git` and any other source fetching tools from
  asking interactive questions like username/password prompts. Use when
  scripting.
")
endfunction()

function(dksdk_project_get)
    set(noValues NONINTERACTIVE SANDBOX ONLY_DKSDK_VERSION)
    set(singleValues LOG_LEVEL FETCH_DIR CONFIG_FILE SOURCE_DIR)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    message(${ARG_LOG_LEVEL} "Fetching dependencies into ${ARG_FETCH_DIR} ...")

    if(ARG_NONINTERACTIVE)
        set(interactive 0)
    else()
        set(interactive 1)
    endif()

    if(ARG_SANDBOX)
        set(sandbox 1)
    else()
        set(sandbox 0)
    endif()

    set(source_dir_OPTS)
    if(ARG_SOURCE_DIR)
        list(APPEND source_dir_OPTS -D "SOURCE_DIR=${ARG_SOURCE_DIR}")
    endif()

    set(only_dksdk_version_OPTS)
    if(ARG_ONLY_DKSDK_VERSION)
        list(APPEND only_dksdk_version_OPTS -D ONLY_DKSDK_VERSION=1)
    endif()

    # Fetch dksdk-access.
    # But we don't want to download every time we run the script.
    #
    #   The default, but explicit so we know where it is.
    set(access_subbuild_dir "${CMAKE_CURRENT_BINARY_DIR}/dksdk-access-subbuild")
    #   Also the default, but explicit since we don't always call FetchContent_Populate().
    set(access_src_dir "${CMAKE_CURRENT_BINARY_DIR}/dksdk-access-src")
    #   Prior downloads are fine if done within the last one hour.
    set(ttl_MINUTES 60)
    if(DEFINED ENV{DKCODER_TTL_MINUTES})
        set(ttl_MINUTES "$ENV{DKCODER_TTL_MINUTES}")
    endif()
    string(TIMESTAMP now_EPOCHSECS "%s")
    math(EXPR min_valid_EPOCHSECS "${now_EPOCHSECS} - 60*${ttl_MINUTES}")
    set(tstamp_EPOCHSECS 0)
    if(EXISTS "${access_subbuild_dir}/build.ninja")
        file(TIMESTAMP "${access_subbuild_dir}/build.ninja" tstamp_EPOCHSECS "%s")
    elseif(EXISTS "${access_subbuild_dir}/Makefile")
        file(TIMESTAMP "${access_subbuild_dir}/Makefile" tstamp_EPOCHSECS "%s")
    endif()
    if(NOT tstamp_EPOCHSECS OR tstamp_EPOCHSECS LESS_EQUAL min_valid_EPOCHSECS)
        # Cache miss. Time to update dksdk-access.
        FetchContent_Populate(dksdk-access
                QUIET
                SOURCE_DIR "${access_src_dir}"
                SUBBUILD_DIR "${access_subbuild_dir}"
                GIT_REPOSITORY https://gitlab.com/diskuv/dksdk-access.git
                GIT_TAG origin/main
                # As of 3.25.3 the bug https://gitlab.kitware.com/cmake/cmake/-/issues/24578
                # has still not been fixed. That means empty strings get removed.
                # ExternalProject_Add(GIT_SUBMODULES) in dkcoder-subbuild/CMakeLists.txt
                # means fetch all submodules.
                # https://gitlab.kitware.com/cmake/cmake/-/issues/20579#note_734045
                # has a workaround.
                GIT_SUBMODULES cmake # Non-git-submodule dir that already exists
                GIT_SUBMODULES_RECURSE OFF)
    endif()

    # Do get
    cmake_path(GET ARG_CONFIG_FILE PARENT_PATH CONFIG_DIR)
    execute_process(
            COMMAND
            "${CMAKE_COMMAND}"
            -D "INTERACTIVE=${interactive}"
            -D "SANDBOX=${sandbox}"
            -D "CONFIG_FILE=${ARG_CONFIG_FILE}"
            ${source_dir_OPTS}
            -D "COMMAND_GET=${ARG_FETCH_DIR}"
            -D "CACHE_DIR=${CMAKE_CURRENT_BINARY_DIR}"
            -D "OUT_DKSDK_VERSION=${CONFIG_DIR}/.z-dk/dk-version/majminpat"
            -D "OUT_DKSDK_VERSION_MAJMIN=${CONFIG_DIR}/.z-dk/dk-version/majmin"
            ${only_dksdk_version_OPTS}
            -P "${access_src_dir}/cmake/run/get.cmake"
            COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues HELP QUIET NONINTERACTIVE SANDBOX ONLY_DKSDK_VERSION)
    set(singleValues FETCH_DIR SOURCE_DIR)
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

    # FETCH_DIR
    set(fetchDir fetch)
    if(ARG_FETCH_DIR)
        set(fetchDir ${ARG_FETCH_DIR})
    endif()
    cmake_path(ABSOLUTE_PATH fetchDir BASE_DIRECTORY "${CMAKE_SOURCE_DIR}" NORMALIZE
            OUTPUT_VARIABLE fetchDirAbs)

    # SOURCE_DIR
    set(expand_SOURCE_DIR)
    if(ARG_SOURCE_DIR)
        # Do not do any translation of SOURCE_DIR since <dksdk-access>/cmake/run/get.cmake
        # has transformations for relative paths and expanding tildes.
        set(expand_SOURCE_DIR SOURCE_DIR "${ARG_SOURCE_DIR}")
    endif()

    # NONINTERACTIVE
    set(expand_NONINTERACTIVE)
    if(ARG_NONINTERACTIVE)
        set(expand_NONINTERACTIVE NONINTERACTIVE)
    endif()

    # SANDBOX
    set(expand_SANDBOX)
    if(ARG_SANDBOX)
        set(expand_SANDBOX SANDBOX)
    endif()

    # ONLY_DKSDK_VERSION
    set(expand_ONLY_DKSDK_VERSION)
    if(ARG_ONLY_DKSDK_VERSION)
        set(expand_ONLY_DKSDK_VERSION ONLY_DKSDK_VERSION)
    endif()

    # configFile
    set(configFile dkproject.jsonc)
    cmake_path(ABSOLUTE_PATH configFile BASE_DIRECTORY "${CMAKE_SOURCE_DIR}" NORMALIZE
            OUTPUT_VARIABLE configFileAbs)

    dksdk_project_get(LOG_LEVEL ${logLevel}
            FETCH_DIR "${fetchDirAbs}"
            CONFIG_FILE "${configFileAbs}"
            ${expand_NONINTERACTIVE}
            ${expand_SOURCE_DIR}
            ${expand_SANDBOX}
            ${expand_ONLY_DKSDK_VERSION})
    message(STATUS "Project dependencies have been updated.")
endfunction()
