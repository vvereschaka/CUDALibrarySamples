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

# ##########################################
# curand_examples build mode
# ##########################################

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to 'Release' as none was specified.")
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose the type of build." FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "" "Debug" "Release")
else()
    message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
endif()

# ##########################################
# curand_examples directories
# ##########################################

# By default put binaries in build/bin (pre-install)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Installation directories
if (NOT CURAND_EXAMPLES_INSTALL_PREFIX)
    set(CURAND_EXAMPLES_INSTALL_PREFIX curand_examples)
endif()

# ##########################################
# Install examples
# ##########################################

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR} CACHE PATH "" FORCE)
endif()

function(add_curand_example GROUP_TARGET EXAMPLE_NAME EXAMPLE_SOURCES)
    add_executable(${EXAMPLE_NAME} ${EXAMPLE_SOURCES})

    set_property(TARGET ${EXAMPLE_NAME} PROPERTY CUDA_ARCHITECTURES OFF)

    target_include_directories(${EXAMPLE_NAME}
        PRIVATE
            "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../utils"
        PUBLIC
            ${CUDA_INCLUDE_DIRS}
    )
    target_link_libraries(${EXAMPLE_NAME}
        PUBLIC
            CUDA::cudart
            CUDA::curand
    )
    set_target_properties(${EXAMPLE_NAME} PROPERTIES
        POSITION_INDEPENDENT_CODE ON
    )

    # Install example
    install(
        TARGETS ${EXAMPLE_NAME}
        RUNTIME
        DESTINATION ${CURAND_EXAMPLES_INSTALL_PREFIX}/bin
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
    )

    if (TARGET ${GROUP_TARGET})
        add_dependencies(${GROUP_TARGET} ${EXAMPLE_NAME})
    endif()
endfunction()
