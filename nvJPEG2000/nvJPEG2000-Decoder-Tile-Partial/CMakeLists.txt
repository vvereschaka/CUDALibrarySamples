# 
# Copyright (c) 2021-2023, NVIDIA CORPORATION.  All rights reserved.
# 
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto. Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.
# 
cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

# ---[ Project specIFication.
set(PROJECT_NAME nvJPEG2000DecoderTilePartial)
project(${PROJECT_NAME} LANGUAGES CUDA CXX)

include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/common_example.cmake)

find_package(CUDAToolkit REQUIRED)
find_package(nvJPEG2000 REQUIRED)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_EXTENSIONS OFF)

if (UNIX)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
endif()

add_nvjpeg2000_example(nvjpeg2000_examples ${PROJECT_NAME} nvj2k_DecodeTilePartial.cpp)
