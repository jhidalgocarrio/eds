eds_testsuite(test_suite
                 SOURCES test_suite.cpp
                 # DEPS_PKGCONFIG base-types opencv libv4lconvert libv4l2 jpeg_conversion
                 DEPS frame_helper
                 )
             #ADD_EXECUTABLE(frame_helper_testsuite test_suite.cpp)
             #TARGET_LINK_LIBRARIES(frame_helper_testsuite frame_helper ${Boost_UNIT_TEST_FRAMEWORK_LIBRARIES} ${Boost_SYSTEM_LIBRARIES} ${GSL_LIBRARIES} ${OPENCV_LIBRARIES} )

