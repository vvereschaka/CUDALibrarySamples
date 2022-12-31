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

# Ajust an extra path to search our custom cmake modules.
if (NOT ${CMAKE_CURRENT_SOURCE_DIR}/modules IN_LIST CMAKE_MODULE_PATH)
    list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/modules)
endif()

# By default put binaries in build/bin (pre-install)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR} CACHE PATH "" FORCE)
endif()

# Installation directories
if (NOT DEFINED NVJPEG_EXAMPLES_BINARY_INSTALL_DIR)
    set(NVJPEG_EXAMPLES_BINARY_INSTALL_DIR "nvjpeg_examples/bin")
endif()
if (NOT DEFINED NVJPEG2000_EXAMPLES_BINARY_INSTALL_DIR)
    set(NVJPEG2000_EXAMPLES_BINARY_INSTALL_DIR "nvjpeg2000_examples/bin")
endif()
if (NOT DEFINED NVTIFF_EXAMPLES_BINARY_INSTALL_DIR)
    set(NVTIFF_EXAMPLES_BINARY_INSTALL_DIR "nvtiff_examples/bin")
endif()

# add example functions.
function(add_nvjpeg_example GROUP_TARGET EXAMPLE_NAME EXAMPLE_SOURCES)
    add_executable(${EXAMPLE_NAME} ${EXAMPLE_SOURCES})

    target_link_libraries(${EXAMPLE_NAME}
        PRIVATE
            CUDA::cudart_static
            CUDA::nvjpeg
            CUDA::nppig
            CUDA::nppc
            CUDA::nppial
    )
    #NOTE: call 'find_package(Threads REQUIRED)' before calling the function.
    if (TARGET Threads::Threads)
        target_link_libraries(${EXAMPLE_NAME}
            PRIVATE
                Threads::Threads
        )
    endif()
    set_target_properties(${EXAMPLE_NAME}
        PROPERTIES
            CUDA_SEPERABLE_COMPILATION ON
            POSITION_INDEPENDENT_CODE ON
    )
    if (APPLE)
        # We need to add the path to the driver (libcuda.dylib) as an rpath,
        # so that the static cuda runtime can find it at runtime.
        set_target_properties(${EXAMPLE_NAME}
            PROPERTIES
                BUILD_RPATH ${CMAKE_CUDA_IMPLICIT_LINK_DIRECTORIES}
        )
    endif()

    # Install example
    install(
        TARGETS ${EXAMPLE_NAME}
        RUNTIME
        DESTINATION ${NVJPEG_EXAMPLES_BINARY_INSTALL_DIR}
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
    )
    if (TARGET ${GROUP_TARGET})
        add_dependencies(${GROUP_TARGET} ${EXAMPLE_NAME})
    endif()
endfunction()

function(add_nvjpeg2000_example GROUP_TARGET EXAMPLE_NAME EXAMPLE_SOURCES)
    add_executable(${EXAMPLE_NAME} ${EXAMPLE_SOURCES})

    target_link_libraries(${EXAMPLE_NAME}
        PRIVATE
            CUDA::cudart_static
            CUDA::nvjpeg2k
    )
    #NOTE: call 'find_package(Threads REQUIRED)' before calling the function.
    if (TARGET Threads::Threads)
        target_link_libraries(${EXAMPLE_NAME}
            PRIVATE
                Threads::Threads
        )
    endif()
    if (UNIX)
        target_link_libraries(${EXAMPLE_NAME}
            PUBLIC
                stdc++fs
        )
    endif()

    # Install example
    install(
        TARGETS ${EXAMPLE_NAME}
        RUNTIME
        DESTINATION ${NVJPEG2000_EXAMPLES_BINARY_INSTALL_DIR}
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
    )

    if (TARGET ${GROUP_TARGET})
        add_dependencies(${GROUP_TARGET} ${EXAMPLE_NAME})
    endif()
endfunction()

function(add_nvtiff_example GROUP_TARGET EXAMPLE_NAME EXAMPLE_SOURCES)
    add_executable(${EXAMPLE_NAME} ${EXAMPLE_SOURCES})

    target_link_libraries(${EXAMPLE_NAME}
        PRIVATE
            CUDA::cudart_static
        PUBLIC
            CUDA::nvtiff
    )
    #NOTE: call 'find_package(Threads REQUIRED)' before calling the function.
    if (TARGET Threads::Threads)
        target_link_libraries(${EXAMPLE_NAME}
            PRIVATE
                Threads::Threads
        )
    endif()
    if (UNIX)
        target_link_libraries(${EXAMPLE_NAME}
            PUBLIC
                stdc++fs
        )
    endif()

    # Install example
    install(
        TARGETS ${EXAMPLE_NAME}
        RUNTIME DESTINATION ${NVTIFF_EXAMPLES_BINARY_INSTALL_DIR}
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
    )
    # CMake cannot install the DLL files from the imported library targets before version 3.21.
    # Just extract the dll file path from the target properties and install it as a regular file.
    if (WIN32)
        get_target_property(nvtiff_dll CUDA::nvtiff IMPORTED_LOCATION)
        install(FILES ${nvtiff_dll}
            DESTINATION ${NVTIFF_EXAMPLES_BINARY_INSTALL_DIR}
            PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
        )
    endif()

    if (TARGET ${GROUP_TARGET})
        add_dependencies(${GROUP_TARGET} ${EXAMPLE_NAME})
    endif()
endfunction()
