#!/usr/bin/env bash

# Event-based Direct Sparse Odometry (EDS)
#
# Tested with Ubuntu 20.04
# You need to have install the following packages
# in you system (basically a build essential, boost
# pcl, opencv, eigen3 and ceres-solver dependencies):
#
# sudo apt install build-essential
# sudo apt install cmake
# sudo apt install libeigen3-dev
# sudo apt install libboost-all-dev
# sudo apt install libpcl-dev
# sudo apt install libopencv-dev python3-opencv
# sudo apt install libgoogle-glog-dev libgflags-dev
# sudo apt install libatlas-base-dev
# sudo apt install libsuitesparse-dev

# exit on first non-zero return code
#set -ex

# Variables and paths
EDS_ROOT_DIR=${PWD}
EDS_INSTALL_DIR=${EDS_ROOT_DIR}/install

# Colors for echo
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

if [ -z "$1" ]; then 
    echo -e "${BOLD}Usage:${NORMAL} ./make.sh [${GREEN}all${NC} | ${ORANGE}clean ${NC} | ${RED}mrproper${NC}]"
    exit
fi

if [ "$1" == "all" ]; then

    mkdir -p ${EDS_INSTALL_DIR}
    export PATH=${EDS_INSTALL_DIR}:$PATH
    export PKG_CONFIG_PATH=${EDS_INSTALL_DIR}/lib/pkgconfig
    BUILD_TYPE=Release
    echo "BUILD_TYPE ${BUILD_TYPE}"
    echo "EDS_ROOT DIR ${EDS_ROOT_DIR}"
    echo "EDS_INSTALL DIR ${EDS_INSTALL_DIR}"


    # Build each EDS module in the given order
    echo -e "${BLUE}* Building EDS CMake macros ${NC}"
    cd ${EDS_ROOT_DIR}/cmake
    mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${EDS_INSTALL_DIR} && make -j && make install
    echo -e "${GREEN}* Built cmake macros [OK] ${NC}"

    echo -e "${BLUE}* Building EDS Base Types ${NC}"
    cd ${EDS_ROOT_DIR}/types
    mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${EDS_INSTALL_DIR} && make -j && make install
    echo -e "${GREEN}* Built EDS Base Types [OK] ${NC}"

    echo -e "${BLUE}* Building Logging ${NC}"
    cd ${EDS_ROOT_DIR}/logging
    mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${EDS_INSTALL_DIR} && make -j && make install
    echo -e "${GREEN}* Built Logging [OK] ${NC}"

    echo -e "${BLUE}* Building JPEG conversion lib ${NC}"
    cd ${EDS_ROOT_DIR}/jpeg_conversion
    mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${EDS_INSTALL_DIR} && make -j && make install
    echo -e "${GREEN}* Built JPEG conversion lib [OK] ${NC}"

    echo -e "${BLUE}* Building Frame Helper ${NC}"
    cd ${EDS_ROOT_DIR}/frame_helper
    mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${EDS_INSTALL_DIR} && make -j && make install
    echo -e "${GREEN}* Built Frame Helper [OK] ${NC}"

    echo -e "${BLUE}* Building Ceres solver ${NC}"
    cd ${EDS_ROOT_DIR}/ceres
    mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${EDS_INSTALL_DIR} -DBUILD_SHARED_LIBS=ON -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF && make -j && make install
    echo -e "${GREEN}* Built Ceres solver [OK] ${NC}"

    echo -e "${BLUE}* Building EDS library ${NC}"
    cd ${EDS_ROOT_DIR}/lib
    mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${EDS_INSTALL_DIR} && make -j && make install
    echo -e "${GREEN}* Built EDS library [OK] ${NC}"

    echo -e "${BLUE}* Building yaml_cpp ${NC}"
    cd ${EDS_ROOT_DIR}/yaml_cpp
    mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${EDS_INSTALL_DIR} && make -j && make install
    echo -e "${GREEN}* Built yaml_cpp [OK] ${NC}"

    echo -e "${BLUE}* Building EDS Task ${NC}"
    cd ${EDS_ROOT_DIR}/task
    mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=${BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${EDS_INSTALL_DIR} && make -j && make install
    echo -e "${GREEN}* Built EDS Task[OK] ${NC}"

elif [ "$1" == "clean" ] || [ "$1" == "mrproper" ]; then

    echo -e "${BLUE}* Cleaning build folders ${NC}"
    rm -rf ${EDS_ROOT_DIR}/types/build
    rm -rf ${EDS_ROOT_DIR}/frame_helper/build
    rm -rf ${EDS_ROOT_DIR}/cmake/build
    rm -rf ${EDS_ROOT_DIR}/jpeg_conversion/build
    rm -rf ${EDS_ROOT_DIR}/ceres/build
    rm -rf ${EDS_ROOT_DIR}/logging/build
    rm -rf ${EDS_ROOT_DIR}/yaml_cpp/build
    rm -rf ${EDS_ROOT_DIR}/lib/build
    rm -rf ${EDS_ROOT_DIR}/task/build
    echo -e "${NC}* [OK]${NC}"

    if [ "$1" == "mrproper" ]; then

        echo -e "${BLUE}* Cleaning install folder ${NC}"
        rm -rf ${EDS_INSTALL_DIR}
        echo -e "${NC}* [OK]${NC}"

    fi

else
    echo -e "${BOLD}Usage:${NORMAL} ./make.sh [${GREEN}all${NC} | ${ORANGE}clean ${NC} | ${RED}mrproper${NC}]"
    exit
fi

