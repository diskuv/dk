##########################################################################
# File: dkcoder/cmake/scripts/dksdk/cmake/copy.cmake                      #
#                                                                        #
# Copyright 2023 Diskuv, Inc.                                            #
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
    message(${ARG_MODE} [[usage: ./dk dksdk.cmake.copy

Creates a copy of the CMake installation into .ci/cmake/.

Typically used when mounting Docker containers, so that on a restart of
the Docker container the CMake installation is still present (assuming
the local project directory was mounted).

Directory Structure
===================

.ci/cmake
├── bin
│   ├── cmake
│   ├── cmake-gui
│   ├── cmcldeps
│   ├── cpack
│   └── ctest
├── doc
│   └── cmake/
├── man
│   ├── man1/
│   └── man7/
└── share
    ├── aclocal/
    ├── bash-completion/
    ├── cmake-3.25/
    ├── emacs/
    └── vim/

On Windows the files will be named cmake.exe, cpack.exe,
and ctest.exe in the ./ci/cmake/bin/ directory.

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print what files are being installed.
]])
endfunction()

# Check the running [cmake] is in a standalone cmake directory
# rather than /usr/bin/cmake
function(check_standalone_cmake OUT_SUCCESS_VARIABLE OUT_DIR_VARIABLE)
    # Either: cmake-3.25.2/bin/cmake -> cmake-3.25.2/
    # or:     cmake-3.25.2-macos10.10-universal/CMake.app/Contents/bin/cmake
    cmake_path(GET CMAKE_COMMAND PARENT_PATH d1)
    cmake_path(GET d1 PARENT_PATH d2)
    cmake_path(GET d2 FILENAME f2)
    if(f2 MATCHES "^cmake-" OR f2 STREQUAL cmake)
      set(${OUT_SUCCESS_VARIABLE} ON PARENT_SCOPE)
      set(${OUT_DIR_VARIABLE} "${d2}" PARENT_SCOPE)
    elseif(f2 STREQUAL "Contents")
      set(${OUT_SUCCESS_VARIABLE} ON PARENT_SCOPE)
      set(${OUT_DIR_VARIABLE} "${d2}" PARENT_SCOPE)
    else()
      set(${OUT_SUCCESS_VARIABLE} OFF PARENT_SCOPE)
    endif()
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP;QUIET" "" "")

    if(ARG_HELP)
      help(MODE NOTICE)
      return()
    endif()

    # QUIET
    if(ARG_QUIET)
        set(file_COMMAND COPY)
    else()
        set(file_COMMAND INSTALL)
    endif()

    # cmake-3.25.2/bin/cmake -> cmake-3.25.2/
    cmake_path(GET CMAKE_COMMAND PARENT_PATH d)
    cmake_path(GET d PARENT_PATH d)

    # validate it is a standalone cmake directory
    check_standalone_cmake(IS_STANDALONE STANDALONE_DIR)
    if(NOT IS_STANDALONE)
      message(FATAL_ERROR "This script does not support CMake installations that are not embedded in a standalone directory named `cmake-{VERSION}` or `cmake`. CMAKE_COMMAND=${CMAKE_COMMAND}")
    endif()

    # gitignore
    file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/.ci/cmake")
    file(COPY_FILE
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../__dk-tmpl/all.gitignore"
        "${CMAKE_SOURCE_DIR}/.ci/cmake/.gitignore"
        ONLY_IF_DIFFERENT)

    # during copy macOS has dangling symlinks, so we need to not use
    # FOLLOW_SYMLINK_CHAIN.
    # cmake-3.25.2-macos10.10-universal/CMake.app/Contents/Frameworks/QtPrintSupport.framework/Resources -> Versions/Current/Resources
    if(APPLE)
      set(file_ARGS)
    else()
      set(file_ARGS FOLLOW_SYMLINK_CHAIN)
    endif()

    # copy
    file(GLOB entries
      LIST_DIRECTORIES true
      RELATIVE ${STANDALONE_DIR}
      ${STANDALONE_DIR}/*)
    foreach(entry IN LISTS entries)
        file(${file_COMMAND} ${STANDALONE_DIR}/${entry}
            DESTINATION ${CMAKE_SOURCE_DIR}/.ci/cmake
            ${file_ARGS}
            USE_SOURCE_PERMISSIONS)
    endforeach()
endfunction()
