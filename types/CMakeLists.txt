cmake_minimum_required(VERSION 3.8)
project(base VERSION 1.0 DESCRIPTION "EDS types")
cmake_policy(SET CMP0057 NEW)

find_package(EDS)
eds_init()

set(CMAKE_CXX_STANDARD 11)

# eds_export_includedir(${PROJECT_SOURCE_DIR}/base ${PROJECT_NAME})
eds_export_includedir(${PROJECT_SOURCE_DIR}/src base/geometry)
include_directories(BEFORE ${PROJECT_SOURCE_DIR})

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/DownloadBoost.cmake)

if (INSTALL_BOOST_IF_REQUIRED)
    eds_find_cmake(Boost)

    if (NOT Boost_FOUND)
        # download and install boost header only
        download_boost_if_needed()
        include_directories(${CMAKE_CURRENT_SOURCE_DIR}/external/${BOOST_SUBDIRECTORY})
        install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/external/${BOOST_SUBDIRECTORY}/boost
            DESTINATION include)
    endif()

else()
    eds_find_cmake(Boost COMPONENTS system REQUIRED)
endif()

eds_find_pkgconfig(Eigen3 eigen3 REQUIRED)

# For forward compatibility. Test was a toplevel target
if (EXISTS ${CMAKE_CURRENT_BINARY_DIR}/test)
    if (NOT IS_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/test)
        FILE(REMOVE ${CMAKE_CURRENT_BINARY_DIR}/test)
    endif()
endif()

# SISL as optional dependency
option(USE_SISL "set to OFF to disable the usage of SISL." OFF)
if(USE_SISL)
    eds_find_cmake(SISL)
    if(NOT SISL_FOUND)
        message(FATAL_ERROR "The usage of SISL is requested, but the library could not be found."
            " Either make sure SISL is installed, or disable the usage via"
            " -DUSE_SISL=OFF")
    endif(NOT SISL_FOUND)
endif()

eds_standard_layout()
