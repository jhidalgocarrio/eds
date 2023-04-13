# Compile all targets with C++11 enabled.
#
# By default, this exports the corresponding compile flags to the target's
# pkg-config file.
#
# When using CMake 3.1 or later, it is recommended to use CMake's own mechanism
# instead of this macro, e.g.
#
#   set(CMAKE_CXX_STANDARD 11)
#   set(CMAKE_CXX_STANDARD_REQUIRED ON)
#
# The setting will be picked up by the eds targets, and you may decide to use
# other standards as e.g. C++14 this way.
#
# The EDS_PUBLIC_CXX_STANDARD variable allows to override this behaviour. It
# sets the standard that is exported in the .pc file, but does not change how the
# standard is handled internally in the package. It is meant as a way to use
# C++11 internally but have C++98 headers (and avoid propagating the C++11
# choice downstream).
#
# For instance,
#   set(CMAKE_CXX_STANDARD 11)
#   set(EDS_PUBLIC_CXX_STANDARD 98)
#   set(CMAKE_CXX_STANDARD_REQUIRED ON)
#
# Will build the package using C++11 but export -std=c++98 in the pkg-config
# file. Set the variable to empty to avoid exporting any -std flag in the
# pkgconfig file, e.g.:
#   set(EDS_PUBLIC_CXX_STANDARD "")
#
macro(eds_activate_cxx11)
    set(CMAKE_CXX_EXTENSIONS OFF)
    set(CMAKE_CXX_STANDARD 11)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)

    if (CMAKE_VERSION VERSION_LESS "3.1")
        CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
        CHECK_CXX_COMPILER_FLAG("-std=c++0x" COMPILER_SUPPORTS_CXX0X)
        if(COMPILER_SUPPORTS_CXX11)
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
        elseif(COMPILER_SUPPORTS_CXX0X)
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
        else()
            message(FATAL_ERROR "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
        endif()
    endif()
endmacro()


macro(eds_use_full_rpath install_rpath)
    # use, i.e. don't skip the full RPATH for the build tree
    SET(CMAKE_SKIP_BUILD_RPATH  FALSE)

    # when building, don't use the install RPATH already
    # (but later on when installing)
    SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)

    # the RPATH to be used when installing
    SET(CMAKE_INSTALL_RPATH ${install_rpath})

    # add the automatically determined parts of the RPATH
    # which point to directories outside the build tree to the insgall RPATH
    SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

    if(APPLE)
        SET(CMAKE_INSTALL_NAME_DIR ${install_rpath})
        Set(CMAKE_MACOSX_RPATH ON)
    endif(APPLE)

    #do not add if system directory
    list(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES "${install_rpath}" isSystemDir)
    if("${isSystemDir}" STREQUAL "-1")
        set(CMAKE_INSTALL_RPATH "${install_rpath}")
    endif()
endmacro()

function(eds_add_compiler_flag_if_it_exists FLAG)
    string(REGEX REPLACE "[^a-zA-Z]"
        "_" VAR_SUFFIX
        "${FLAG}")
    CHECK_CXX_COMPILER_FLAG(${FLAG} CXX_SUPPORTS${VAR_SUFFIX})
    if (CXX_SUPPORTS${VAR_SUFFIX})
        add_definitions(${FLAG})
    endif()
endfunction()

macro(eds_add_target_properties _target _name)
    get_target_property(_properties ${_target} ${_name})
    if(NOT _properties)
        set(_properties ${ARGN})
    else()
        list(APPEND _properties ${ARGN})
    endif()
    string (REPLACE ";" " " _new_properties "${_properties}")
    set_target_properties(${_target} PROPERTIES ${_name} "${_new_properties}")
endmacro()

function(eds_add_compiler_flag_to_target_if_it_exists EDS_TARGET FLAG)
    string(REGEX REPLACE "[^a-zA-Z]"
        "_" VAR_SUFFIX
        "${FLAG}")
    CHECK_CXX_COMPILER_FLAG(${FLAG} CXX_SUPPORTS${VAR_SUFFIX})
    if (CXX_SUPPORTS${VAR_SUFFIX})
        eds_add_target_properties(${EDS_TARGET}
                                   COMPILE_FLAGS ${FLAG})
    endif()
endfunction()


## Main initialization for EDS CMake projects
macro (eds_init)
    if (${ARGC} GREATER 0)
        message(WARNING "Passing project name and version to eds_init was a misfeature \
of EDS' macros since CMake 3.0. You must call CMake's project() \
at toplevel, like this:\
\nproject(${ARGV0} VERSION ${ARGV1} DESCRIPTION \"project description\")\
\nRemove the arguments to eds_init() to silence this warning")
        project(${ARGV0})
        set(PROJECT_VERSION ${ARGV1})
    endif()

    eds_use_full_rpath("${CMAKE_INSTALL_PREFIX}/lib")
    include(CheckCXXCompilerFlag)
    include(FindPkgConfig)
    if(EDS_USE_CXX11)
        eds_activate_cxx11()
    endif()
    eds_add_compiler_flag_if_it_exists(-Wall)
    eds_add_compiler_flag_if_it_exists(-Wno-unused-local-typedefs)
    add_definitions(-DBASE_LOG_NAMESPACE=${PROJECT_NAME})

    if (EDS_TEST_ENABLED)
        enable_testing()
    endif()
endmacro()

macro(eds_exported_includedir_root VAR DIR TARGET_DIR)
    if("${ARGC}" EQUAL 4)
        set(TARGET_INCLUDE_DIR ${ARGV3})
    else()
        string(REGEX REPLACE / "-" TARGET_INCLUDE_DIR ${TARGET_DIR})
    endif()

    set(${VAR} ${PROJECT_BINARY_DIR}/include/_${TARGET_INCLUDE_DIR}_)
endmacro()

# Allow for a global include dir schema by creating symlinks into the source directory
# Manipulation of the source directory is prevented using individual export
# directories (e.g. to prevent creating files within already symlinked directories)
function(eds_export_includedir DIR TARGET_DIR)
    eds_exported_includedir_root(_EDS_ADD_INCLUDE_DIR ${ARGV})
    set(_EDS_EXPORT_INCLUDE_DIR ${_EDS_ADD_INCLUDE_DIR}/${TARGET_DIR})
    if(NOT EXISTS ${_EDS_EXPORT_INCLUDE_DIR})
        # Get the subdir of the export path
        get_filename_component(_EDS_EXPORT_INCLUDE_SUBDIR ${_EDS_EXPORT_INCLUDE_DIR} PATH)

        # Making sure we create all required parent directories
        file(MAKE_DIRECTORY ${_EDS_EXPORT_INCLUDE_SUBDIR})
        if(WIN32)
            execute_process(COMMAND cmake -E copy_directory ${DIR} ${_EDS_EXPORT_INCLUDE_DIR})
        else()
            execute_process(COMMAND cmake -E create_symlink ${DIR} ${_EDS_EXPORT_INCLUDE_DIR})
        endif()

        if(NOT EXISTS ${_EDS_EXPORT_INCLUDE_DIR})
            message(FATAL_ERROR "Export include dir '${DIR}' to '${_EDS_EXPORT_INCLUDE_DIR}' failed")
        endif()
    else()
        message(STATUS "Export include dir: '${_EDS_EXPORT_INCLUDE_DIR}' already exists")
    endif()

    include_directories(BEFORE ${_EDS_ADD_INCLUDE_DIR})
endfunction()

function(eds_add_source_dir DIR TARGET_DIR)
    if(IS_ABSOLUTE ${DIR})
        eds_export_includedir(${DIR} ${TARGET_DIR})
    else()
        eds_export_includedir(${CMAKE_CURRENT_SOURCE_DIR}/${DIR} ${TARGET_DIR})
    endif()
    add_subdirectory(${DIR})
endfunction()

function(eds_add_dummy_target_dependency TARGET)
    if (NOT TARGET ${TARGET})
        add_custom_target(${TARGET})
    endif()
    add_dependencies(${TARGET} ${ARGN})
