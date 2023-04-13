# CMakeLists.txt has to be located in the project folder and cmake has to be
# executed from 'project/build' with 'cmake ../'.

cmake_minimum_required(VERSION 3.9)
project(frame_helper
        VERSION 1.0
        DESCRIPTION "Library for manipulating Rock Core image type")
find_package(EDS)
eds_init()

eds_opencv_autodetect(OPENCV_PACKAGE)
eds_standard_layout()
