
if (NOT CUDAToolkit_FOUND)
    find_package(CUDAToolkit 10.1 REQUIRED)
endif()

unset(CUTENSOR_INCLUDE_FILE CACHE)
unset(CUTENSOR_ROOT_DIR CACHE)
unset(CUTENSOR_INCLUDE_DIR CACHE)
unset(CUTENSOR_LIB_DIR CACHE)

if (DEFINED CUTENSOR_ROOT OR DEFINED ENV{CUTENSOR_ROOT})
    if (DEFINED CUTENSOR_ROOT)
        set(_CUTENSOR_ROOT_DIR ${CUTENSOR_ROOT})
    else()
        set(_CUTENSOR_ROOT_DIR $ENV{CUTENSOR_ROOT})
    endif()

    message(STATUS "Looking for cuTENSOR in ${_CUTENSOR_ROOT_DIR}")

    find_file(CUTENSOR_INCLUDE_FILE
        NAMES cutensor.h
        PATHS "${_CUTENSOR_ROOT_DIR}/include"
        NO_DEFAULT_PATH
    )

    if (NOT CUTENSOR_INCLUDE_FILE)
        message(WARNING "Could not find cuTENSOR in path specified by CUTENSOR_ROOT=${_CUTENSOR_ROOT_DIR}")
    else()
        set(CUTENSOR_ROOT_DIR ${_CUTENSOR_ROOT_DIR})
        set(CUTENSOR_INCLUDE_DIR "${_CUTENSOR_ROOT_DIR}/include")
    endif()
    unset(_CUTENSOR_ROOT_DIR)
endif()

# try platform defaults.
if (NOT CUTENSOR_ROOT_DIR)
    # - Linux: /usr/lib/*/libcutensor   (/usr/lib/x86_64-linux-gnu/libcutensor)
    # - Windows: C:\Program Files\NVIDIA cuTENSOR\vX.Y
    if(WIN32)
        set(platform_base "C:/Program Files/NVIDIA cuTENSOR/v")

        # Build out a descending list of possible cuda installations, e.g.
        file(GLOB possible_paths "${platform_base}*")
        # Iterate the glob results and create a descending list.
        set(versions)
        foreach(p ${possible_paths})
            # Extract version number from end of string
            string(REGEX MATCH "[0-9][0-9]?\\.[0-9]$" p_version ${p})
            if(IS_DIRECTORY ${p} AND p_version)
                list(APPEND versions ${p_version})
            endif()
        endforeach()

        # Sort numerically in descending order, so we try the newest versions first.
        list(SORT versions COMPARE NATURAL ORDER DESCENDING)

        # With a descending list of versions, populate possible paths to search.
        set(search_paths)
        foreach(v ${versions})
            find_file(CUTENSOR_INCLUDE_FILE
                NAMES cutensor.h
                PATHS "${platform_base}${v}/include"
                NO_DEFAULT_PATH
            )
            if (CUTENSOR_INCLUDE_FILE)
                set(CUTENSOR_ROOT_DIR "${platform_base}${v}")
                set(CUTENSOR_INCLUDE_DIR "${platform_base}${v}/include")
                break()
            endif()
        endforeach()

        # We are done with these variables now, cleanup for caller.
        unset(platform_base)
        unset(possible_paths)
        unset(versions)
        unset(search_paths)
    elseif(UNIX)
        if (NOT APPLE)
            find_file(CUTENSOR_INCLUDE_FILE
                NAMES cutensor.h
                PATHS "/usr/include"
                NO_DEFAULT_PATH
            )
            if (CUTENSOR_INCLUDE_FILE)
                set(CUTENSOR_ROOT_DIR "/usr")
                set(CUTENSOR_INCLUDE_DIR "/usr/include")
            endif()
        endif()
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(cuTENSOR
  REQUIRED_VARS
    CUTENSOR_ROOT_DIR
    CUTENSOR_INCLUDE_DIR
)
mark_as_advanced(CUTENSOR_INCLUDE_DIR)

if (cuTENSOR_FOUND)
    if (WIN32)
        set(lib_search_suffix_prefix "lib")
    else()
        set(lib_search_suffix_prefix "libcutensor")
    endif()

    # The path suffix for cuTENSOR libraries.
    if (CUDAToolkit_VERSION VERSION_LESS 11.0)
        set(LIB_DIR_SUFFIX "${lib_search_suffix_prefix}/10.2")
    elseif (CUDAToolkit_VERSION VERSION_EQUAL 11.0)
        set(LIB_DIR_SUFFIX "${lib_search_suffix_prefix}/11.0")
    elseif (CUDAToolkit_VERSION VERSION_GREATER_EQUAL 11.1 AND CUDAToolkit_VERSION VERSION_LESS 12.0)
        set(LIB_DIR_SUFFIX "${lib_search_suffix_prefix}/11")
    else()
        set(LIB_DIR_SUFFIX "${lib_search_suffix_prefix}/12")
    endif()

    unset(lib_search_suffix_prefix)

    # Find all cuTENSOR libraries.
    set(cutensor_lib_names "cutensor;cutensor_static;cutensorMg;cutensorMg_static")
    foreach (lib_name ${cutensor_lib_names})
        if(NOT TARGET CUDA::${lib_name})
            find_library(CUDA_${lib_name}_LIBRARY
                NAMES ${lib_name}
                HINTS ${CUTENSOR_ROOT_DIR}
                PATH_SUFFIXES ${LIB_DIR_SUFFIX}
            )
            mark_as_advanced(CUDA_${lib_name}_LIBRARY)

            if (CUDA_${lib_name}_LIBRARY)
                mark_as_advanced(CUDA_${lib_name}_LIBRARY)

                if (NOT CUTENSOR_LIBRARY_DIR)
                    get_filename_component(CUTENSOR_LIBRARY_DIR ${CUDA_${lib_name}_LIBRARY} DIRECTORY ABSOLUTE)
                    mark_as_advanced(CUTENSOR_LIBRARY_DIR)
                endif()

                message(STATUS "Found CUDA::${lib_name}")
                add_library(CUDA::${lib_name} UNKNOWN IMPORTED)
                target_include_directories(CUDA::${lib_name} SYSTEM INTERFACE "${CUTENSOR_INCLUDE_DIR}")
                target_link_directories(CUDA::${lib_name} INTERFACE "${CUTENSOR_LIBRARY_DIR}")
                set_property(TARGET CUDA::${lib_name} PROPERTY IMPORTED_LOCATION "${CUDA_${lib_name}_LIBRARY}")
            endif()
        endif()
    endforeach()
endif()