endfunction()

macro(eds_doxygen)
    find_package(Doxygen)
    if (DOXYGEN_FOUND)
        if (DOXYGEN_DOT_EXECUTABLE)
            SET(DOXYGEN_DOT_FOUND YES)
        elSE(DOXYGEN_DOT_EXECUTABLE)
            SET(DOXYGEN_DOT_FOUND NO)
            SET(DOXYGEN_DOT_EXECUTABLE "")
        endif(DOXYGEN_DOT_EXECUTABLE)
        configure_file(Doxyfile.in Doxyfile @ONLY)
        add_custom_target(cxx-doc doxygen Doxyfile)
        eds_add_dummy_target_dependency(doc cxx-doc)
    endif(DOXYGEN_FOUND)
endmacro()

macro(eds_standard_layout)
    if (EXISTS ${PROJECT_SOURCE_DIR}/Doxyfile.in)
        eds_doxygen()
    endif()

    if(IS_DIRECTORY ${PROJECT_SOURCE_DIR}/src)
        eds_add_source_dir(src ${PROJECT_NAME})
    endif()

    # Test for known types of EDS subprojects
    if(IS_DIRECTORY ${PROJECT_SOURCE_DIR}/viz)
        option(EDS_VIZ_ENABLED "set to OFF to disable the visualization plugin. Visualization plugins are automatically disabled if EDS' vizkit3d is not available" ON)
        if (EDS_VIZ_ENABLED)
            if ("${PROJECT_NAME}" STREQUAL vizkit3d)
                add_subdirectory(viz)
            else()
                eds_find_pkgconfig(vizkit3d vizkit3d)
                if (vizkit3d_FOUND)
                    message(STATUS "vizkit3d found ... building the vizkit3d plugin")
                    eds_add_source_dir(viz vizkit3d)
                else()
                    message(STATUS "vizkit3d not found ... NOT building the vizkit3d plugin")
                endif()
            endif()
        else()
            message(STATUS "visualization plugins disabled as EDS_VIZ_ENABLED is set to OFF")
        endif()
    endif()

    if (IS_DIRECTORY ${PROJECT_SOURCE_DIR}/ruby)
        if (EXISTS ${PROJECT_SOURCE_DIR}/ruby/CMakeLists.txt)
            include(EDSRuby)
            if (RUBY_FOUND)
                add_subdirectory(ruby)
            endif()
        endif()
    endif()

    if (IS_DIRECTORY ${PROJECT_SOURCE_DIR}/bindings/ruby)
        if (EXISTS ${PROJECT_SOURCE_DIR}/bindings/ruby/CMakeLists.txt)
            option(BINDINGS_RUBY "install this package's Ruby bindings" ON)
            include(EDSRuby)
            if (BINDINGS_RUBY)
                if (RUBY_FOUND)
                    add_subdirectory(bindings/ruby)
                else()
                    message(FATAL_ERROR "this package has Ruby bindings but Ruby cannot be found. Set BINDINGS_RUBY to OFF (e.g.  -DBINDINGS_RUBY=OFF to avoid installing the bindings")
                endif()
            endif()
        endif()
    endif()

    if (IS_DIRECTORY ${PROJECT_SOURCE_DIR}/bindings/python)
        if (EXISTS ${PROJECT_SOURCE_DIR}/bindings/python/CMakeLists.txt)
            option(BINDINGS_PYTHON "install this package's Python bindings" ON)
            if(BINDINGS_PYTHON)
                add_subdirectory(bindings/python)
            endif()
        endif()
    endif()

    if (IS_DIRECTORY ${PROJECT_SOURCE_DIR}/configuration)
        install(DIRECTORY ${PROJECT_SOURCE_DIR}/configuration/
                DESTINATION configuration/${PROJECT_NAME}
                FILES_MATCHING PATTERN "*"
                               PATTERN "*.pc" EXCLUDE)
    endif()

    if (IS_DIRECTORY ${PROJECT_SOURCE_DIR}/test)
        option(EDS_TEST_ENABLED "set to ON to enable the unit tests" OFF)
        if (EDS_TEST_ENABLED)
            add_subdirectory(test)
        else()
            message(STATUS "unit tests disabled as EDS_TEST_ENABLED is set to OFF")
        endif()

    endif()

    option(EDS_CLANG_STYLING_CHECK_ENABLED
           "set to ON to styling check on test targets" OFF)
    if (EDS_CLANG_STYLING_CHECK_ENABLED)
        enable_testing()
        eds_setup_styling_check(${PROJECT_NAME} ${source_and_test_files})
    endif()

    option(EDS_CLANG_LINTING_CHECK_ENABLED
           "set to ON to linting check on test targets" OFF)
    if (EDS_CLANG_LINTING_CHECK_ENABLED)
        enable_testing()
        eds_setup_linting_check(${PROJECT_NAME} ${source_and_test_files})
    endif()
endmacro()

## Like pkg_check_modules, but calls include_directories and link_directories
# using the resulting information
macro (eds_find_pkgconfig VARIABLE)
    if (NOT ${VARIABLE}_FOUND)
        pkg_check_modules(${VARIABLE} ${ARGN})
        foreach(${VARIABLE}_lib ${${VARIABLE}_LIBRARIES})
          set(_${VARIABLE}_lib NOTFOUND)
          find_library(_${VARIABLE}_lib NAMES ${${VARIABLE}_lib} HINTS ${${VARIABLE}_LIBRARY_DIRS})
          if (NOT _${VARIABLE}_lib)
            set(_${VARIABLE}_lib ${${VARIABLE}_lib})
          endif()
          list(APPEND _${VARIABLE}_LIBRARIES ${_${VARIABLE}_lib})
        endforeach()
        list(APPEND _${VARIABLE}_LIBRARIES ${${VARIABLE}_LDFLAGS_OTHER})
        set(${VARIABLE}_LIBRARIES ${_${VARIABLE}_LIBRARIES} CACHE INTERNAL "")
    endif()

    add_definitions(${${VARIABLE}_CFLAGS_OTHER})
    include_directories(${${VARIABLE}_INCLUDE_DIRS})
endmacro()

## Like find_package, but calls include_directories and link_directories using
# the resulting information
macro (eds_find_cmake VARIABLE)
    find_package(${VARIABLE} ${ARGN})
    eds_add_plain_dependency(${VARIABLE})
endmacro()

macro (eds_add_plain_dependency VARIABLE)
    string(TOUPPER ${VARIABLE} UPPER_VARIABLE)

    # Normalize uppercase / lowercase
    foreach(__varname CFLAGS INCLUDE_DIRS INCLUDE_DIR LIBRARY_DIRS LIBRARY_DIR LIBRARIES)
        if (NOT ${VARIABLE}_${__varname})
            set(${VARIABLE}_${__varname} "${${UPPER_VARIABLE}_${__varname}}")
        endif()
    endforeach()

    # Normalize plural/singular
    foreach(__varname INCLUDE_DIR LIBRARY_DIR)
        if (NOT ${VARIABLE}_${__varname}S)
            set(${VARIABLE}_${__varname}S "${${VARIABLE}_${__varname}}")
        endif()
    endforeach()

    # Be consistent with pkg-config
    set(${VARIABLE}_CFLAGS_OTHER ${${VARIABLE}_CFLAGS})

    add_definitions(${${VARIABLE}_CFLAGS_OTHER})
    include_directories(${${VARIABLE}_INCLUDE_DIRS})
    link_directories(${${VARIABLE}_LIBRARY_DIRS})
endmacro()

