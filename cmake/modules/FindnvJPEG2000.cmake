# Copyright 2023 NVIDIA Corporation.  All rights reserved.
#
# NOTICE TO LICENSEE:
#
# This source code and/or documentation ("Licensed Deliverables") are
# subject to NVIDIA intellectual property rights under U.S. and
# international Copyright laws.
#
# These Licensed Deliverables contained herein is PROPRIETARY and
# CONFIDENTIAL to NVIDIA and is being provided under the terms and
# conditions of a form of NVIDIA software license agreement by and
# between NVIDIA and Licensee ("License Agreement") or electronically
# accepted by Licensee.  Notwithstanding any terms or conditions to
# the contrary in the License Agreement, reproduction or disclosure
# of the Licensed Deliverables to any third party without the express
# written consent of NVIDIA is prohibited.
#
# NOTWITHSTANDING ANY TERMS OR CONDITIONS TO THE CONTRARY IN THE
# LICENSE AGREEMENT, NVIDIA MAKES NO REPRESENTATION ABOUT THE
# SUITABILITY OF THESE LICENSED DELIVERABLES FOR ANY PURPOSE.  IT IS
# PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY OF ANY KIND.
# NVIDIA DISCLAIMS ALL WARRANTIES WITH REGARD TO THESE LICENSED
# DELIVERABLES, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY,
# NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE.
# NOTWITHSTANDING ANY TERMS OR CONDITIONS TO THE CONTRARY IN THE
# LICENSE AGREEMENT, IN NO EVENT SHALL NVIDIA BE LIABLE FOR ANY
# SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, OR ANY
# DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
# WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
# ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
# OF THESE LICENSED DELIVERABLES.
#
# U.S. Government End Users.  These Licensed Deliverables are a
# "commercial item" as that term is defined at 48 C.F.R. 2.101 (OCT
# 1995), consisting of "commercial computer software" and "commercial
# computer software documentation" as such terms are used in 48
# C.F.R. 12.212 (SEPT 1995) and is provided to the U.S. Government
# only as a commercial end item.  Consistent with 48 C.F.R.12.212 and
# 48 C.F.R. 227.7202-1 through 227.7202-4 (JUNE 1995), all
# U.S. Government End Users acquire the Licensed Deliverables with
# only those rights set forth herein.
#
# Any use of the Licensed Deliverables in individual and commercial
# software must include, in the user documentation and internal
# comments to the code, the above Disclaimer and U.S. Government End
# Users Notice.
if (nvJPEG2000_FOUND)
    return()
endif()

unset(NVJPEG2000_INCLUDE_FILE CACHE)
unset(NVJPEG2000_ROOT_DIR CACHE)
unset(NVJPEG2000_INCLUDE_DIR CACHE)
unset(NVJPEG2000_LIB_DIR CACHE)

if (DEFINED NVJPEG2000_ROOT OR DEFINED NVJPEG2K_PATH OR DEFINED ENV{NVJPEG2000_ROOT})
    if (DEFINED NVJPEG2000_ROOT)
        set(_NVJPEG2000_ROOT_DIR ${NVJPEG2000_ROOT})
    elseif(DEFINED NVJPEG2K_PATH)
        set(_NVJPEG2000_ROOT_DIR ${NVJPEG2K_PATH})
    else()
        set(_NVJPEG2000_ROOT_DIR $ENV{NVJPEG2000_ROOT})
    endif()

    message(STATUS "Looking for nvJPEG2000 in ${_NVJPEG2000_ROOT_DIR}")

    find_file(NVJPEG2000_INCLUDE_FILE
        NAMES nvjpeg2k.h
        PATHS "${_NVJPEG2000_ROOT_DIR}/include"
        NO_DEFAULT_PATH
    )

    if (NOT NVJPEG2000_INCLUDE_FILE)
        message(WARNING "Could not find nvJPEG2000 in path specified by NVJPEG2000_ROOT=${_NVJPEG2000_ROOT_DIR}")
    else()
        set(NVJPEG2000_ROOT_DIR ${_NVJPEG2000_ROOT_DIR})
        set(NVJPEG2000_INCLUDE_DIR "${_NVJPEG2000_ROOT_DIR}/include")
    endif()
    unset(_NVJPEG2000_ROOT_DIR)
