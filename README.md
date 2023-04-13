
Event-aided Direct Sparse Odometry (EDS) [Standalone]
=============
Direct visual odometry approach using events and frames (CVPR 2022) This is an
standalone version of the orginal
[EDS]((https://github.com/uzh-rpg/eds-buildconf)

License
-------
See LICENSE file

Dependencies
-----------------
Dependencies are listed in the make.sh script:

```console
sudo apt install build-essential
sudo apt install cmake
sudo apt install libeigen3-dev
sudo apt install libboost-all-dev
sudo apt install libpcl-dev
sudo apt install libopencv-dev python3-opencv
sudo apt install libgoogle-glog-dev libgflags-dev
sudo apt install libatlas-base-dev
sudo apt install libsuitesparse-dev
```

Installation
------------

```console
git clone git@github.com:jhidalgocarrio/eds.git
cd eds
./make.sh all
```
### EDS Folder Structure

| directory         |       purpose                                                        |
| ----------------- | ------------------------------------------------------               |
| cmake             | EDS CMake macros                                                     |
| types             | EDS Base CXX types                                                   |
| logging           | Simple Logging similar to Google logger                              |
| frame_helper      | Helper to convert between EDS image types (frames)                   |
| jpeg_conversion   | Image JPEG helper library                                            |
| yaml_cpp          | YAML CXX library (used for config)                                   |
| ceres             | The ceres solver library                                             |
| lib               | The EDS C++ library                                                  |
| task              | Main EDS task class                                                  |
