##########################################################################
# File: dkcoder/cmake/scripts/dksdk/android/ndk/download.cmake            #
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

set(STUDIO_NAME "Electric Eel")
set(STUDIO_WHY [[Electric Eel is the latest version of Android Studio
that supports Gradle 7.4. This tool downloads Electric Eel because DkSDK
supports the security-minded Palantir Gradle Baseline (PGB) for Gradle 7.

The Android Studio version compatibility matrix is at
https://developer.android.com/studio/releases#android_gradle_plugin_and_android_studio_compatibility]])
set(STUDIO_VERSION 2022.1.1.21)

# Checksums are available at https://developer.android.com/studio/archive
set(android_studio_url_LINUX        https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${STUDIO_VERSION}/android-studio-${STUDIO_VERSION}-linux.tar.gz)
set(android_studio_url_MAC_ARM64    https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${STUDIO_VERSION}/android-studio-${STUDIO_VERSION}-mac_arm.zip)
set(android_studio_url_MAC_INTEL    https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${STUDIO_VERSION}/android-studio-${STUDIO_VERSION}-mac.zip)
set(android_studio_url_WINDOWS      https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${STUDIO_VERSION}/android-studio-${STUDIO_VERSION}-windows.zip)
set(android_studio_256_LINUX        0bca26c45daf5cad79b131c34013b985d146a2526990ea2aa6d88792d51905a1)
set(android_studio_256_MAC_ARM64    8171f686d7d9521620b895e89421b45a31cb7b77ffa451236f3ead788da37332)
set(android_studio_256_MAC_INTEL    d91af16c2982e1655e6bc3935ea29be3ba4866dd89310c634d858f0766eb18e6)
set(android_studio_256_WINDOWS      45db1f103b1113590e01ce73452ccbe6ca24af83188c51f8cabf57ceb9ae32ce)

function(help)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "MODE" "")

    if(NOT ARG_MODE)
        set(ARG_MODE FATAL_ERROR)
    endif()

    message(${ARG_MODE} "usage: ./dk dksdk.android.studio.download

Downloads Android Studio ${STUDIO_NAME} ${STUDIO_VERSION}.

${STUDIO_WHY}

Directory Structure
===================

.ci/local/share/android-studio
├── bin
│   ├── appletviewer.policy
│   ├── brokenPlugins.db
│   ├── format.sh
│   ├── fsnotifier
│   ├── game-tools.sh
│   ├── helpers
│   ├── icons
│   ├── idea.properties
│   ├── inspect.sh
│   ├── libdbm64.so
│   ├── lldb
│   ├── ltedit.sh
│   ├── profiler.sh
│   ├── remote-dev-server.sh
│   ├── restart.py
│   ├── studio64.vmoptions
│   ├── studio.png
│   ├── studio.sh
│   └── studio.svg
├── build.txt
├── Install-Linux-tar.txt
├── jbr
│   ├── bin/
│   ├── conf/
│   ├── legal/
│   ├── lib/
│   └── release/
├── lib/
├── license/
├── LICENSE.txt
├── NOTICE.txt
├── plugins/
└── product-info.json

Arguments
=========

HELP
  Print this help message.

QUIET
  Do not print CMake STATUS messages.

NO_SYSTEM_PATH
  Do not check for Android Studio in well-known locations and in the PATH.
  Instead, install Android Studio if no Android Studio exists at `.ci/local/share/android-studio`.
")
endfunction()

macro(_install_android_studio_helper ARCHIVE_NAME TYPE)
    set(archive_name ${ARCHIVE_NAME})
    set(url ${android_studio_url_${TYPE}})
    message(${loglevel} "Downloading Android Studio from ${url}")
    file(DOWNLOAD "${url}" ${CMAKE_CURRENT_BINARY_DIR}/${ARCHIVE_NAME}
        EXPECTED_HASH SHA256=${android_studio_256_${TYPE}})
endmacro()

# Clone of internal section in legacy __dk.cmake:__dkcoder_abi
function(find_macos_host_abi)
    execute_process(COMMAND /usr/sbin/sysctl -n machdep.cpu.brand_string
            OUTPUT_VARIABLE brand_string
            OUTPUT_STRIP_TRAILING_WHITESPACE
            COMMAND_ERROR_IS_FATAL ANY)
    if(brand_string MATCHES "Apple M")
        set(dkml_host_abi darwin_arm64 PARENT_SCOPE)
    else()
        execute_process(COMMAND /usr/bin/uname -m
                OUTPUT_VARIABLE brand_string
                OUTPUT_STRIP_TRAILING_WHITESPACE
                COMMAND_ERROR_IS_FATAL ANY)
        if(host_machine_type STREQUAL x86_64)
            set(dkml_host_abi darwin_x86_64 PARENT_SCOPE)
        elseif(host_machine_type STREQUAL arm64)
            set(dkml_host_abi darwin_arm64 PARENT_SCOPE)
        else()
            message(FATAL_ERROR "Problem: Unfortunately, your macOS ${host_machine_type} platform is currently not supported by this download script. ${solution}")
        endif()
    endif()
endfunction()

function(install_android_studio)
    set(noValues NO_SYSTEM_PATH)
    set(singleValues)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    set(hints
        "${CMAKE_SOURCE_DIR}/.ci/local/share/android-studio/bin"
        "${CMAKE_SOURCE_DIR}/.ci/local/share/Android Studio.app/Contents/MacOS")
    set(find_program_INITIAL)
    if(ARG_NO_SYSTEM_PATH)
        list(APPEND find_program_INITIAL NO_DEFAULT_PATH)
    endif()
    find_program(ANDROID_STUDIO NAMES studio.sh studio.bat studio HINTS ${hints} ${find_program_INITIAL})

    if(NOT ANDROID_STUDIO)
        # Download into .ci/local/share/android-studio (which is one of the HINTS)
        if(CMAKE_HOST_WIN32)
            _install_android_studio_helper(studio.zip WINDOWS)
        elseif(CMAKE_HOST_APPLE)
            find_macos_host_abi()
            if(dkml_host_abi STREQUAL darwin_arm64)
                _install_android_studio_helper(studio.zip MAC_ARM64)
            else()
                _install_android_studio_helper(studio.zip MAC)
            endif()
        elseif(CMAKE_HOST_UNIX)
            _install_android_studio_helper(studio.tar.gz LINUX)
        else()
            message(FATAL_ERROR "Your platform is currently not supported by this download script")
        endif()

        message(${loglevel} "Extracting Android Studio")
        file(ARCHIVE_EXTRACT INPUT ${CMAKE_CURRENT_BINARY_DIR}/${archive_name}
            DESTINATION ${CMAKE_SOURCE_DIR}/.ci/local/share)
    endif()

    find_program(ANDROID_STUDIO NAMES studio.sh studio.bat studio REQUIRED HINTS ${hints})
endfunction()

function(run)
    # Get helper functions from this file
    include(${CMAKE_CURRENT_FUNCTION_LIST_FILE})

    cmake_parse_arguments(PARSE_ARGV 0 ARG "HELP;QUIET;NO_SYSTEM_PATH" "" "")

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

    # gitignore. But not on Apple since "Android Studio.app" folder often
    # has macOS security to not write into the folder.
    if(NOT CMAKE_HOST_APPLE)
        set(extractdir "${CMAKE_SOURCE_DIR}/.ci/local/share/android-studio")
        file(MAKE_DIRECTORY "${extractdir}")
        file(COPY_FILE
            "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../../../__dk-tmpl/all.gitignore"
            "${extractdir}/.gitignore"
            ONLY_IF_DIFFERENT)
    endif()

    install_android_studio(${expand_NO_SYSTEM_PATH})
    message(STATUS "Android Studio: ${ANDROID_STUDIO}")
endfunction()