endif()

# try platform defaults.
if (NOT NVJPEG2000_ROOT_DIR)
    # - Linux: /usr/lib/*/   (/usr/lib/x86_64-linux-gnu/)
    # - Windows: C:\Program Files\NVIDIA nvJPEG2K\vX.Y
    if(WIN32)
        set(platform_base "C:/Program Files/NVIDIA nvJPEG2K/v")

        # Build out a descending list of possible cuda installations, e.g.
        file(GLOB possible_paths "${platform_base}*")
        # Iterate the glob results and create a descending list.
        set(versions)
        foreach(p ${possible_paths})
            # Extract version number from end of string
            string(REGEX MATCH "[0-9][0-9]?\\.[0-9]$" p_version ${p})
            if(IS_DIRECTORY ${p} AND p_version)
                list(APPEND versions ${p_version})
            endif()
        endforeach()

        # Sort numerically in descending order, so we try the newest versions first.
        list(SORT versions COMPARE NATURAL ORDER DESCENDING)

        # With a descending list of versions, populate possible paths to search.
        set(search_paths)
        foreach(v ${versions})
            find_file(NVJPEG2000_INCLUDE_FILE
                NAMES nvjpeg2k.h
                PATHS "${platform_base}${v}/include"
                NO_DEFAULT_PATH
            )
            if (NVJPEG2000_INCLUDE_FILE)
                set(NVJPEG2000_ROOT_DIR "${platform_base}${v}")
                set(NVJPEG2000_INCLUDE_DIR "${platform_base}${v}/include")
                break()
            endif()
        endforeach()

        # We are done with these variables now, cleanup for caller.
        unset(platform_base)
        unset(possible_paths)
        unset(versions)
        unset(search_paths)
    elseif(UNIX)
        if (NOT APPLE)
            find_file(NVJPEG2000_INCLUDE_FILE
                NAMES nvjpeg2k.h
                PATHS "/usr/include"
                NO_DEFAULT_PATH
            )
            if (NVJPEG2000_INCLUDE_FILE)
                set(NVJPEG2000_ROOT_DIR "/usr")
                set(NVJPEG2000_INCLUDE_DIR "/usr/include")
            endif()
        endif()
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(nvJPEG2000
    REQUIRED_VARS
        NVJPEG2000_ROOT_DIR
        NVJPEG2000_INCLUDE_DIR
)
mark_as_advanced(NVJPEG2000_INCLUDE_DIR)

if (nvJPEG2000_FOUND)
    # Find all nvJPEG2000 libraries.
    set(cutensor_lib_names "nvjpeg2k;nvjpeg2k_static")
    foreach (lib_name ${cutensor_lib_names})
        if(NOT TARGET CUDA::${lib_name})
            find_library(CUDA_${lib_name}_LIBRARY
                NAMES ${lib_name}
                HINTS ${NVJPEG2000_ROOT_DIR}
                PATH_SUFFIXES lib64 lib
            )
            mark_as_advanced(CUDA_${lib_name}_LIBRARY)

            if (CUDA_${lib_name}_LIBRARY)
                mark_as_advanced(CUDA_${lib_name}_LIBRARY)

                if (NOT NVJPEG2000_LIBRARY_DIR)
                    get_filename_component(NVJPEG2000_LIBRARY_DIR ${CUDA_${lib_name}_LIBRARY} DIRECTORY ABSOLUTE)
                    mark_as_advanced(NVJPEG2000_LIBRARY_DIR)
                endif()

                message(STATUS "Found CUDA::${lib_name}")
                add_library(CUDA::${lib_name} UNKNOWN IMPORTED)
                target_include_directories(CUDA::${lib_name} SYSTEM INTERFACE "${NVJPEG2000_INCLUDE_DIR}")
                target_link_directories(CUDA::${lib_name} INTERFACE "${NVJPEG2000_LIBRARY_DIR}")
                set_property(TARGET CUDA::${lib_name} PROPERTY IMPORTED_LOCATION "${CUDA_${lib_name}_LIBRARY}")
            endif()
        endif()
    endforeach()
endif()