## Common parsing of parameters for all the C/C++ target types
macro(eds_target_definition TARGET_NAME)
    set(${TARGET_NAME}_INSTALL ON)
    set(${TARGET_NAME}_USE_BINARY_DIR OFF)
    set(EDS_TARGET_AVAILABLE_MODES "SOURCES;HEADERS;DEPS;DEPS_PKGCONFIG;DEPS_CMAKE;DEPS_PLAIN;DEPS_TARGET;MOC;UI;LIBS")

    set(${TARGET_NAME}_MODE "SOURCES")
    foreach(ELEMENT ${ARGN})
        list(FIND EDS_TARGET_AVAILABLE_MODES "${ELEMENT}" IS_KNOWN_MODE)
        if (ELEMENT STREQUAL "USE_BINARY_DIR")
            set(${TARGET_NAME}_USE_BINARY_DIR ON)
        elseif (ELEMENT STREQUAL "LIBS")
            set(${TARGET_NAME}_MODE DEPENDENT_LIBS)
        elseif (IS_KNOWN_MODE GREATER -1)
            set(${TARGET_NAME}_MODE "${ELEMENT}")
        elseif(ELEMENT STREQUAL "NOINSTALL")
            set(${TARGET_NAME}_INSTALL OFF)
        elseif(ELEMENT STREQUAL "LANG_C")
            set(${TARGET_NAME}_LANG_C TRUE)
        elseif(ELEMENT STREQUAL "EXPORT")
            set(${TARGET_NAME}_MODE EXPORT)
            set(${TARGET_NAME}_EXPORT "EXPORT")
        else()
            list(APPEND ${TARGET_NAME}_${${TARGET_NAME}_MODE} "${ELEMENT}")
        endif()
    endforeach()

    foreach (internal_dep ${${TARGET_NAME}_DEPS})
        foreach(dep_mode PLAIN CMAKE PKGCONFIG TARGET)
            get_property(internal_dep_DEPS TARGET ${internal_dep}
                PROPERTY DEPS_PUBLIC_${dep_mode})

            if (internal_dep_DEPS)
                list(APPEND ${TARGET_NAME}_DEPS_${dep_mode} ${internal_dep_DEPS})
            else()
                get_property(internal_dep_DEPS TARGET ${internal_dep}
                    PROPERTY DEPS_${dep_mode})
                list(APPEND ${TARGET_NAME}_DEPS_${dep_mode} ${internal_dep_DEPS})
            endif()
        endforeach()
    endforeach()

    foreach (plain_pkg ${${TARGET_NAME}_DEPS_PLAIN} ${${TARGET_NAME}_PUBLIC_PLAIN})
        eds_add_plain_dependency(${plain_pkg})
    endforeach()
    foreach (pkgconfig_pkg ${${TARGET_NAME}_DEPS_PKGCONFIG} ${${TARGET_NAME}_PUBLIC_PKGCONFIG})
        eds_find_pkgconfig(${pkgconfig_pkg}_PKGCONFIG REQUIRED ${pkgconfig_pkg})
    endforeach()
    foreach (cmake_pkg ${${TARGET_NAME}_DEPS_CMAKE} ${${TARGET_NAME}_PUBLIC_CMAKE})
        eds_find_cmake(${cmake_pkg} REQUIRED)
    endforeach()

    # At this stage, if the user did not set public dependency lists
    # explicitely, pass on everything
    foreach(__depmode PLAIN CMAKE PKGCONFIG TARGET)
        if (NOT DEFINED ${TARGET_NAME}_PUBLIC_${__depmode})
            set(${TARGET_NAME}_PUBLIC_${__depmode} ${${TARGET_NAME}_DEPS_${__depmode}})
        endif()
    endforeach()

    # Export public dependencies to pkg-config
    set(${TARGET_NAME}_PKGCONFIG_REQUIRES
        "${${TARGET_NAME}_PKGCONFIG_REQUIRES} ${${TARGET_NAME}_PUBLIC_PKGCONFIG}")
    string(REPLACE ";" " " ${TARGET_NAME}_PKGCONFIG_REQUIRES "${${TARGET_NAME}_PKGCONFIG_REQUIRES}")
    foreach(dep_mode PLAIN CMAKE)
        foreach(__dep ${${TARGET_NAME}_PUBLIC_${dep_mode}})
            eds_libraries_for_pkgconfig(${TARGET_NAME}_PKGCONFIG_LIBS
                ${${__dep}_LIBRARIES})
            set(${TARGET_NAME}_PKGCONFIG_CFLAGS
                "${${TARGET_NAME}_PKGCONFIG_CFLAGS} ${${__dep}_CFLAGS_OTHER}")
            foreach(__dep_incdir ${${__dep}_INCLUDE_DIRS})
                set(${TARGET_NAME}_PKGCONFIG_CFLAGS
                    "${${TARGET_NAME}_PKGCONFIG_CFLAGS} -I${__dep_incdir}")
            endforeach()
        endforeach()
    endforeach()

    eds_target_resolve_transitive_dependencies(
        __dependent_targets __dependent_libs ${${TARGET_NAME}_PUBLIC_TARGET}
    )
    foreach(__dep ${__dependent_libs})
        eds_libraries_for_pkgconfig(${TARGET_NAME}_PKGCONFIG_LIBS
            ${__dep})
    endforeach()

    foreach(__dep ${__dependent_targets})
        get_property(__dep_link_dirs TARGET ${__dep} PROPERTY INTERFACE_LINK_DIRECTORIES)
        foreach(__dep_linkdir ${__dep_link_dirs})
            set(${TARGET_NAME}_PKGCONFIG_LIBS
                "${${TARGET_NAME}_PKGCONFIG_LIBS} -L${__dep_linkdir}")
        endforeach()

        get_property(__dep_include_dirs TARGET ${__dep} PROPERTY INTERFACE_INCLUDE_DIRECTORIES)
        foreach(__dep_incdir ${__dep_include_dirs})
            set(${TARGET_NAME}_PKGCONFIG_CFLAGS
                "${${TARGET_NAME}_PKGCONFIG_CFLAGS} -I${__dep_incdir}")
        endforeach()
    endforeach()

    list(LENGTH ${TARGET_NAME}_MOC QT_SOURCE_LENGTH)
    if (QT_SOURCE_LENGTH GREATER 0)
        if(NOT DEFINED EDS_QT_VERSION)
            message(WARNING "you are requesting moc generation, but did not call eds_find_qt4() or eds_find_qt5(). Explicitely add eds_find_qt4() or eds_find_qt5() in your root CMakeLists.txt, just before calling eds_standard_layout()")
            eds_find_qt4()
        endif()

        list(APPEND ${TARGET_NAME}_DEPENDENT_LIBS ${QT_QTCORE_LIBRARY} ${QT_QTGUI_LIBRARY})

        set(__${TARGET_NAME}_MOC "${${TARGET_NAME}_MOC}")
        set(${TARGET_NAME}_MOC "")

        set(__cpp_extensions ".c" ".cpp" ".cxx" ".cc")

        # If a source file (*.c*) is listed in MOC, add it to the list of
        # sources and moc the corresponding header
        foreach(__moced_file ${__${TARGET_NAME}_MOC})
            get_filename_component(__file_ext ${__moced_file} EXT)
            list(FIND __cpp_extensions "${__file_ext}" __file_is_source)
            if (__file_is_source GREATER -1)
                list(APPEND ${TARGET_NAME}_SOURCES ${__moced_file})
                get_filename_component(__file_wext ${__moced_file} NAME_WE)
                get_filename_component(__file_dir ${__moced_file} PATH)
                if (NOT "${__file_dir}" STREQUAL "")
                    set(__file_wext "${__file_dir}/${__file_wext}")
                endif()
                unset(__moced_file)
                foreach(__header_ext .h .hh .hxx .hpp)
                    if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${__file_wext}${__header_ext}")
                        set(__moced_file "${__file_wext}${__header_ext}")
                    endif()
                endforeach()
            endif()
            list(APPEND ${TARGET_NAME}_MOC ${__moced_file})
        endforeach()

        if (EDS_QT_VERSION EQUAL 5)
            QT5_WRAP_CPP(${TARGET_NAME}_MOC_SRCS ${${TARGET_NAME}_MOC} TARGET ${TARGET_NAME})
        else()
            QT4_WRAP_CPP(${TARGET_NAME}_MOC_SRCS ${${TARGET_NAME}_MOC} TARGET ${TARGET_NAME})
        endif()
        list(APPEND ${TARGET_NAME}_SOURCES ${${TARGET_NAME}_MOC_SRCS})
    endif()

    list(LENGTH ${TARGET_NAME}_UI QT_UI_LENGTH)
    if (QT_UI_LENGTH GREATER 0)
        if (EDS_QT_VERSION EQUAL 5)
            QT5_WRAP_UI(${TARGET_NAME}_UI_HDRS ${${TARGET_NAME}_UI})
        else()
            QT4_WRAP_UI(${TARGET_NAME}_UI_HDRS ${${TARGET_NAME}_UI})
        endif()
        message(DEBUG ${${TARGET_NAME}_UI_HDRS})
        include_directories(${CMAKE_CURRENT_BINARY_DIR})
        list(APPEND ${TARGET_NAME}_SOURCES ${${TARGET_NAME}_UI_HDRS})
    endif()
