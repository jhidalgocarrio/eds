# CMakeLists.txt has to be located in the project folder and cmake has to be
# executed from 'project/build' with 'cmake ../'.

cmake_minimum_required(VERSION 3.9)
project(jpeg_conversion
        VERSION 1.0
        DESCRIPTION "jpeg conversion helper library")
find_package(EDS)
eds_init()

eds_standard_layout()

