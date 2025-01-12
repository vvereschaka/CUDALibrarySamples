#
# Copyright (c) 2019-2023, NVIDIA CORPORATION.  All rights reserved.
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

# ---[ Check cmake version.
cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../cmake/modules)

include(GNUInstallDirs)

# ---[ Project specIFication.
project(cutensormg_example LANGUAGES C CXX CUDA)

# ##########################################
# cuTENSOR_example build mode
# ##########################################

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to 'Debug' as none was specified.")
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Choose the type of build." FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "" "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
else()
    message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
endif()

# ##########################################
# cuTENSOR_example dependencies
# ##########################################

if (NOT CUDAToolkit_FOUND)
    find_package(CUDAToolkit 10.1 REQUIRED)
endif()
if (NOT cuTENSOR_FOUND)
    find_package(cuTENSOR REQUIRED)
endif()

# Installation directories
if(NOT CUTENSORMG_EXAMPLES_INSTALL_PREFIX)
    set(CUTENSORMG_EXAMPLES_INSTALL_PREFIX cutensormg_examples)
endif()


# ##########################################
# cuTENSOR_example directories
# ##########################################

# By default put binaries in build/bin (pre-install)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# ##########################################
# Install examples
# ##########################################

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR} CACHE PATH "" FORCE)
endif()

# ##########################################
# cuTENSOR_example building flags
# ##########################################

# Global CXX/CUDA flags

# Global CXX flags/options
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Global CUDA CXX flags/options
set(CUDA_HOST_COMPILER ${CMAKE_CXX_COMPILER})
set(CMAKE_CUDA_STANDARD 11)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_EXTENSIONS OFF)

# ##########################################
# cuTENSOR_example target
# ##########################################

function(add_cutensormg_example GROUP_TARGET EXAMPLE_NAME EXAMPLE_SOURCES)
    list(GET EXAMPLE_SOURCES 0 EXAMPLE_MAIN_SOURCE)
    get_filename_component(EXAMPLE_TARGET ${EXAMPLE_MAIN_SOURCE} NAME_WE)
    add_executable(${EXAMPLE_TARGET} ${EXAMPLE_SOURCES})
    target_link_libraries(${EXAMPLE_TARGET}
        PRIVATE
            CUDA::cutensorMg
            CUDA::cutensor
    )
    set_target_properties(${EXAMPLE_TARGET}
        PROPERTIES
            POSITION_INDEPENDENT_CODE ON
            CUDA_SEPARABLE_COMPILATION ON
    )

    # Install example
    install(
        TARGETS ${EXAMPLE_TARGET}
        RUNTIME
        DESTINATION ${CUTENSORMG_EXAMPLES_INSTALL_PREFIX}/bin
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
    )
    # CMake cannot install the DLL files from the imported library targets before version 3.21.
    # Just extract the dll file path from the target properties and install it as a regular file.
    if (WIN32)
        get_target_property(cutensor_dll CUDA::cutensor IMPORTED_LOCATION)
        install(FILES ${cutensor_dll}
            DESTINATION ${CUTENSORMG_EXAMPLES_INSTALL_PREFIX}/bin
            PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
        )
        get_target_property(cutensorMg_dll CUDA::cutensorMg IMPORTED_LOCATION)
        install(FILES ${cutensorMg_dll}
            DESTINATION ${CUTENSORMG_EXAMPLES_INSTALL_PREFIX}/bin
            PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
        )
    endif()

    add_dependencies(${GROUP_TARGET} ${EXAMPLE_TARGET})
endfunction()

add_custom_target(cutensormg-examples)

add_cutensormg_example(cutensormg-examples "cuTENSORMg.example.contraction_multi_gpu" contraction_multi_gpu.cu)
add_cutensormg_example(cutensormg-examples "cuTENSORMg.example.blog_post" blog_post.cu)
