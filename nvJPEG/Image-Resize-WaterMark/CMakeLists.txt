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

# ---[ Project specIFication.
set(PROJECT_NAME imageResizeWatermark)
project(${PROJECT_NAME} LANGUAGES CUDA CXX)

include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/common_example.cmake)

# Global CXX flags/options
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Global CUDA CXX flags/options
set(CUDA_HOST_COMPILER ${CMAKE_CXX_COMPILER})
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_EXTENSIONS OFF)

add_nvjpeg_example(jpeg_examples "${PROJECT_NAME}" imageResizeWatermark.cpp)