endmacro()

function(eds_target_resolve_transitive_dependencies TARGETS LIBS)
    foreach(obj ${ARGN})
        if (TARGET ${obj})
            get_target_property(target_type ${obj} TYPE)
            # CMake has a concept called "INTERFACE_LIBRARY" which is not an actual
            # target. It does not build anything, so does not have a location
            #
            # However, it does have other useful properties such as link/include
            # directories
            if (NOT target_type STREQUAL "INTERFACE_LIBRARY")
                get_property(target_location TARGET ${obj} PROPERTY LOCATION)
            endif()
            get_property(dep_libraries TARGET ${obj} PROPERTY INTERFACE_LINK_LIBRARIES)
            eds_target_resolve_transitive_dependencies(
                recursive_targets recursive_libs ${dep_libraries}
            )
            list(APPEND targets ${obj} ${recursive_targets})
            list(APPEND libs ${target_location} ${recursive_libs})
        else()
            list(APPEND libs ${obj})
        endif()
    endforeach()

    set(${TARGETS} "${targets}" PARENT_SCOPE)
    set(${LIBS} "${libs}" PARENT_SCOPE)
endfunction()

## Common post-target-definition setup for all C/C++ targets
macro(eds_target_setup TARGET_NAME)
    set_property(TARGET ${TARGET_NAME}
        PROPERTY DEPS_PUBLIC_PKGCONFIG ${${TARGET_NAME}_PUBLIC_PKGCONFIG})
    set_property(TARGET ${TARGET_NAME}
        PROPERTY DEPS_PUBLIC_PLAIN ${${TARGET_NAME}_PUBLIC_PLAIN})
    set_property(TARGET ${TARGET_NAME}
        PROPERTY DEPS_PUBLIC_CMAKE ${${TARGET_NAME}_PUBLIC_CMAKE})

    if (${TARGET_NAME}_USE_BINARY_DIR)
        eds_target_use_binary_dir(${TARGET_NAME})
    endif()

    if (NOT ${TARGET_NAME}_LANG_C)
        eds_add_compiler_flag_to_target_if_it_exists(${TARGET_NAME} "-Wnon-virtual-dtor")
    endif()

    foreach (plain_dep ${${TARGET_NAME}_DEPS_PLAIN})
        target_link_libraries(${TARGET_NAME} ${${plain_dep}_LIBRARIES}
            ${${plain_dep}_LIBRARY})
    endforeach()
    foreach (pkgconfig_pkg ${${TARGET_NAME}_DEPS_PKGCONFIG})
        target_link_libraries(${TARGET_NAME} ${${pkgconfig_pkg}_PKGCONFIG_LIBRARIES})
    endforeach()
    foreach (__cmake_target ${${TARGET_NAME}_DEPS_TARGET})
        target_link_libraries(${TARGET_NAME} ${__cmake_target})
    endforeach()
    foreach (imported_dep ${${TARGET_NAME}_IMPORTED_DEPS})
        target_link_libraries(${TARGET_NAME} ${${imported_dep}_LIBRARIES})
    endforeach()
    foreach (internal_dep ${${TARGET_NAME}_DEPS})
        get_target_property(internal_dep_includes ${internal_dep} INCLUDE_DIRECTORIES)
        if(internal_dep_includes)
            target_include_directories(${TARGET_NAME} BEFORE PUBLIC ${internal_dep_includes})
        endif()
    endforeach()
    target_link_libraries(${TARGET_NAME} ${${TARGET_NAME}_DEPS})
    target_link_libraries(${TARGET_NAME} ${${TARGET_NAME}_DEPENDENT_LIBS})
    foreach (cmake_pkg ${${TARGET_NAME}_DEPS_CMAKE})
        string(TOUPPER ${cmake_pkg} UPPER_cmake_pkg)
        target_link_libraries(${TARGET_NAME} ${${cmake_pkg}_LIBRARIES} ${${cmake_pkg}_LIBRARY})
        target_link_libraries(${TARGET_NAME} ${${UPPER_cmake_pkg}_LIBRARIES} ${${UPPER_cmake_pkg}_LIBRARY})
    endforeach()
endmacro()

## Defines a new C++ executable
#
# eds_executable(name
#     SOURCES source.cpp source1.cpp ...
#     [USE_BINARY_DIR]
#     [DEPS target1 target2 target3]
#     [DEPS_PKGCONFIG pkg1 pkg2 pkg3]
#     [DEPS_TARGET target1 target2 target3]
#     [DEPS_CMAKE pkg1 pkg2 pkg3]
#     [MOC qtsource1.hpp qtsource2.hpp])
#     [UI qt_window.ui qt_widget.ui]
#     [LANG_C]
#
# Creates a C++ executable and (optionally) installs it
#
# The following arguments are mandatory:
#
# SOURCES: list of the C++ sources that should be built into that library
#
# The following optional arguments are available:
#
# USE_BINARY_DIR: whether the target needs to access headers from its binary dir,
# as e.g. if some code-generated files are used.
# DEPS: lists the other targets from this CMake project against which the
# library should be linked
# DEPS_PKGCONFIG: list of pkg-config packages that the library depends upon. The
# necessary link and compilation flags are added
# DEPS_TARGET: lists the CMake imported targets which should be used for this
# target. The targets must have been found already using e.g. `find_package`
# DEPS_CMAKE: list of packages which can be found with CMake's find_package,
# that the library depends upon using old-style variable passing. Use
# DEPS_TARGET for imported targets. It is assumed that the Find*.cmake scripts
# follow the cmake accepted standard for variable naming
# MOC: if the library is Qt-based, this is a list of either source or header
# files of classes that need to be passed through Qt's moc compiler.  If headers
# are listed, these headers should be processed by moc, with the resulting
# implementation files are built into the library. If they are source files,
# they get added to the library and the corresponding header file is passed to
# moc.
# UI: if the library is Qt-based, a list of ui files (only active if moc files are
# present)
# LANG_C: use this if the code is written in C

function(eds_executable TARGET_NAME)
    eds_target_definition(${TARGET_NAME} ${ARGN})

    add_executable(${TARGET_NAME} ${${TARGET_NAME}_SOURCES})
    eds_target_setup(${TARGET_NAME})

    if (${TARGET_NAME}_INSTALL)
        install(TARGETS ${TARGET_NAME}
            RUNTIME DESTINATION bin)
    endif()
endfunction()

