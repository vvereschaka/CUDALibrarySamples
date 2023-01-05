#
# Copyright (c) 2023, NVIDIA CORPORATION.  All rights reserved.
#
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#  - Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#  - Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#  - Neither the name(s) of the copyright holder(s) nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
include(GNUInstallDirs)
find_package(CUDAToolkit REQUIRED)

# Adjust custom build type for the cuSPARSELt examples.
#
# cuSPARSELt libraries requires matching of some values during linking
# on Windows platform using VC. So we need to use Release build type
# for the examples on Windows becase the cuPARSELt libraries are built as Release.
# see: "error LNK2038: mismatch detected for ..."

if (DEFINED CUSPARSELT_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE ${CUSPARSELT_BUILD_TYPE})
else()
    set(CMAKE_BUILD_TYPE Release)
endif()

if (NOT _ADJUST_BUILD_TYPE)
    if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
        message(STATUS "Setting build type to 'Release' as none was specified.")
        set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose the type of build." FORCE)
        set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "" "Debug" "Release")
    else()
        message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
    endif()

    # Adjust just once.
    set(_ADJUST_BUILD_TYPE 1 INTERNAL)
    mark_as_advanced(_ADJUST_BUILD_TYPE)
endif()

# By default put binaries in build/bin (pre-install)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Installation directories
if (NOT CUSPARSELT_EXAMPLES_INSTALL_PREFIX)
    set(CUSPARSELT_EXAMPLES_INSTALL_PREFIX cusparselt_examples)
endif()

if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR} CACHE PATH "" FORCE)
endif()

if (NOT DEFINED CUSPARSELT_PATH)
    set(CUSPARSELT_PATH $ENV{CUSPARSELT_PATH} CACHE INTERNAL "")
endif()

if (CUSPARSELT_PATH STREQUAL "")
    message(FATAL_ERROR "Please set the environment variables CUSPARSELT_PATH to the path of the cuSPARSELt installation.")
endif ()

message(STATUS "Using CUSPARSELT_PATH = ${CUSPARSELT_PATH}")

# #############################################################################
# Add a new cuSOLVER example target.
# #############################################################################
function(add_cusparselt_example EXAMPLE_NAME EXAMPLE_SOURCES)
    cmake_parse_arguments(_CUPARSELT_OPT "STATIC" "" "" ${ARGN} )

    add_executable(${EXAMPLE_NAME} ${EXAMPLE_SOURCES})

    target_include_directories(${EXAMPLE_NAME}
        PRIVATE
            ${CUSPARSELT_PATH}/include
    )

    if (_CUPARSELT_OPT_STATIC)
        target_link_libraries(${EXAMPLE_NAME}
            PRIVATE
                cusparseLt_static
        )
    else()
        target_link_libraries(${EXAMPLE_NAME}
            PRIVATE
                cusparseLt
        )
    endif()

    # Common libraries
    target_link_libraries(${EXAMPLE_NAME}
        PRIVATE
            CUDA::cudart
            CUDA::cusparse
            CUDA::nvrtc
    )

    if(WIN32)
        target_link_directories(${EXAMPLE_NAME}
            PRIVATE
                ${CUSPARSELT_PATH}/lib
        )
    endif()

    if (UNIX)
        target_link_directories(${EXAMPLE_NAME}
            PRIVATE
                ${CUSPARSELT_PATH}/lib
                ${CUSPARSELT_PATH}/lib64   # Just in case
        )

        target_link_libraries(${EXAMPLE_NAME}
            PUBLIC
                ${CMAKE_DL_LIBS}
        )
    endif()

    # Install example
    install(
        TARGETS ${EXAMPLE_NAME}
        RUNTIME
        DESTINATION ${CUSPARSELT_EXAMPLES_INSTALL_PREFIX}/bin
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
    )

    if (TARGET cusparselt_examples)
        add_dependencies(cusparselt_examples ${EXAMPLE_NAME})
    endif()
endfunction()
