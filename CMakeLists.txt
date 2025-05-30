cmake_minimum_required(VERSION 3.10)

# ==============================================================================
# SECTION 1: Project Initialization & Mode Detection
# ==============================================================================
# This section determines if 'forenum' is being built as a standalone project
# (e.g., for development and testing of 'forenum' itself) or as a submodule
# included by a parent project. The behavior of subsequent sections,
# particularly regarding test building, will adapt based on this mode.

if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    # --- STANDALONE MODE ---
    # This CMakeLists.txt is for the top-level project. This typically means
    # you are developing 'forenum' itself.
    set(FORENUM_IS_STANDALONE TRUE)
    project(forenum_project LANGUAGES Fortran)
    message(STATUS "Configuring 'forenum' as a standalone project (for development/testing).")

    # Standalone-specific configurations (examples):
    if(NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose build type: Debug Release RelWithDebInfo MinSizeRel" FORCE)
        message(STATUS "Standalone forenum: Defaulting CMAKE_BUILD_TYPE to Debug for development.")
    endif()
    # You might also set CMAKE_Fortran_MODULE_DIRECTORY here if desired for standalone builds, e.g.:
    # set(CMAKE_Fortran_MODULE_DIRECTORY \"${CMAKE_BINARY_DIR}/modules\")
else()
    # --- SUBMODULE MODE ---
    # 'forenum' is being included by another (parent) CMake project.
    # We use project(name NONE) to set our project name for this scope ('forenum_project')
    # without re-initializing languages or interfering with the parent project's setup.
    set(FORENUM_IS_STANDALONE FALSE)
    project(forenum_project NONE)
    message(STATUS "Configuring 'forenum' as a submodule (part of parent project: ${CMAKE_PROJECT_NAME}).")
endif()

# ==============================================================================
# SECTION 2: Core Library Definition (For Consumers of 'forenum')
# ==============================================================================
# This is the primary section relevant to users who want to incorporate 'forenum'
# into their own CMake projects. It defines the 'mod_forenum' INTERFACE library
# target, which makes the Fortran enumeration module available.

message(STATUS "Defining 'mod_forenum' INTERFACE library target...")

# 'mod_forenum' is an INTERFACE library. It doesn't compile into a separate
# .a or .so file. Instead, its source files and include directories are
# "interfaced" to any target that links against it.
add_library(mod_forenum INTERFACE)

# Specify the source file(s) that constitute the 'forenum' library.
# When another target links to 'mod_forenum', CMake ensures this source file
# is compiled as part of that target.
target_sources(mod_forenum INTERFACE
    "${CMAKE_CURRENT_SOURCE_DIR}/src/forenum.f90"
)

# Specify the include directories required to use 'mod_forenum'.
# This allows consuming projects to 'use forenum' and for
# the compiler to locate 'forenum.f90' and its generated .mod file.
target_include_directories(mod_forenum INTERFACE
    "${CMAKE_CURRENT_SOURCE_DIR}/src"  # Directory containing forenum.f90
)

message(STATUS "'mod_forenum' library defined. Link against it in your project.")

# ==============================================================================
# SECTION 3: Self-Testing Framework (Primarily for Developers of 'forenum')
# ==============================================================================
# This section configures the build of 'forenum's own internal tests.
# If you are simply using 'forenum' as a library in your project, you can
# generally ignore this section. These tests are for ensuring 'forenum' itself
# works correctly during its development.

# Option to control building of self-tests:
# - Defaults to ON if 'forenum' is built standalone (FORENUM_IS_STANDALONE is TRUE).
# - Defaults to OFF if 'forenum' is a submodule (FORENUM_IS_STANDALONE is FALSE).
#   Parent projects can override this by setting -DFORENUM_BUILD_TESTS=ON.
if(FORENUM_IS_STANDALONE)
    option(FORENUM_BUILD_TESTS "Build forenum's self-tests (for development)" ON)
    message(STATUS "Self-tests for 'forenum' are ON by default in standalone mode.")
else()
    option(FORENUM_BUILD_TESTS "Build forenum's self-tests (for submodule)" OFF)
    message(STATUS "Self-tests for 'forenum' are OFF by default when used as a submodule.")
endif()
message(STATUS "To control test building, use CMake option -DFORENUM_BUILD_TESTS=ON/OFF. Current value: ${FORENUM_BUILD_TESTS}")

if(FORENUM_BUILD_TESTS)
    message(STATUS "Configuring self-tests for 'forenum'...")

    # Enable CTest, CMake's testing framework.
    # This can be called multiple times; safe if parent project also calls it.
    enable_testing()

    # Define the test executable.
    add_executable(run_forenum_tests tests/test_forenum.f90)
    message(STATUS "  Added test executable 'run_forenum_tests'.")

    # Link the test executable against our 'mod_forenum' library.
    # This ensures the test program can use the enumeration module.
    target_link_libraries(run_forenum_tests PRIVATE mod_forenum)
    message(STATUS "  Linked 'run_forenum_tests' against 'mod_forenum'.")

    # Add the test to CTest.
    # 'ctest' will run 'run_forenum_tests'. The test passes if the executable returns 0.
    add_test(NAME ForenumFunctionalityTest COMMAND run_forenum_tests)
    message(STATUS "  Added CTest 'ForenumFunctionalityTest'.")
    message(STATUS "Self-tests configured. Run 'ctest' after building.")
else()
    message(STATUS "Skipping configuration of self-tests for 'forenum' (FORENUM_BUILD_TESTS is OFF).")
endif()

message(STATUS "Finished configuring 'forenum' (Mode: ${PROJECT_NAME}, Standalone: ${FORENUM_IS_STANDALONE}).")
