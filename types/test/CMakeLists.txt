if(SISL_FOUND)
    list(APPEND OPTIONAL_TESTS
        test_Spline.cpp)
endif()

eds_testsuite(test_base_types test.cpp
    test_Angle.cpp
    test_Eigen.cpp
    test_RigidBodyStateSE3.cpp
    test_Temperature.cpp
    test_Time.cpp
    test_Timeout.cpp
    test_samples_Sonar.cpp
    ${OPTIONAL_TESTS}
    DEPS base-types)

