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
if (cuSPARSELt_FOUND)
    return()
endif()

if (NOT CUDAToolkit_FOUND)
    find_package(CUDAToolkit 10.1 REQUIRED)
endif()

unset(CUSPARSELT_INCLUDE_FILE CACHE)
unset(CUSPARSELT_ROOT_DIR CACHE)
unset(CUSPARSELT_INCLUDE_DIR CACHE)
unset(CUSPARSELT_LIB_DIR CACHE)

if (DEFINED CUSPARSELT_ROOT OR DEFINED ENV{CUSPARSELT_ROOT})
    if (DEFINED CUSPARSELT_ROOT)
        set(_CUSPARSELT_ROOT_DIR ${CUSPARSELT_ROOT})
    else()
        set(_CUSPARSELT_ROOT_DIR $ENV{CUSPARSELT_ROOT})
    endif()

    message(STATUS "Looking for cuSPARSELt in ${_CUSPARSELT_ROOT_DIR}")

    find_file(CUSPARSELT_INCLUDE_FILE
        NAMES cusparseLt.h
        PATHS "${_CUSPARSELT_ROOT_DIR}/include"
        NO_DEFAULT_PATH
    )

    if (NOT CUSPARSELT_INCLUDE_FILE)
        message(WARNING "Could not find cuSPARSELt in path specified by CUSPARSELT_ROOT=${_CUSPARSELT_ROOT_DIR}")
    else()
        set(CUSPARSELT_ROOT_DIR ${_CUSPARSELT_ROOT_DIR})
        set(CUSPARSELT_INCLUDE_DIR "${_CUSPARSELT_ROOT_DIR}/include")
    endif()
    unset(_CUSPARSELT_ROOT_DIR)
endif()

# try platform defaults.
if (NOT CUSPARSELT_ROOT_DIR)
    # - Linux: /usr/lib/*/libcusparselt   (/usr/lib/x86_64-linux-gnu/libcusparselt)
    # - Windows: C:\Program Files\NVIDIA cuSPARSELt\vX.Y
    if(WIN32)
        set(platform_base "C:/Program Files/NVIDIA cuSPARSELt/v")

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
            find_file(CUSPARSELT_INCLUDE_FILE
                NAMES cusparseLt.h
                PATHS "${platform_base}${v}/include"
                NO_DEFAULT_PATH
            )
            if (CUSPARSELT_INCLUDE_FILE)
                set(CUSPARSELT_ROOT_DIR "${platform_base}${v}")
                set(CUSPARSELT_INCLUDE_DIR "${platform_base}${v}/include")
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
            find_file(CUSPARSELT_INCLUDE_FILE
                NAMES cusparseLt.h
                PATHS "/usr/include"
                NO_DEFAULT_PATH
            )
            if (CUSPARSELT_INCLUDE_FILE)
                set(CUSPARSELT_ROOT_DIR "/usr")
                set(CUSPARSELT_INCLUDE_DIR "/usr/include")
            endif()
        endif()
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(cuSPARSELt
    REQUIRED_VARS
        CUSPARSELT_ROOT_DIR
        CUSPARSELT_INCLUDE_DIR
)
mark_as_advanced(CUSPARSELT_INCLUDE_DIR)

if (cuSPARSELt_FOUND)
    # Find all cuSPARSELt libraries.
    set(cusparselt_lib_names "cusparseLt;cusparseLt_static")
    foreach (lib_name ${cusparselt_lib_names})
        if(NOT TARGET CUDA::${lib_name})
            find_library(CUDA_${lib_name}_LIBRARY
                NAMES ${lib_name}
                HINTS ${CUSPARSELT_ROOT_DIR}
                PATH_SUFFIXES lib64 lib
            )

            if (WIN32)
                find_file(CUDA_${lib_name}_dll_LIBRARY
                    NAMES ${lib_name}.dll
                    PATHS ${CUSPARSELT_ROOT_DIR}
                    PATH_SUFFIXES lib64 lib
                    NO_DEFAULT_PATH
                )
            endif()

            if (CUDA_${lib_name}_LIBRARY)
                mark_as_advanced(CUDA_${lib_name}_LIBRARY)

                if (NOT CUSPARSELT_LIBRARY_DIR)
                    get_filename_component(CUSPARSELT_LIBRARY_DIR ${CUDA_${lib_name}_LIBRARY} DIRECTORY ABSOLUTE)
                    mark_as_advanced(CUSPARSELT_LIBRARY_DIR)
                endif()

                message(STATUS "Found CUDA::${lib_name}")
                if (CUDA_${lib_name}_dll_LIBRARY)
                    add_library(CUDA::${lib_name} SHARED IMPORTED)
                else()
                    add_library(CUDA::${lib_name} UNKNOWN IMPORTED)
                endif()
                target_include_directories(CUDA::${lib_name} SYSTEM INTERFACE "${CUSPARSELT_INCLUDE_DIR}")
                target_link_directories(CUDA::${lib_name} INTERFACE "${CUSPARSELT_LIBRARY_DIR}")
                set_target_properties(CUDA::${lib_name}
                    PROPERTIES
                        IMPORTED_LOCATION "${CUDA_${lib_name}_LIBRARY}"
                        INTERFACE_LINK_LIBRARIES "${lib_name}"
                )
                if (CUDA_${lib_name}_dll_LIBRARY)
                    mark_as_advanced(CUDA_${lib_name}_dll_LIBRARY)

                    set_target_properties(CUDA::${lib_name}
                        PROPERTIES
                            IMPORTED_LOCATION ${CUDA_${lib_name}_dll_LIBRARY}
                            IMPORTED_IMPLIB "${CUDA_${lib_name}_LIBRARY}"
                            INTERFACE_LINK_LIBRARIES "${lib_name}"
                    )
                endif()
            endif()
        endif()
    endforeach()
endif()