# Trigger the configuration of the pkg-config config file (*.pc.in)
# Second option allows to select installation of the generated .pc file
function(eds_prepare_pkgconfig TARGET_NAME DO_INSTALL)
    foreach(pkgname ${${TARGET_NAME}_PUBLIC_PKGCONFIG})
        set(DEPS_PKGCONFIG "${DEPS_PKGCONFIG} ${pkgname}")
    endforeach()
    set(PKGCONFIG_REQUIRES ${${TARGET_NAME}_PKGCONFIG_REQUIRES})
    set(PKGCONFIG_CFLAGS ${${TARGET_NAME}_PKGCONFIG_CFLAGS})
    set(PKGCONFIG_LIBS ${${TARGET_NAME}_PKGCONFIG_LIBS})

    if (DEFINED EDS_PUBLIC_CXX_STANDARD)
        set(cxx_standard ${EDS_PUBLIC_CXX_STANDARD})
    elseif (TARGET ${TARGET_NAME} AND NOT CMAKE_VERSION VERSION_LESS "3.1")
        get_property(cxx_standard TARGET ${TARGET_NAME} PROPERTY CXX_STANDARD)
    else()
        set(cxx_standard ${CMAKE_CXX_STANDARD})
    endif()

    if (cxx_standard)
        set(PKGCONFIG_CFLAGS "${PKGCONFIG_CFLAGS} -std=c++${cxx_standard}")
    endif()

    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET_NAME}.pc.in)
        configure_file(${CMAKE_CURRENT_SOURCE_DIR}/${TARGET_NAME}.pc.in
            ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.pc @ONLY)
        if (DO_INSTALL)
            install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.pc
                DESTINATION lib/pkgconfig)
        endif()
    else()
        message("pkg-config: ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET_NAME}.pc.in is not available for configuration")
    endif()
endfunction()

## Common setup for libraries in EDS. Used by eds_library and
# eds_vizkit_plugin
macro(eds_library_common TARGET_NAME)
    eds_target_definition(${TARGET_NAME} ${ARGN})
    # Skip the add_library part if the only thing the caller wants is to install
    # headers
    list(LENGTH ${TARGET_NAME}_SOURCES __source_list_size)
    if (__source_list_size)
        add_library(${TARGET_NAME} SHARED ${${TARGET_NAME}_SOURCES})
        eds_target_setup(${TARGET_NAME})
        set(${TARGET_NAME}_LIBRARY_HAS_TARGET TRUE)
    endif()
    eds_prepare_pkgconfig(${TARGET_NAME} ${TARGET_NAME}_INSTALL)
endmacro()

# Install list of headers and keep directory structure
function(eds_install_headers HEADER_LIST)
    # Note: using ARGV here, since it expand to the full argument list,
    # otherwise the function would need to be called with a quoted list, e.g.
    # eds_install_headers("${MY_LIST}")
    foreach(HEADER ${ARGV})
        string(REPLACE "${CMAKE_CURRENT_BINARY_DIR}/" "" HEADER_relative "${HEADER}")
        get_filename_component(DIR ${HEADER_relative} PATH)
        install(FILES ${HEADER} DESTINATION include/${PROJECT_NAME}/${DIR})
    endforeach(HEADER)
endfunction()

## Defines a new shared library
#
# eds_library(name
#     SOURCES source.cpp source1.cpp ...
#     [USE_BINARY_DIR]
#     [DEPS target1 target2 target3]
#     [DEPS_PKGCONFIG pkg1 pkg2 pkg3]
#     [DEPS_TARGET target1 target2 target3]
#     [DEPS_CMAKE pkg1 pkg2 pkg3]
#     [HEADERS header1.hpp header2.hpp header3.hpp ...]
#     [MOC qtsource1.hpp qtsource2.hpp]
#     [UI qt_window.ui qt_widget.ui]
#     [NOINSTALL]
#     [LANG_C])
#
# Creates and (optionally) installs a shared library.
#
# As with all eds libraries, the target must have a pkg-config file along, that
# gets generated and (optionally) installed by the macro. The pkg-config file
# needs to be in the same directory and called <name>.pc.in
#
# The following arguments are mandatory:
#
# SOURCES: list of the C++ sources that should be built into that library
#
# The following optional arguments are available:
#
# USE_BINARY_DIR: whether the target needs to access headers from its binary dir,
# as e.g. if some code-generated files are used.
# DEPS: lists the other targets from this CMake project against which the
# library should be linked
# DEPS_PKGCONFIG: list of pkg-config packages that the library depends upon. The
# necessary link and compilation flags are added
# DEPS_TARGET: lists the CMake imported targets which should be used for this
# target. The targets must have been found already using e.g. `find_package`
# DEPS_CMAKE: list of packages which can be found with CMake's find_package,
# that the library depends upon. It is assumed that the Find*.cmake scripts
# follow the cmake accepted standard for variable naming
# HEADERS: a list of headers that should be installed with the library. They get
# installed in include/project_name
# MOC: if the library is Qt-based, a list of either source or header files.
# If headers are listed, these headers should be processed by moc, with the
# resulting implementation files are built into the library. If they are source
# files, they get added to the library and the corresponding header file is
# passed to moc.
# UI: if the library is Qt-based, a list of ui files (only active if moc files are
# present)
# NOINSTALL: by default, the library gets installed on 'make install'. If this
# argument is given, this is turned off
# LANG_C: use this if the library is written in C to avoid the use of unsupported
# compiler flags and arguments
#
# If a pkg-config file named '${TARGET_NAME}.pc.in' exists in the same folder
# as the target, this file will be automatically generated and installed. The
# eds_library setup expects this file to follow this template:
#
#    prefix=@CMAKE_INSTALL_PREFIX@
#    exec_prefix=@CMAKE_INSTALL_PREFIX@
#    libdir=${prefix}/lib
#    includedir=${prefix}/include
#
#    Name: @TARGET_NAME@
#    Description: @PROJECT_DESCRIPTION@
#    Version: @PROJECT_VERSION@
#    Requires: @PKGCONFIG_REQUIRES@
#    Libs: -L${libdir} -l@TARGET_NAME@ @PKGCONFIG_LIBS@
#    Cflags: -I${includedir} @PKGCONFIG_CFLAGS@
#
# Within EDS, such a template is installed by the eds-create-lib tool.
function(eds_library TARGET_NAME)
    eds_library_common(${TARGET_NAME} ${ARGN})

    if (${TARGET_NAME}_INSTALL)
        if (${TARGET_NAME}_LIBRARY_HAS_TARGET)
            install(TARGETS ${TARGET_NAME} ${${TARGET_NAME}_EXPORT}
                LIBRARY DESTINATION lib
                # On Windows the dll part of a library is treated as RUNTIME target
                # and the corresponding import library is treated as ARCHIVE target
                ARCHIVE DESTINATION lib
                RUNTIME DESTINATION bin)
        endif()

        # Install headers and keep directory structure
        if(${TARGET_NAME}_HEADERS)
            eds_install_headers(${${TARGET_NAME}_HEADERS})
        endif()
    endif()
endfunction()

