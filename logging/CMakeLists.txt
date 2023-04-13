# CMakeLists.txt has to be located in the project folder and cmake has to be
# executed from 'project/build' with 'cmake ../'.
cmake_minimum_required(VERSION 3.9)
project(base-logging
        VERSION 1.0
        DESCRIPTION "Simple base Logging: similar to google logger")
find_package(EDS)
eds_init()

eds_standard_layout()
