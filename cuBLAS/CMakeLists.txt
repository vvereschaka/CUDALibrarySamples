# Copyright 2023 NVIDIA Corporation.  All rights reserved.
#
# NOTICE TO LICENSEE:
#
# This source code and/or documentation ("Licensed Deliverables") are
# subject to NVIDIA intellectual property rights under U.S. and
# international Copyright laws.
#
# These Licensed Deliverables contained herein is PROPRIETARY and
# CONFIDENTIAL to NVIDIA and is being provided under the terms and
# conditions of a form of NVIDIA software license agreement by and
# between NVIDIA and Licensee ("License Agreement") or electronically
# accepted by Licensee.  Notwithstanding any terms or conditions to
# the contrary in the License Agreement, reproduction or disclosure
# of the Licensed Deliverables to any third party without the express
# written consent of NVIDIA is prohibited.
#
# NOTWITHSTANDING ANY TERMS OR CONDITIONS TO THE CONTRARY IN THE
# LICENSE AGREEMENT, NVIDIA MAKES NO REPRESENTATION ABOUT THE
# SUITABILITY OF THESE LICENSED DELIVERABLES FOR ANY PURPOSE.  IT IS
# PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY OF ANY KIND.
# NVIDIA DISCLAIMS ALL WARRANTIES WITH REGARD TO THESE LICENSED
# DELIVERABLES, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY,
# NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE.
# NOTWITHSTANDING ANY TERMS OR CONDITIONS TO THE CONTRARY IN THE
# LICENSE AGREEMENT, IN NO EVENT SHALL NVIDIA BE LIABLE FOR ANY
# SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, OR ANY
# DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
# WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
# ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
# OF THESE LICENSED DELIVERABLES.
#
# U.S. Government End Users.  These Licensed Deliverables are a
# "commercial item" as that term is defined at 48 C.F.R. 2.101 (OCT
# 1995), consisting of "commercial computer software" and "commercial
# computer software documentation" as such terms are used in 48
# C.F.R. 12.212 (SEPT 1995) and is provided to the U.S. Government
# only as a commercial end item.  Consistent with 48 C.F.R.12.212 and
# 48 C.F.R. 227.7202-1 through 227.7202-4 (JUNE 1995), all
# U.S. Government End Users acquire the Licensed Deliverables with
# only those rights set forth herein.
#
# Any use of the Licensed Deliverables in individual and commercial
# software must include, in the user documentation and internal
# comments to the code, the above Disclaimer and U.S. Government End
# Users Notice.
cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

project("cuBLAS_examples" 
        LANGUAGES    C CXX CUDA)

# Speed up configuration for the examples, find CUDAToolkit at first.
find_package(CUDAToolkit REQUIRED)

# cuSOLVER example helpers
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/cublas_example.cmake)

set(cuda_examples)
list(APPEND cuda_examples 
    Extensions/AxpyEx
    Extensions/Cherk3mEx
    Extensions/CherkEx
    Extensions/Csyrk3mEx
    Extensions/CsyrkEx
    Extensions/dgmm
    Extensions/DotEx
    Extensions/geam
    Extensions/GemmBatchedEx
    Extensions/GemmEx
    Extensions/GemmStridedBatchedEx
    Extensions/Nrm2Ex
    Extensions/RotEx
    Extensions/ScalEx
    Extensions/tpttr
    Extensions/trttp
    Level-1/amax
    Level-1/amin
    Level-1/asum
    Level-1/axpy
    Level-1/copy
    Level-1/dot
    Level-1/nrm2
    Level-1/rot
    Level-1/rotg
    Level-1/rotm
    Level-1/rotmg
    Level-1/scal
    Level-1/swap
    Level-2/gbmv
    Level-2/gemv
    Level-2/ger
    Level-2/hbmv
    Level-2/hemv
    Level-2/her
    Level-2/her2
    Level-2/hpmv
    Level-2/hpr
    Level-2/hpr2
    Level-2/sbmv
    Level-2/spmv
    Level-2/spr
    Level-2/spr2
    Level-2/symv
    Level-2/syr
    Level-2/syr2
    Level-2/tbmv
    Level-2/tbsv
    Level-2/tpmv
    Level-2/tpsv
    Level-2/trmv
    Level-2/trsv
    Level-3/gemm
    Level-3/gemm3m
    Level-3/gemmBatched
    Level-3/gemmStridedBatched
    Level-3/hemm
    Level-3/her2k
    Level-3/herk
    Level-3/herkx
    Level-3/symm
    Level-3/syr2k
    Level-3/syrk
    Level-3/syrkx
    Level-3/trmm
    Level-3/trsm
    Level-3/trsmBatched
)

if (NOT TARGET cublas_examples)
    add_custom_target(cublas_examples)
endif()

foreach(dir ${cuda_examples})
    message(STATUS "Adding CUDA example '${PROJECT_NAME}::${dir}' ...")
    add_subdirectory(${dir})
endforeach()
