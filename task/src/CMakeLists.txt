# Generated from orogen/lib/orogen/templates/tasks/CMakeLists.txt


eds_library(${PROJECT_NAME}
    SOURCES Task.cpp
    HEADERS Task.hpp
            EDSTypes.hpp
    DEPS_PKGCONFIG
            base-types
            eds
            yaml-cpp
            frame_helper
)