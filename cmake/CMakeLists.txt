cmake_minimum_required(VERSION 3.9)
project(cmake VERSION 1.0 DESCRIPTION "EDS' core CMake macros")
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/modules")
include(${CMAKE_CURRENT_SOURCE_DIR}/modules/EDS.cmake)
eds_init()

install(FILES
    modules/FindBoost.cmake
    modules/FindGem.cmake
    modules/FindNumpy.cmake
    modules/FindRuby.cmake
    modules/FindSISL.cmake
    modules/ListMacros.cmake
    modules/PythonBind.cmake
    modules/PythonInstallPath.cmake
    modules/EDS.cmake
    modules/EDSRuby.cmake
    modules/eds-config.cmake
    DESTINATION share/eds/cmake)

