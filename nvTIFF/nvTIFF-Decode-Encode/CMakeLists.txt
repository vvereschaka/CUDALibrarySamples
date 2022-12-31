# 
# Copyright (c) 2020 - 2021, NVIDIA CORPORATION.  All rights reserved.
# 
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto. Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.
# 
cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

# ---[ Project specIFication.
set(PROJECT_NAME nvTIFFDecodeEncode)
project(${PROJECT_NAME} LANGUAGES CUDA CXX)

include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/common_example.cmake)

# Find nvTIFF lirary
if(NOT DEFINED NVTIFF_PATH)
    message(FATAL_ERROR "NVTIFF_PATH not set")
endif()

message(STATUS "Looking for nvTIFF in ${NVTIFF_PATH}")

find_file(NVTIFF_INCLUDE_FILE
    NAMES nvTiff.h
    PATHS "${NVTIFF_PATH}/include"
    NO_DEFAULT_PATH
)

if (NOT NVTIFF_INCLUDE_FILE)
    message(FATAL_ERROR "Could not find nvTIFF in path specified by NVTIFF_PATH=${NVTIFF_PATH}")
endif()

set(NVTIFF_ROOT_DIR ${NVTIFF_PATH})
set(NVTIFF_INCLUDE_DIR "${NVTIFF_PATH}/include")

find_library(CUDA_nvtiff_LIBRARY
    NAMES nvtiff
    HINTS ${NVTIFF_ROOT_DIR}
    PATH_SUFFIXES lib64 lib
)
if (WIN32)
    find_file(CUDA_nvtiff_0_dll_LIBRARY
        NAMES nvtiff_0.dll
        PATHS ${NVTIFF_ROOT_DIR}
        PATH_SUFFIXES lib64 lib
        NO_DEFAULT_PATH
    )
endif()

if (CUDA_nvtiff_LIBRARY)
    get_filename_component(NVTIFF_LIBRARY_DIR ${CUDA_nvtiff_LIBRARY} DIRECTORY ABSOLUTE)
    get_filename_component(NVTIFF_LIBRARY_NAME ${CUDA_nvtiff_LIBRARY} NAME)
    message(STATUS "Found CUDA::nvtiff")
    add_library(CUDA::nvtiff SHARED IMPORTED)
    target_include_directories(CUDA::nvtiff SYSTEM INTERFACE "${NVTIFF_INCLUDE_DIR}")
    target_link_directories(CUDA::nvtiff INTERFACE "${NVTIFF_LIBRARY_DIR}")
    set_target_properties(CUDA::nvtiff
        PROPERTIES
            IMPORTED_LOCATION "${CUDA_nvtiff_LIBRARY}"
            INTERFACE_LINK_LIBRARIES "${NVTIFF_LIBRARY_NAME}"
    )
    if (CUDA_nvtiff_0_dll_LIBRARY)
        set_target_properties(CUDA::nvtiff
            PROPERTIES
                IMPORTED_LOCATION ${CUDA_nvtiff_0_dll_LIBRARY}
                IMPORTED_IMPLIB "${CUDA_nvtiff_LIBRARY}"
                INTERFACE_LINK_LIBRARIES "${NVTIFF_LIBRARY_NAME}"
        )
    endif()
endif()

# c++14 is requiered for stdc++fs
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_CUDA_STANDARD 14)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_EXTENSIONS OFF)

if (UNIX)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
endif()

add_nvtiff_example(nvtiff_examples ${PROJECT_NAME} "nvtiff_example.cu;nvTiff_utils.cpp")
