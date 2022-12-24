# 
# Copyright (c) 2020, NVIDIA CORPORATION.  All rights reserved.
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

# #############################################################################
# cusolver_examples build mode
# #############################################################################

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
set(CUSOLVER_EXAMPLES_BINARY_INSTALL_DIR "cusolver_examples/bin")

if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR} CACHE PATH "" FORCE)
endif()

# #############################################################################
# Global CXX/CUDA flags

# Global CXX flags/options
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")

# Global CUDA CXX flags/options
set(CUDA_HOST_COMPILER ${CMAKE_CXX_COMPILER})
set(CMAKE_CUDA_STANDARD 11)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_EXTENSIONS OFF)

# Debug options
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS} -O0 -g")
set(CMAKE_CUDA_FLAGS_DEBUG "${CMAKE_CUDA_FLAGS} -O0 -g -lineinfo")

# #############################################################################
# Add a new cuSOLVER example target.
# #############################################################################
function(add_cusolver_example EXAMPLE_NAME EXAMPLE_SOURCES)

    add_executable(${EXAMPLE_NAME} ${EXAMPLE_SOURCES})
    
    set_property(TARGET ${EXAMPLE_NAME} PROPERTY CUDA_ARCHITECTURES OFF)
    target_include_directories(${EXAMPLE_NAME} 
        PRIVATE 
            "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils"
    )
    target_link_libraries(${EXAMPLE_NAME}
        PRIVATE
            CUDA::cusolver
            CUDA::cublas
            CUDA::cublasLt
            CUDA::cusparse
        PUBLIC
            #NOTE: find_package(CUDAToolkit) doesn't support CUDA::cusolverMg target.
            cusolverMg
    )
    set_target_properties(${EXAMPLE_NAME} 
        PROPERTIES
            POSITION_INDEPENDENT_CODE ON
    )

    # Install example
    install(
        TARGETS ${EXAMPLE_NAME}
        RUNTIME
        DESTINATION ${CUSOLVER_EXAMPLES_BINARY_INSTALL_DIR}
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
    )

    if (TARGET cusolver_examples)
        add_dependencies(cusolver_examples ${EXAMPLE_NAME})
    endif()
endfunction()