## Defines a new vizkit3d plugin
#
# eds_vizkit_plugin(name
#     SOURCES source.cpp source1.cpp ...
#     [DEPS target1 target2 target3]
#     [DEPS_PKGCONFIG pkg1 pkg2 pkg3]
#     [DEPS_TARGET target1 target2 target3]
#     [DEPS_CMAKE pkg1 pkg2 pkg3]
#     [HEADERS header1.hpp header2.hpp header3.hpp ...]
#     [MOC qtsource1.hpp qtsource2.hpp]
#     [NOINSTALL])
#
# Creates and (optionally) installs a shared library that defines a vizkit3d
# plugin. In EDS, vizkit3d is the base for data display. Vizkit plugins are
# plugins to the 3D display in vizkit3d.
#
# The library gets linked against the vizkit3d libraries automatically (no
# need to list them in DEPS_PKGCONFIG). Moreoer, unlike with a normal shared
# library, the headers get installed in include/vizkit3d
#
# The following arguments are mandatory:
#
# SOURCES: list of the C++ sources that should be built into that library
#
# The following optional arguments are available:
#
# DEPS: lists the other targets from this CMake project against which the
# library should be linked
# DEPS_PKGCONFIG: list of pkg-config packages that the library depends upon. The
# necessary link and compilation flags are added
# DEPS_TARGET: lists the CMake imported targets which should be used for this
# target. The targets must have been found already using e.g. `find_package`
# DEPS_CMAKE: list of packages which can be found with CMake's find_package,
# that the library depends upon. It is assumed that the Find*.cmake scripts
# follow the cmake accepted standard for variable naming
# HEADERS: a list of headers that should be installed with the library. They get
# installed in include/project_name
# MOC: if the library is Qt-based, a list of either source or header files.
# If headers are listed, these headers should be processed by moc, with the
# resulting implementation files are built into the library. If they are source
# files, they get added to the library and the corresponding header file is
# passed to moc.
# NOINSTALL: by default, the library gets installed on 'make install'. If this
# argument is given, this is turned off
function(eds_vizkit_plugin TARGET_NAME)
    if (${PROJECT_NAME} STREQUAL "vizkit3d")
    else()
        list(APPEND additional_deps DEPS_PKGCONFIG vizkit3d)
    endif()
    eds_library_common(${TARGET_NAME} ${ARGN} ${additional_deps})
    if (${TARGET_NAME}_INSTALL)
        if (${TARGET_NAME}_LIBRARY_HAS_TARGET)
            install(TARGETS ${TARGET_NAME}
                LIBRARY DESTINATION lib)
        endif()
        install(FILES ${${TARGET_NAME}_HEADERS}
            DESTINATION include/vizkit3d)
        install(FILES vizkit_plugin.rb
            DESTINATION lib/qt/designer/widgets
            RENAME ${PROJECT_NAME}_vizkit.rb
            OPTIONAL)
    endif()
endfunction()

## Defines a new vizkit widget
#
# eds_vizkit_widget(name
#     SOURCES source.cpp source1.cpp ...
#     [DEPS target1 target2 target3]
#     [DEPS_PKGCONFIG pkg1 pkg2 pkg3]
#     [DEPS_TARGET target1 target2 target3]
#     [DEPS_CMAKE pkg1 pkg2 pkg3]
#     [HEADERS header1.hpp header2.hpp header3.hpp ...]
#     [MOC qtsource1.hpp qtsource2.hpp]
#     [NOINSTALL])
#
# Creates and (optionally) installs a shared library that defines a vizkit
# widget. In EDS, vizkit is the base for data display. Vizkit widgets are
# Qt designer widgets that can be seamlessly integrated in the vizkit framework.
#
# If a file called <project_name>.rb exists, it is assumed to be a ruby
# extension used to extend the C++ interface in ruby scripting. It gets
# installed in share/vizkit/ext, where vizkit is looking for it. if a file
# called vizkit_widget.rb exists it will be renamed and installed to
# lib/qt/designer/cplusplus_extensions/<project_name>_vizkit.rb
#
# List all libraries to link to in the DEPS_PKGCONFIG, including Qt-libraries
# like QtCore. Unlike with a normal shared library, the headers get installed
# in include/<project_name>
#
# The following arguments are mandatory:
#
# SOURCES: list of the C++ sources that should be built into that library
# MOC: if the library is Qt-based, a list of either source or header files.
# If headers are listed, these headers should be processed by moc, with the
# resulting implementation files are built into the library. If they are source
# files, they get added to the library and the corresponding header file is
# passed to moc.
#
# The following optional arguments are available:
#
# DEPS: lists the other targets from this CMake project against which the
# library should be linked
# DEPS_PKGCONFIG: list of pkg-config packages that the library depends upon. The
# necessary link and compilation flags are added
# DEPS_TARGET: lists the CMake imported targets which should be used for this
# target. The targets must have been found already using e.g. `find_package`
# DEPS_CMAKE: list of packages which can be found with CMake's find_package,
# that the library depends upon. It is assumed that the Find*.cmake scripts
# follow the cmake accepted standard for variable naming
# HEADERS: a list of headers that should be installed with the library. They get
# installed in include/project_name
# NOINSTALL: by default, the library gets installed on 'make install'. If this
# argument is given, this is turned off
function(eds_vizkit_widget TARGET_NAME)
    eds_library_common(${TARGET_NAME} ${ARGN})
    if (${TARGET_NAME}_INSTALL)
        install(TARGETS ${TARGET_NAME}
            LIBRARY DESTINATION lib/qt/designer)
        install(FILES ${${TARGET_NAME}_HEADERS}
            DESTINATION include/${PROJECT_NAME})
        install(FILES ${TARGET_NAME}.rb
            DESTINATION share/vizkit/ext
            OPTIONAL)
        install(FILES vizkit_widget.rb
            DESTINATION lib/qt/designer/cplusplus_extensions
            RENAME ${PROJECT_NAME}_vizkit.rb
            OPTIONAL)
    endif()
endfunction()

## Defines a new C++ test suite
#
# eds_testsuite(name
#     SOURCES source.cpp source1.cpp ...
#     [DEPS target1 target2 target3]
#     [DEPS_PKGCONFIG pkg1 pkg2 pkg3]
#     [DEPS_TARGET target1 target2 target3]
#     [DEPS_CMAKE pkg1 pkg2 pkg3]
#     [MOC qtsource1.hpp qtsource2.hpp])
#
# Creates a C++ test suite that is using the boost unit test framework
#
# The following arguments are mandatory:
#
# SOURCES: list of the C++ sources that should be built into that library
#
# The following optional arguments are available:
#
# DEPS: lists the other targets from this CMake project against which the
# library should be linked
# DEPS_PKGCONFIG: list of pkg-config packages that the library depends upon. The
# necessary link and compilation flags are added
# DEPS_TARGET: lists the CMake imported targets which should be used for this
# target. The targets must have been found already using e.g. `find_package`
# DEPS_CMAKE: list of packages which can be found with CMake's find_package,
# that the library depends upon. It is assumed that the Find*.cmake scripts
# follow the cmake accepted standard for variable naming
# MOC: if the library is Qt-based, a list of either source or header files.
# If headers are listed, these headers should be processed by moc, with the
# resulting implementation files are built into the library. If they are source
# files, they get added to the library and the corresponding header file is
# passed to moc.
function(eds_testsuite TARGET_NAME)
    eds_test_common(${TARGET_NAME} ${ARGN})
    eds_setup_boost_test(${TARGET_NAME})
    eds_add_test(${TARGET_NAME} "${__eds_test_parameters}")
endfunction()

## Uses gtest + google-mock as unit testing framework
# The interface is the same as the one from eds_testsuite
#
# Unfortunately, gtest and google-mock do not ship with
# pre-compiled libraries so we have to add their source files
# to the test target. If GTEST_DIR or GMOCK_DIR are not set,
# this function will look for the required source files
# in /usr/src, which is the default path under ubuntu/debian
function(eds_gtest TARGET_NAME)
    if (NOT GTEST_DIR)
        find_path(GTEST_DIR "src/gtest-all.cc" /usr/src/gtest)
    endif()
    if (NOT GMOCK_DIR)
        find_path(GMOCK_DIR "src/gmock-all.cc" /usr/src/gmock)
    endif()

    if (NOT GTEST_DIR)
        message(FATAL_ERROR "Could not find gtest in /usr/src")
    endif()
    if (NOT GMOCK_DIR)
        message(FATAL_ERROR "Could not find google-mock in /usr/src")
    endif()
    message(STATUS "gtest found ... building the test suite")

    eds_test_common(${TARGET_NAME} ${GTEST_DIR}/src/gtest-all.cc
                                    ${GMOCK_DIR}/src/gmock-all.cc
                                    ${ARGN})

    eds_setup_gtest_test(${TARGET_NAME} ${GMOCK_DIR} ${GTEST_DIR})
    eds_add_test(${TARGET_NAME} "${__eds_test_parameters}")
endfunction()

