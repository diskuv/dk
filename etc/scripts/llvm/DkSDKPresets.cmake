# Minimal DkSDKPresets.cmake for reporting macOS minimum version
# Derived from build/dksdk-cmake/cmake/DkSDKPresets.cmake

cmake_policy(SET CMP0054 NEW)
cmake_policy(SET CMP0057 NEW)

function(DkSDKPresets_MacOSXVersionMin)
    set(noValues)
    set(singleValues OUTPUT_VARIABLE)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")
    # Keep in sync with main DkSDKPresets.cmake
    set("${ARG_OUTPUT_VARIABLE}" 10.16 PARENT_SCOPE)
endfunction()

if(CMAKE_SCRIPT_MODE_FILE)
    if(REPORT_MACOSX_VERSION_MIN)
        DkSDKPresets_MacOSXVersionMin(OUTPUT_VARIABLE _DkSDKPresets_version)
        execute_process(
            COMMAND "${CMAKE_COMMAND}" -E echo "${_DkSDKPresets_version}"
            COMMAND_ERROR_IS_FATAL ANY
        )
    else()
        message(WARNING "usage: cmake -D REPORT_MACOSX_VERSION_MIN=1 -P DkSDKPresets.cmake")
    endif()
endif()
