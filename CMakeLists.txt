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
cmake_minimum_required(VERSION 3.18)

project("CUDA_Library_Samples"
        LANGUAGES    C CXX CUDA)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

# List of all known CUDA examples within the project.
# Exculed because of missed CMakeLists.txt file: cuFFTMp; cuSOLVERMp
set(CUDA_ALL_EXAMPLE_PROJECTS "cuBLAS;cuBLASLt;cuFFT;cuRAND;cuSOLVER;cuSPARSE;cuSPARSELt;cuTENSOR;cuTENSORMg;MathDx;NPP;nvJPEG;nvJPEG2000;nvTIFF")
# Specify 'all' examples by default.
set(CUDA_ENABLE_EXAMPLE_PROJECTS "all" CACHE STRING
    "Semicolon-separated list of projects to build (${CUDA_ALL_EXAMPLE_PROJECTS}), or \"all\".")

if (CUDA_ENABLE_EXAMPLE_PROJECTS STREQUAL "all" )
    set(CUDA_ENABLE_EXAMPLE_PROJECTS ${CUDA_ALL_EXAMPLE_PROJECTS})
endif()

macro(add_cuda_examples proj)
    set(_cuda_examples ${ARGN})
    if (_cuda_examples)
        foreach(dir ${_cuda_examples})
            message(STATUS "Adding CUDA example '${proj}::${dir}' ...")
            add_subdirectory("${proj}/${dir}")
        endforeach()
    else()
        message(STATUS "Adding CUDA example '${proj}' ...")
        add_subdirectory("${proj}")
    endif()
endmacro()

find_package(CUDAToolkit REQUIRED)

