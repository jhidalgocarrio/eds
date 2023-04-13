# base-logging

This is a header only library provides functionality to embed logging into your C++ project.
The logger allows you to log either in a printf-style or stream-style. For that purpose include it where needed and preferably in the .cpp files to avoid warnings about an undefined namespace for the logging.

```
#include<base-logging/Logging.hpp>

...
// printf-style logging
std::string information("test-logging happening here");
LOG_DEBUG("I provide you the following debug information: %s", 
    information.c_str());
LOG_INFO(...);
LOG_WARN(...);
LOG_ERROR(..);
LOG_FATAL(..);

// stream-style logging
LOG_DEBUG_S << information;
LOG_INFO_S << information;
...
LOG_FATAL << information;
```

The default output format of a log message looks like the following (without linebreak):
```
[20120120-11:58:00:577] [FATAL] - test_logger::A fatal error 
occurred (/tmp/test_logger/src/Main.cpp:10 - int main(int, char**))
```

## Configuring the base logger

The logger can be configured at compile time to remove unwanted logging statement in a release version, and at runtime to control the verbosity level and logging format.

### Compile time

The following defines can be set to configure the logger at compile time:

**BASE_LOG_NAMESPACE** Setting the namespace to a unique string that allows you to filter the logging output, e.g. ROCK Macros automatically set it to the package name

**BASE_LOG_DISABLE** Deactivate all logging statements, e.g. for a realease binary.

**BASE_LOG_xxx** Compile only logs equal or higher than a certain level xxx into your binary, i.e. BASE_LOG_WARN disable all logs except for WARN, ERROR and FATAL Settings of log levels via environment variables with then only apply to the still activated levels.

**BASE_LONG_NAMES** Set this define in order to enforce a BASE_ prefix for the logging Macros, to avoid clashes with other libraries, i.e. BASE_LOG_DEBUG(…)

### At run-time

The following enviroment variables can be used to control the behaviour of the logger:
**BASE_LOG_LEVEL** Set to one of DEBUG, INFO, WARN, ERROR or FATAL to define the maximum logging level, e.g. export BASE_LOG_LEVEL=”DEBUG”

**BASE_LOG_COLOR** Activate colored logging (current configuration best for dark background coloured terminals), e.g. export BASE_LOG_COLOR

**BASE_LOG_FORMAT** Select from a set of predefined logging formats: DEFAULT, MULTILINE, SHORT, example outputs are given below: 

The DEFAULT format contains no linebreaks (here only due to fit the narrow presentation):

```
[20120120-11:58:00:577] [FATAL] - test_logger::A fatal error 
occurred (/tmp/test_logger/src/Main.cpp:10 - int main(int, char**))
```

The SHORT format reduces information to the log priority and the message:

```
[20120120-11:58:00:577] [FATAL] - test_logger::A fatal error 
occurred (/tmp/test_logger/src/Main.cpp:10 - int main(int, char**))
```
The MULTILINE format split each individual log message across a minimum of three lines:
```
[20120120-11:58:59:976] in int main(int, char**)
        /tmp/test_logger/src/Main.cpp:10
        [FATAL] - test_logger::A fatal error occurred
```


Installation
------------
The easiest way to build and install this package is to use Rock's build system.
See [this page](http://rock-robotics.org/stable/documentation/installation.html)
on how to install Rock.

However, if you feel that it's too heavy for your needs, Rock aims at having
most of its "library" packages (such as this one) to follow best practices. See
[this page](http://rock-robotics.org/stable/documentation/packages/outside_of_rock.html)
for installation instructions outside of Rock.

Dependencies
-----------------

This package uses a set of CMake helper shipped as the Rock CMake macros.
Documentations is available on [this page](http://rock-robotics.org/stable/documentation/packages/cmake_macros.html).


## Merge Requests and Issue Tracking

Github will be used for pull requests and issue tracking: https://github.com/rock-core/base-logging/

## License
This software source are licensed under the New/3-clause BSD license

## Copyright
(c) Copyright 2016-2018 DFKI GmbH Robotics Innovation Center
