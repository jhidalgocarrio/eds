rock_testsuite(test_logging test.cpp
    DEPS base-logging)

rock_executable(benchmark_time_per_message benchmark_time_per_message.cpp
    NOINSTALL
    DEPS base-logging)
