##########################################################################
# File: dkcoder/cmake/scripts/dksdk/android/pkg/list.cmake               #
#                                                                        #
# Copyright 2025 Diskuv, Inc.                                            #
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

    message(${ARG_MODE} "usage: ./dk dksdk.android.pkg.list PACKAGES...

Lists the Android packages available for download and if needed a Java JDK
and the Android [sdkmanager] as well.

You may download a package using `./dk dksdk.android.pkg.download`.

Directory Structure
===================

Places the package within .ci/local/share/android-sdk:

.ci/local/share/
└── android-sdk
    ├── cmdline-tools
    │   └── latest
    │       ├── bin
    │       ├── lib
    │       └── source.properties
    └── patcher
    
Proxies
=======

The Android SDK Manager, which is used to download the Android packages,
supports HTTP proxies. If your environment must use an HTTP proxy to
download from the Internet, you can set the environment variable 'http_proxy'
to the URL of your HTTP proxy.
Examples: http://proxy_host:3182 or http://proxy_host:8080.
Authenticated proxies with a username and password are not supported.
Set the environment variable 'https_proxy' if you have a
https://proxy_host:proxy_port proxy.

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print CMake STATUS messages.

NO_SYSTEM_PATH
  Do not check for a JDK in well-known locations and in the PATH.
  Instead, install a JDK if no JDK exists at `.ci/local/share/jdk`.
")
endfunction()

function(list_pkgs)
    set(noValues)
    set(singleValues)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    # Install into .ci/local/share/android-sdk ...
    set_run_sdkmanager()
    execute_process(
        COMMAND ${run_sdkmanager} --list ${SDKMANAGER_COMMON_ARGS}
        COMMAND_ERROR_IS_FATAL ANY)
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    set(noValues HELP QUIET NO_SYSTEM_PATH)
    set(singleValues)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    if(ARG_HELP)
        help(MODE NOTICE)
        return()
    endif()

    # QUIET
    if(ARG_QUIET)
        set(loglevel DEBUG)
    else()
        set(loglevel STATUS)
    endif()

    # NO_SYSTEM_PATH
    set(expand_NO_SYSTEM_PATH)
    if(ARG_NO_SYSTEM_PATH)
        list(APPEND expand_NO_SYSTEM_PATH NO_SYSTEM_PATH)
    endif()

    # Get helper functions from JDK downloader
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../java/jdk/download.cmake")

    # Get helper functions from Android package downlader
    include("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/download.cmake")

    # gitignore
    file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk")
    file(COPY_FILE
        "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../__dk-tmpl/all.gitignore"
        "${CMAKE_SOURCE_DIR}/.ci/local/share/android-sdk/.gitignore"
        ONLY_IF_DIFFERENT)

    install_java_jdk(${expand_NO_SYSTEM_PATH})
    get_jdk_home(JDK_VERSION 17) # Set JAVA_HOME if available. Android Gradle requires 17, so check for that first.
    install_sdkmanager(${expand_NO_SYSTEM_PATH})

    list_pkgs()
endfunction()
