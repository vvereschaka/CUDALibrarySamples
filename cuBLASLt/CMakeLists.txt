#
# Copyright (c) 2020, NVIDIA CORPORATION.  All rights reserved.
#
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto. Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.
#
cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

project("cuBLASLt_examples"
        LANGUAGES    CXX CUDA)

# Speed up configuration for the examples, find CUDAToolkit at first.
find_package(CUDAToolkit REQUIRED)

# cuBLASLt example helpers
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/cublaslt_example.cmake)

set(cuda_examples)
list(APPEND cuda_examples
    LtSgemm
    LtDgemmPresetAlgo
    LtIgemmTensor
    LtHSHgemmStridedBatchSimple
    LtSgemmCustomFind
    LtPlanarComplex
    LtSgemmSimpleAutoTuning
)

if (NOT TARGET cublaslt_examples)
    add_custom_target(cublaslt_examples)
endif()

foreach(dir ${cuda_examples})
    message(STATUS "Adding CUDA example '${PROJECT_NAME}::${dir}' ...")
    add_subdirectory(${dir})
endforeach()