function(eds_get_clang_targets VAR filepath)
    if (EXISTS "${filepath}")
        file(STRINGS ${filepath} checklist REGEX "^(\\+|-)+")
        foreach(entry ${checklist})
            string(REGEX MATCH "^(\\+|-)?" symbol ${entry})
            string(SUBSTRING ${entry} 1 -1 glob_pattern)
            file(GLOB listed_files "${glob_pattern}")
            if (symbol STREQUAL "+")
                list(APPEND target_list ${listed_files})
            else()
                list(REMOVE_ITEM target_list ${listed_files})
            endif()
        endforeach(entry)
    else()
        file(GLOB target_list "src/*[cpp|hpp|c|h|cc|hh]" "test/*[cpp|hpp|c|h|cc|hh]")
    endif()
    set(${VAR} ${target_list} PARENT_SCOPE)
endfunction()

function(eds_setup_styling_check TARGET_NAME)
    eds_get_clang_targets(clang_targets "${CMAKE_SOURCE_DIR}/.clang_format_targets")
    message(STATUS "Setting up styling for ${TARGET_NAME} package")
    find_program(
        clang_format_exec NAMES
        ${EDS_CLANG_FORMAT_EXECUTABLE} clang-format
    )
    if (NOT clang_format_exec)
        message(FATAL_ERROR "Could not find an executable for clang-format.")
    endif()

    set(clang_config_option "-style=file")
    if(${EDS_CLANG_FORMAT_CONFIG_PATH})
        message(WARNING "Setting an explicit config path for the styling check is only available for clang-format-14 or later.")
        set(clang_config_option "-style=file:${EDS_CLANG_FORMAT_CONFIG_PATH}")
    endif()

    add_test(
        NAME
        clangformat
        COMMAND
        ${clang_format_exec}
        ${clang_config_option}
        -n
        ${EDS_CLANG_FORMAT_OPTIONS}
        ${clang_targets}
    )
endfunction()

function(eds_setup_linting_check TARGET_NAME)
    eds_get_clang_targets(clang_targets "${CMAKE_SOURCE_DIR}/.clang_tidy_targets")
    message(STATUS "Setting up linting for ${TARGET_NAME} package")
    # Setup Clang-Tidy linting as a test command
    find_program(
        clang_tidy_exec NAMES ${EDS_CLANG_TIDY_EXECUTABLE} clang-tidy
    )
    if (NOT clang_tidy_exec)
        message(FATAL_ERROR "Could not find an executable for clang-tidy.")
    endif()
    if (NOT EDS_CLANG_TIDY_CONFIG_PATH)
        message(FATAL_ERROR "Clang-tidy config file path unset.")
    endif()

    add_test(
        NAME
        clangtidy
        COMMAND
        ${clang_tidy_exec}
        -p
        ${PROJECT_BINARY_DIR}
        --config-file=${EDS_CLANG_TIDY_CONFIG_PATH}
        ${EDS_CLANG_TIDY_OPTIONS}
        ${clang_targets}
    )
endfunction()

function(eds_setup_gtest_test TARGET_NAME GMOCK_DIR GTEST_DIR)
    target_include_directories(${TARGET_NAME} SYSTEM PUBLIC ${GMOCK_DIR} ${GTEST_DIR}
                               ${GMOCK_DIR}/include ${GTEST_DIR}/include)
    target_link_libraries(${TARGET_NAME} pthread)

    if (EDS_TEST_LOG_DIR)
        list(APPEND __eds_test_parameters
             --gtest_output=xml:${EDS_TEST_LOG_DIR}/${TARGET_NAME}.gtest.xml)
        file(MAKE_DIRECTORY "${EDS_TEST_LOG_DIR}")
        set(__eds_test_parameters ${__eds_test_parameters} PARENT_SCOPE)
    endif()
endfunction()

function(eds_test_common TARGET_NAME)
    if (TARGET_NAME STREQUAL "test")
        message(WARNING "test name cannot be 'test', renaming to '${PROJECT_NAME}-test'")
        set(TARGET_NAME "${PROJECT_NAME}-test")
    endif()

    eds_executable(${TARGET_NAME} ${ARGN} NOINSTALL)
endfunction()

function(eds_setup_boost_test TARGET_NAME)
    find_package(Boost REQUIRED COMPONENTS unit_test_framework system)
    message(STATUS "boost/test found ... building the test suite")

    add_definitions(-DBOOST_TEST_DYN_LINK)
    target_link_libraries(${TARGET_NAME} ${Boost_UNIT_TEST_FRAMEWORK_LIBRARY})

    set(EDS_TEST_BOOST_FORMAT XML CACHE STRING "the output format for Boost.Test suites")
    if (EDS_TEST_LOG_DIR)
        list(APPEND __eds_test_parameters
             --log_format=${EDS_TEST_BOOST_FORMAT}
             --log_level=all
             --log_sink=${EDS_TEST_LOG_DIR}/${TARGET_NAME}.boost.xml)
        file(MAKE_DIRECTORY "${EDS_TEST_LOG_DIR}")
        set(__eds_test_parameters ${__eds_test_parameters} PARENT_SCOPE)
    endif()
endfunction()

function(eds_add_test TARGET_NAME __eds_test_parameters)
    add_test(NAME test-${TARGET_NAME}-cxx
             COMMAND ${EXECUTABLE_OUTPUT_PATH}/${TARGET_NAME}
             ${__eds_test_parameters})
endfunction()

## Get the library name from a given path
#
# eds_get_library_name(<output_variable> <input>)
#
# e.g.
#   eds_get_library_name(LIB_NAME "/usr/lib/libpython-2.7.so.0")
# will result in LIB_NAME=python-2.7
#
macro(eds_get_library_name VARNAME)
    get_filename_component(__lib_name ${ARGN} NAME)
    foreach(__lib_suffix ${CMAKE_FIND_LIBRARY_SUFFIXES})
        if("${__lib_name}" MATCHES "${__lib_suffix}")
            string(REGEX REPLACE "${__lib_suffix}\\..*$"
                "${__lib_suffix}" __lib_name "${__lib_name}")
            string(REGEX REPLACE "${__lib_suffix}$" "" __lib_name
                    "${__lib_name}")
            break()
        endif()
    endforeach()

    foreach(__lib_prefix ${CMAKE_FIND_LIBRARY_PREFIXES})
        if("${__lib_name}" MATCHES "${__lib_prefix}")
            string(REGEX REPLACE "^${__lib_prefix}" "" __lib_name
                "${__lib_name}")
            break()
        endif()
    endforeach()
    set(${VARNAME} "${__lib_name}")
endmacro()

macro(eds_libraries_for_pkgconfig VARNAME)
    foreach(__lib ${ARGN})
        string(STRIP __lib ${__lib})
        string(SUBSTRING ${__lib} 0 1 __lib_is_absolute)
        if (__lib_is_absolute STREQUAL "/")
            get_filename_component(__lib_path ${__lib} PATH)
            eds_get_library_name(__lib_name ${__lib})
            set(${VARNAME} "${${VARNAME}} -L${__lib_path} -l${__lib_name}")
        else()
            set(${VARNAME} "${${VARNAME}} ${__lib}")
        endif()
    endforeach()
endmacro()

## List dependencies for the given target that are needed by the user of that
# target
#
# eds_add_public_dependencies(TARGET
#     [PLAIN] dep0 dep1 dep2
#     [CMAKE cmake_dep0 cmake_dep1 cmake_dep2]
#     [PKGCONFIG pkg_dep0 pkg_dep1 pkg_dep2])
#
# Declares a list of dependencies for the users of TARGET. It must be called
# before TARGET is defined
#
# These dependencies are going to be used automatically in the definition of
# TARGET, i.e. there is no need to repeat them in e.g. the eds_library call.
# This method also update the following variables:
#
#   ${TARGET_NAME}_PKGCONFIG_REQUIRES
#   ${TARGET_NAME}_PKGCONFIG_CFLAGS
#   ${TARGET_NAME}_PKGCONFIG_LIBS
#
# Which can be used in pkg-config files to automatically add the necessary
# information from these dependencies in the target's pkg-config file
#
# Unless you call this, all dependencies listed in the eds_* macro to create
# the target are public. You only need to call this to restrict the
# cross-project dependencies
macro(eds_add_public_dependencies TARGET_NAME)
    set(MODE PLAIN)
    foreach(__dep ${ARGN})
        if ("${__dep}" STREQUAL "CMAKE")
            set(MODE CMAKE)
        elseif ("${__dep}" STREQUAL "PLAIN")
            set(MODE PLAIN)
        elseif ("${__dep}" STREQUAL "PKGCONFIG")
            set(MODE PKGCONFIG)
        else()
            list(APPEND ${TARGET_NAME}_PUBLIC_${MODE} "${__dep}")
        endif()
    endforeach()
