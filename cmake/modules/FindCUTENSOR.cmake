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

if (NOT CUDAToolkit_FOUND)
    find_package(CUDAToolkit 10.1 REQUIRED)
endif()

unset(CUTENSOR_INCLUDE_FILE CACHE)
unset(CUTENSOR_ROOT_DIR CACHE)
unset(CUTENSOR_INCLUDE_DIR CACHE)
unset(CUTENSOR_LIB_DIR CACHE)

if (DEFINED CUTENSOR_ROOT OR DEFINED ENV{CUTENSOR_ROOT})
    if (DEFINED CUTENSOR_ROOT)
        set(_CUTENSOR_ROOT_DIR ${CUTENSOR_ROOT})
    else()
        set(_CUTENSOR_ROOT_DIR $ENV{CUTENSOR_ROOT})
    endif()

    message(STATUS "Looking for cuTENSOR in ${_CUTENSOR_ROOT_DIR}")

    find_file(CUTENSOR_INCLUDE_FILE
        NAMES cutensor.h
        PATHS "${_CUTENSOR_ROOT_DIR}/include"
        NO_DEFAULT_PATH
    )

    if (NOT CUTENSOR_INCLUDE_FILE)
        message(WARNING "Could not find cuTENSOR in path specified by CUTENSOR_ROOT=${_CUTENSOR_ROOT_DIR}")
    else()
        set(CUTENSOR_ROOT_DIR ${_CUTENSOR_ROOT_DIR})
        set(CUTENSOR_INCLUDE_DIR "${_CUTENSOR_ROOT_DIR}/include")
    endif()
    unset(_CUTENSOR_ROOT_DIR)
endif()

# try platform defaults.
if (NOT CUTENSOR_ROOT_DIR)
    # - Linux: /usr/lib/*/libcutensor   (/usr/lib/x86_64-linux-gnu/libcutensor)
    # - Windows: C:\Program Files\NVIDIA cuTENSOR\vX.Y
    if(WIN32)
        set(platform_base "C:/Program Files/NVIDIA cuTENSOR/v")

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
            find_file(CUTENSOR_INCLUDE_FILE
                NAMES cutensor.h
                PATHS "${platform_base}${v}/include"
                NO_DEFAULT_PATH
            )
            if (CUTENSOR_INCLUDE_FILE)
                set(CUTENSOR_ROOT_DIR "${platform_base}${v}")
                set(CUTENSOR_INCLUDE_DIR "${platform_base}${v}/include")
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
            find_file(CUTENSOR_INCLUDE_FILE
                NAMES cutensor.h
                PATHS "/usr/include"
                NO_DEFAULT_PATH
            )
            if (CUTENSOR_INCLUDE_FILE)
                set(CUTENSOR_ROOT_DIR "/usr")
                set(CUTENSOR_INCLUDE_DIR "/usr/include")
            endif()
        endif()
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(cuTENSOR
  REQUIRED_VARS
    CUTENSOR_ROOT_DIR
    CUTENSOR_INCLUDE_DIR
)
mark_as_advanced(CUTENSOR_INCLUDE_DIR)

if (cuTENSOR_FOUND)
    if (WIN32)
        set(lib_search_suffix_prefix "lib")
    else()
        set(lib_search_suffix_prefix "libcutensor")
    endif()

    # The path suffix for cuTENSOR libraries.
    if (CUDAToolkit_VERSION VERSION_LESS 11.0)
        set(LIB_DIR_SUFFIX "${lib_search_suffix_prefix}/10.2")
    elseif (CUDAToolkit_VERSION VERSION_EQUAL 11.0)
        set(LIB_DIR_SUFFIX "${lib_search_suffix_prefix}/11.0")
    elseif (CUDAToolkit_VERSION VERSION_GREATER_EQUAL 11.1 AND CUDAToolkit_VERSION VERSION_LESS 12.0)
        set(LIB_DIR_SUFFIX "${lib_search_suffix_prefix}/11")
    else()
        set(LIB_DIR_SUFFIX "${lib_search_suffix_prefix}/12")
    endif()

    unset(lib_search_suffix_prefix)

    # Find all cuTENSOR libraries.
    set(cutensor_lib_names "cutensor;cutensor_static;cutensorMg;cutensorMg_static")
    foreach (lib_name ${cutensor_lib_names})
        if(NOT TARGET CUDA::${lib_name})
            find_library(CUDA_${lib_name}_LIBRARY
                NAMES ${lib_name}
                HINTS ${CUTENSOR_ROOT_DIR}
                PATH_SUFFIXES ${LIB_DIR_SUFFIX}
            )
            mark_as_advanced(CUDA_${lib_name}_LIBRARY)

            if (CUDA_${lib_name}_LIBRARY)
                mark_as_advanced(CUDA_${lib_name}_LIBRARY)

                if (NOT CUTENSOR_LIBRARY_DIR)
                    get_filename_component(CUTENSOR_LIBRARY_DIR ${CUDA_${lib_name}_LIBRARY} DIRECTORY ABSOLUTE)
                    mark_as_advanced(CUTENSOR_LIBRARY_DIR)
                endif()

                message(STATUS "Found CUDA::${lib_name}")
                add_library(CUDA::${lib_name} UNKNOWN IMPORTED)
                target_include_directories(CUDA::${lib_name} SYSTEM INTERFACE "${CUTENSOR_INCLUDE_DIR}")
                target_link_directories(CUDA::${lib_name} INTERFACE "${CUTENSOR_LIBRARY_DIR}")
                set_property(TARGET CUDA::${lib_name} PROPERTY IMPORTED_LOCATION "${CUDA_${lib_name}_LIBRARY}")
            endif()
        endif()
    endforeach()
endif()