foreach(proj ${CUDA_ENABLE_EXAMPLE_PROJECTS})
    message(STATUS "Configuring CUDA example project '${proj}' ...")

    if (proj STREQUAL "cuBLAS")
        include(${proj}/cmake/cublas_example.cmake)

        if (NOT TARGET cublas-examples)
            add_custom_target(cublas-examples)
        endif()

        add_cuda_examples(${proj}
            Extensions/AxpyEx Extensions/Cherk3mEx Extensions/CherkEx Extensions/Csyrk3mEx Extensions/CsyrkEx
            Extensions/dgmm Extensions/DotEx Extensions/geam
            #TODO:VV:Extensions/GemmBatchedEx
            Extensions/GemmEx Extensions/GemmStridedBatchedEx Extensions/Nrm2Ex Extensions/RotEx
            Extensions/ScalEx Extensions/tpttr Extensions/trttp
            Level-1/amax Level-1/amin Level-1/asum Level-1/axpy Level-1/copy Level-1/dot Level-1/nrm2 Level-1/rot
            Level-1/rotg Level-1/rotm Level-1/rotmg Level-1/scal Level-1/swap
            Level-2/gbmv Level-2/gemv Level-2/ger Level-2/hbmv Level-2/hemv Level-2/her Level-2/her2 Level-2/hpmv
            Level-2/hpr Level-2/hpr2 Level-2/sbmv Level-2/spmv Level-2/spr Level-2/spr2 Level-2/symv Level-2/syr
            Level-2/syr2 Level-2/tbmv Level-2/tbsv Level-2/tpmv Level-2/tpsv Level-2/trmv Level-2/trsv
            Level-3/gemm Level-3/gemm3m Level-3/gemmBatched Level-3/gemmStridedBatched Level-3/hemm Level-3/her2k
            Level-3/herk Level-3/herkx Level-3/symm Level-3/syr2k Level-3/syrk Level-3/syrkx Level-3/trmm
            Level-3/trsm Level-3/trsmBatched
        )
    endif()

    if (proj STREQUAL "cuBLASLt")
        include(${proj}/cmake/cublaslt_example.cmake)

        if (NOT TARGET cublaslt-examples)
            add_custom_target(cublaslt-examples)
        endif()

        add_cuda_examples(${proj}
            LtSgemm
            LtDgemmPresetAlgo
            LtIgemmTensor
            LtHSHgemmStridedBatchSimple
            LtSgemmCustomFind
            LtPlanarComplex
            LtSgemmSimpleAutoTuning
        )
    endif()

    if (proj STREQUAL "cuFFT")
        if (NOT TARGET cufft-examples)
            add_custom_target(cufft-examples)
        endif()

        add_cuda_examples(${proj}
            1d_c2c 1d_mgpu_c2c 1d_r2c 2d_c2r 3d_c2c 3d_mgpu_c2c 3d_mgpu_r2c_c2r
        )
    endif()

    if (proj STREQUAL "cuRAND")
        if (NOT TARGET curand-examples)
            add_custom_target(curand-examples)
        endif()

        add_cuda_examples(${proj}
            Host/mrg32k3a Host/mt19937 Host/mtgp32 Host/philox
            Host/scrambled_sobol32 Host/scrambled_sobol64
            Host/sobol32 Host/sobol64 Host/xorwow
        )
    endif()

    if (proj STREQUAL "cuSOLVER")
        # cuSOLVER example helpers
        include(${proj}/cmake/cusolver_example.cmake)

        if (NOT TARGET cusolver-examples)
            add_custom_target(cusolver-examples)
        endif()

        add_cuda_examples(${proj}
            csrqr gesv gesvd gesvdaStridedBatched gesvdj gesvdjBatched getrf MgGetrf MgPotrf MgSyevd
            orgqr ormqr potrfBatched syevd syevdx syevj syevjBatched sygvd sygvdx sygvj
            Xgeqrf Xgesvd Xgesvdp Xgesvdr Xgetrf Xpotrf Xsyevd Xsyevdx Xtrtri
        )
    endif()

    if (proj STREQUAL "cuSPARSE")
        if (NOT TARGET cusparse-examples)
            add_custom_target(cusparse-examples)
        endif()

        add_cuda_examples(${proj}
            axpby bicgstab cg compression coosort dense2sparse_blockedell dense2sparse_csr
            gather gpsvInterleavedBatch graph_capture rot scatter sddmm_csr sddmm_csr_batched sparse2dense_csr
            spgemm spgemm_mem spgemm_reuse spmm_blockedell spmm_coo spmm_coo_batched
            spmm_csr spmm_csr_batched spmm_csr_op
            spmv_coo spmv_csr spsm_coo spsm_csr spsv_coo spsv_csr
        )
    endif()

    if (proj STREQUAL "cuSPARSELt")
        if (NOT TARGET cusparse-examples)
            add_custom_target(cusparse-examples)
        endif()

        add_cuda_examples(${proj}
            spmma
            spmma2
        )
    endif()

    if (proj STREQUAL "cuTENSOR" OR proj STREQUAL "cuTENSORMg")
        find_package(cuTENSOR REQUIRED)

        add_cuda_examples(${proj})
    endif()

    #NOTE: MSVC is not supported yet.
    if (NOT MSVC AND proj STREQUAL "MathDx")
        if (NOT TARGET mathdx-examples)
            add_custom_target(mathdx-examples)
        endif()

        add_cuda_examples(${proj}
            cuFFTDx/block_fft
            cuFFTDx/convolution
        )
    endif()

    if (proj STREQUAL "NPP")
        if (NOT TARGET npp-examples)
            add_custom_target(npp-examples)
        endif()

        add_cuda_examples(${proj}
            batchedLabelMarkersAndCompression
            distanceTransform
            findContour
            watershedSegmentation
        )
    endif()

    if (proj STREQUAL "nvJPEG")
        if (NOT nvjpeg-examples)
            add_custom_target(nvjpeg-examples)
        endif()

        add_cuda_examples(${proj}
            Image-Resize
            Image-Resize-WaterMark
            nvJPEG-Decoder
            nvJPEG-Decoder-Backend-ROI
            nvJPEG-Decoder-MultipleInstances
        )
    endif()

    if (proj STREQUAL "nvJPEG2000")
        find_package(nvJPEG2000 REQUIRED)

        if (NOT nvjpeg2000-examples)
            add_custom_target(nvjpeg2000-examples)
        endif()

        add_cuda_examples(${proj}
            nvJPEG2000-Decoder
            nvJPEG2000-Decoder-Pipelined
            nvJPEG2000-Decoder-Tile-Partial
            nvJPEG2000-Encoder
        )
    endif()

    if (proj STREQUAL "nvTIFF")
        if (NOT nvtiff-examples)
            add_custom_target(nvtiff-examples)
        endif()

        add_cuda_examples(${proj}
            nvTIFF-Decode-Encode
        )
    endif()


endforeach()

