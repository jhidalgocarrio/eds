#define BOOST_TEST_MODULE BaseTypes
#include <boost/test/unit_test.hpp>

#define BASE_LOG_DEBUG
#include <base-logging/Logging.hpp>

// Boost::Test fails the test suite if there are no tests defined
//
// Define one dummy test case until a brave soul actually writes a proper test
// suite
BOOST_AUTO_TEST_CASE(dummy_test_to_pass) {
}