endmacro()

# Restore the default dependency-export mechanism after a call to
# eds_add_public_dependencies or eds_no_public_dependencies
#
# When one does
#
#   eds_library(target DEPS_PKGCONFIG dep0 dep1)
#
# the dependencies are automatically exported in the pkg-config file. To ensure
# that no PKGCONFIG dependencies are exported at all, one needs to do
#
#   eds_no_public_dependencies(target PKGCONFIG)
#   eds_library(target DEPS_PKGCONFIG dep0 dep1)
#
# and equivalent for PLAIN and CMAKE. If you only want dep0 but not dep1, you
# would use eds_add_public_dependencies
#
#   eds_add_public_dependencies(target PKGCONFIG dep0)
#   eds_library(target DEPS_PKGCONFIG dep0 dep1)
#
# Finally, if you want to reset the default behaviour after a call to
# eds_add_public_dependencies or eds_no_public_dependencies, do
#
#   eds_make_all_dependencies_public(target PKGCONFIG)
#
macro(eds_make_all_dependencies_public TARGET_NAME)
    foreach(__dep ${ARGN})
        if ("${__dep}" STREQUAL "CMAKE")
            unset(${TARGET_NAME}_PUBLIC_CMAKE)
        elseif ("${__dep}" STREQUAL "PLAIN")
            unset(${TARGET_NAME}_PUBLIC_PLAIN)
        elseif ("${__dep}" STREQUAL "PKGCONFIG")
            unset(${TARGET_NAME}_PUBLIC_PKGCONFIG)
        else()
            message(FATAL_ERROR "unknown mode ${__dep} in eds_no_public_dependencies")
        endif()
    endforeach()
endmacro()

# Ensure that no dependencies of a certain type are exported in the pkg-config
# file
#
# When one does
#
#   eds_library(target DEPS_PKGCONFIG dep0 dep1)
#
# the dependencies are automatically exported in the pkg-config file. To ensure
# that no PKGCONFIG dependencies are exported at all, one needs to do
#
#   eds_no_public_dependencies(target PKGCONFIG)
#   eds_library(target DEPS_PKGCONFIG dep0 dep1)
#
# and equivalent for PLAIN and CMAKE. If you only want dep0 but not dep1, you
# would use eds_add_public_dependencies
#
#   eds_add_public_dependencies(target PKGCONFIG dep0)
#   eds_library(target DEPS_PKGCONFIG dep0 dep1)
#
# Finally, if you want to reset the default behaviour after a call to
# eds_add_public_dependencies or eds_no_public_dependencies, do
#
#   eds_make_all_dependencies_public(target PKGCONFIG)
#
macro(eds_no_public_dependencies TARGET_NAME)
    foreach(__dep ${ARGN})
        if ("${__dep}" STREQUAL "CMAKE")
            set(${TARGET_NAME}_PUBLIC_CMAKE "")
        elseif ("${__dep}" STREQUAL "PLAIN")
            set(${TARGET_NAME}_PUBLIC_PLAIN "")
        elseif ("${__dep}" STREQUAL "PKGCONFIG")
            set(${TARGET_NAME}_PUBLIC_PKGCONFIG "")
        else()
            message(FATAL_ERROR "unknown mode ${__dep} in eds_no_public_dependencies")
        endif()
    endforeach()
endmacro()

# Tell the target definitions to assume that code (headers and sources) is
# present in this folder's binary directory
#
# This happens most often when using code generation and/or configuration files
macro(eds_target_use_binary_dir TARGET)
    eds_export_includedir(${CMAKE_CURRENT_BINARY_DIR}
                           ${PROJECT_NAME} ${PROJECT_NAME}_bin)
    eds_exported_includedir_root(__includedir_root ${CMAKE_CURRENT_BINARY_DIR}
                                  ${PROJECT_NAME}_bin)
    target_include_directories(${TARGET} BEFORE PRIVATE ${__includedir_root})
    target_include_directories(${TARGET} BEFORE PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
endmacro()

# Find Qt4 libraries
#
# The macro finds QtCore, QtGui and QtOpenGL by default. Additional arguments
# can be given to find more components.
#
# Found include and library paths are added to the current directory. The
# relevant modules must be added to other targets with `DEPS_CMAKE Qt4`
macro (eds_find_qt4)
    set(__arglist "${ARGN}")
    list(GET 0 __arglist __arg_optreq)
    if ((__arg_optreq EQUAL "OPTIONAL") OR (__arg_optreq EQUAL "REQUIRED"))
        list(REMOVE_AT __arglist 0)
    else()
        set(__arg_optreq REQUIRED)
    endif()

    find_package(Qt4 ${__arg_optreq} COMPONENTS QtCore QtGui QtOpenGl ${__arglist})
    include_directories(${QT_HEADERS_DIR})
    set(EDS_QT_VERSION 4)

    foreach(__qtmodule__ QtCore QtGui QtOpenGl ${ARGN})
        string(TOUPPER ${__qtmodule__} __qtmodule__)
        add_definitions(${QT_${__qtmodule__}_DEFINITIONS})
        include_directories(${QT_${__qtmodule__}_INCLUDE_DIR})
        link_directories(${QT_${__qtmodule__}_LIBRARY_DIR})
    endforeach()
endmacro()

# Find Qt5 libraries
#
# The macro finds QtCore, QtGui and QtOpenGL by default. Additional arguments
# can be given to find more components.
macro (eds_find_qt5)
    set(__arglist "${ARGN}")
    list(GET 0 __arglist __arg_optreq)
    if ((__arg_optreq EQUAL "OPTIONAL") OR (__arg_optreq EQUAL "REQUIRED"))
        list(REMOVE_AT __arglist 0)
    else()
        set(__arg_optreq REQUIRED)
    endif()

    find_package(Qt5 ${__arg_optreq} COMPONENTS ${__arglist})
    set(EDS_QT_VERSION 5)

    set(CMAKE_AUTOMOC ON)
    set(CMAKE_AUTORCC ON)
    set(CMAKE_AUTOUIC ON)
endmacro()

# Autodetect the available OpenCV version and make it available for EDS DEPS_PKGCONFIG mechanism
#
# This tries to find the name of the opencv pkg-config package, due to the change
# from `opencv` for versions before 4.0 to `opencv4` later on.
#
# Basic usage is to call this function at toplevel with the name of the
# variable. This variable will be set with the name of the opencv pkg-config
# package that should be used on this installation, for instance:
#
#    eds_opencv_autodetect(OPENCV_PACKAGE)
#    eds_library(somelib DEPS_PKGCONFIG ${OPENCV_PACKAGE})
#
# The function declares the variable as CACHED. So, one can define it explicitely
# in the CMake call to override the detected version, e.g.
#
#    cmake -DOPENCV_PACKAGE=opencv ..
#
# The call will fail if no OpenCV package can be found.
function(eds_opencv_autodetect VARIABLE)
    if (${${VARIABLE}})
        return()
    endif()

    foreach(__opencv_candidate opencv opencv4)
        pkg_check_modules(__autodetect_opencv ${__opencv_candidate})
        if (__autodetect_opencv_FOUND)
            set(${VARIABLE} ${__opencv_candidate} CACHE STRING
                "The pkg-config package that should be resolved for OpenCV. Default is to auto-detect")
            return()
        endif()
    endforeach()
    message(FATAL_ERROR "failed to autodetect OpenCV version")
endfunction()

