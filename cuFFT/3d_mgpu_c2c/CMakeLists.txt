# Copyright 1993-2023 NVIDIA Corporation.  All rights reserved.
#
# NOTICE TO LICENSEE:
#
# This source code and/or documentation ("Licensed Deliverables") are subject to
# NVIDIA intellectual property rights under U.S. and international Copyright
# laws.
#
# These Licensed Deliverables contained herein is PROPRIETARY and CONFIDENTIAL
# to NVIDIA and is being provided under the terms and conditions of a form of
# NVIDIA software license agreement by and between NVIDIA and Licensee ("License
# Agreement") or electronically accepted by Licensee.  Notwithstanding any terms
# or conditions to the contrary in the License Agreement, reproduction or
# disclosure of the Licensed Deliverables to any third party without the express
# written consent of NVIDIA is prohibited.
#
# NOTWITHSTANDING ANY TERMS OR CONDITIONS TO THE CONTRARY IN THE LICENSE
# AGREEMENT, NVIDIA MAKES NO REPRESENTATION ABOUT THE SUITABILITY OF THESE
# LICENSED DELIVERABLES FOR ANY PURPOSE.  IT IS PROVIDED "AS IS" WITHOUT EXPRESS
# OR IMPLIED WARRANTY OF ANY KIND. NVIDIA DISCLAIMS ALL WARRANTIES WITH REGARD
# TO THESE LICENSED DELIVERABLES, INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE.
# NOTWITHSTANDING ANY TERMS OR CONDITIONS TO THE CONTRARY IN THE LICENSE
# AGREEMENT, IN NO EVENT SHALL NVIDIA BE LIABLE FOR ANY SPECIAL, INDIRECT,
# INCIDENTAL, OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THESE LICENSED DELIVERABLES.
#
# U.S. Government End Users.  These Licensed Deliverables are a "commercial
# item" as that term is defined at 48 C.F.R. 2.101 (OCT 1995), consisting of
# "commercial computer software" and "commercial computer software
# documentation" as such terms are used in 48 C.F.R. 12.212 (SEPT 1995) and is
# provided to the U.S. Government only as a commercial end item.  Consistent
# with 48 C.F.R.12.212 and 48 C.F.R. 227.7202-1 through 227.7202-4 (JUNE 1995),
# all U.S. Government End Users acquire the Licensed Deliverables with only
# those rights set forth herein.
#
# Any use of the Licensed Deliverables in individual and commercial software
# must include, in the user documentation and internal comments to the code, the
# above Disclaimer and U.S. Government End Users Notice.
cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

include(GNUInstallDirs)

# Initialize before project definition.
# https://cmake.org/cmake/help/latest/variable/CMAKE_CUDA_ARCHITECTURES.html
if(CMAKE_CUDA_ARCHITECTURES LESS 60)
    set(CMAKE_CUDA_ARCHITECTURES 60 70 75 80 86)
endif()

set(ROUTINE 3d_mgpu_c2c)

project(
    "${ROUTINE}_example"
    DESCRIPTION "GPU-Accelerated Fast Fourier Transforms"
    HOMEPAGE_URL "https://docs.nvidia.com/cuda/cufft/index.html"
    LANGUAGES CXX CUDA)

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
if (NOT CUFFT_EXAMPLES_INSTALL_PREFIX)
    set(CUFFT_EXAMPLES_INSTALL_PREFIX cufft_examples)
endif()

if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX ${CMAKE_BINARY_DIR} CACHE PATH "" FORCE)
endif()

add_executable(${ROUTINE}_example)

target_include_directories(${ROUTINE}_example
                           PRIVATE ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}
                           ${CMAKE_CURRENT_LIST_DIR}/../utils)

target_sources(${ROUTINE}_example
               PRIVATE ${PROJECT_SOURCE_DIR}/${ROUTINE}_example.cpp)

target_link_libraries(${ROUTINE}_example PRIVATE CUDA::cufft CUDA::cudart)

install(
    TARGETS ${ROUTINE}_example
    RUNTIME
    DESTINATION ${CUFFT_EXAMPLES_INSTALL_PREFIX}/bin
    PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ GROUP_EXECUTE GROUP_READ WORLD_EXECUTE WORLD_READ
)

if (NOT TARGET cufft_examples)
    add_custom_target(cufft_examples)
endif()

add_dependencies(cufft_examples ${ROUTINE}_example)
