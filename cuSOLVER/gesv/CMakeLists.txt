# 
# Copyright (c) 2019-2023, NVIDIA CORPORATION.  All rights reserved.
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

# ---[ Check cmake version.
cmake_minimum_required(VERSION 3.18.0 FATAL_ERROR)

set(ROUTINE gesv)
set(ProjectId "cusolver_${ROUTINE}_example")

# ---[ Project specification.
project(${ProjectId} LANGUAGES C CXX CUDA)

# cuSOLVER example helpers
include(../cmake/cusolver_example.cmake)

# Iterative refinement solver is added in CUDA 10.2
if(NOT CMAKE_CUDA_COMPILER_VERSION VERSION_LESS "10.2")
    add_cusolver_example("cusolver_irs_lapack" cusolver_irs_lapack.cu)
    if (CMAKE_CUDA_COMPILER_VERSION VERSION_GREATER_EQUAL "11.0")
        add_cusolver_example("cusolver_irs_expert" cusolver_irs_expert_cuda-11.cu)
    else()
        add_cusolver_example("cusolver_irs_expert" cusolver_irs_expert_cuda-10.2.cu)
    endif()
else()
    message("GESV solver routines are introduced in CUDA 10.2, update toolkit to get GESV functionality in cuSOLVER")
endif()
