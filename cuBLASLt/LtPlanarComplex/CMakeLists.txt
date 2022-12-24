# 
# Copyright (c) 2020, NVIDIA CORPORATION.  All rights reserved.
# 
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto. Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.
# 

# ---[ Check cmake version.
cmake_minimum_required(VERSION 3.18.0 FATAL_ERROR)

# ---[ Routine name
set(ROUTINE LtPlanarComplex)
set(ProjectId "cublaslt_${ROUTINE}_example")

# ---[ Project specification.
project("${ProjectId}" LANGUAGES CXX CUDA)

# cuBLASLt example helpers.
include(../cmake/cublaslt_example.cmake)

add_cublaslt_example("${ProjectId}" SOURCES main.cpp sample_cublasLt_${ROUTINE}.cu)
