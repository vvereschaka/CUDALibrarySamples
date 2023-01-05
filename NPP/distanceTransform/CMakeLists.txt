#
# Copyright (c) 2019-2023, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto. Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.
#
# ---[ Check cmake version.
cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

include(GNUInstallDirs)

# ---[ Project specIFication.
set(ROUTINE distanceTransform)

project("${ROUTINE}_example" LANGUAGES CUDA CXX)

find_package(CUDAToolkit REQUIRED)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CUDA_HOST_COMPILER ${CMAKE_CXX_COMPILER})
set(CMAKE_CUDA_STANDARD 11)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Specifies the build type on single-configuration generators.")
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Installation directories
if (NOT NPP_EXAMPLES_INSTALL_PREFIX)
    set(NPP_EXAMPLES_INSTALL_PREFIX "npp_examples")
endif()

if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR} CACHE PATH "" FORCE)
endif()

add_executable(${ROUTINE}_example ${ROUTINE}.cpp)

set_source_files_properties(${ROUTINE}.cpp
    PROPERTIES
        LANGUAGE CUDA
)

set_target_properties(${ROUTINE}_example
    PROPERTIES
        POSITION_INDEPENDENT_CODE ON
        CUDA_SEPERABLE_COMPILATION ON
)

if(APPLE)
    # We need to add the path to the driver (libcuda.dylib) as an rpath,
    # so that the static cuda runtime can find it at runtime.
    set_target_properties(${ROUTINE}_example
        PROPERTIES
            BUILD_RPATH ${CMAKE_CUDA_IMPLICIT_LINK_DIRECTORIES}
    )
endif(APPLE)

target_link_libraries(${ROUTINE}_example
    PRIVATE
        CUDA::nppif
        CUDA::nppc
        CUDA::nppisu
        CUDA::cudart
)

install(
    TARGETS ${ROUTINE}_example
    RUNTIME
    DESTINATION ${NPP_EXAMPLES_INSTALL_PREFIX}/bin
    PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
)
install(
    DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/images
    DESTINATION ${NPP_EXAMPLES_INSTALL_PREFIX}
)

if (NOT TARGET npp_examples)
    add_custom_target(npp_examples)
endif()

add_dependencies(npp_examples ${ROUTINE}_example)
