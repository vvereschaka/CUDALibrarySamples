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
if (NOT CUBLASLT_EXAMPLES_INSTALL_PREFIX)
    set(CUBLASLT_EXAMPLES_INSTALL_PREFIX cublaslt_examples)
endif()

if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR} CACHE PATH "" FORCE)
endif()

# #############################################################################
# Add a new cuBLASLt example target.
# #############################################################################
function(add_cublaslt_example EXAMPLE_NAME)
    cmake_parse_arguments(_CUBLASLT_OPT "STATIC" "" "SOURCES" ${ARGN} )

    add_executable(${EXAMPLE_NAME} ${_CUBLASLT_OPT_SOURCES})

    target_include_directories(${EXAMPLE_NAME}
        PRIVATE
            "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../Common"
    )
    if (_CUBLASLT_OPT_STATIC)
        target_link_libraries(${EXAMPLE_NAME}
            PRIVATE
                CUDA::cudart_static
                CUDA::cublasLt_static
        )
    else()
        target_link_libraries(${EXAMPLE_NAME}
            PRIVATE
                CUDA::cudart
                CUDA::cublasLt
        )
    endif()

    # Install example
    install(
        TARGETS ${EXAMPLE_NAME}
        RUNTIME
        DESTINATION ${CUBLASLT_EXAMPLES_INSTALL_PREFIX}/bin
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
    )

    if (TARGET cublaslt-examples)
        add_dependencies(cublaslt-examples ${EXAMPLE_NAME})
    endif()
endfunction()
