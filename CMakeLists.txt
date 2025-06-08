cmake_minimum_required(VERSION 3.10)

# ==============================================================================
# SECTION 1: Project Initialization & Mode Detection
# ==============================================================================
# This section determines if 'fortenum' is being built as a standalone project
# (e.g., for development and testing of 'fortenum' itself) or as a submodule
# included by a parent project. The behavior of subsequent sections,
# particularly regarding test building, will adapt based on this mode.

if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
    # --- STANDALONE MODE ---
    # This CMakeLists.txt is for the top-level project. This typically means
    # you are developing 'fortenum' itself.
    set(FORTENUM_IS_STANDALONE TRUE)
    project(fortenum VERSION 3.0.0 LANGUAGES Fortran)
    message(STATUS "Configuring 'fortenum' as a standalone project (for development/testing).")

    # Standalone-specific configurations (examples):
    if(NOT CMAKE_BUILD_TYPE)
        set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose build type: Debug Release RelWithDebInfo MinSizeRel" FORCE)
        message(STATUS "Standalone fortenum: Defaulting CMAKE_BUILD_TYPE to Debug for development.")
    endif()
    # You might also set CMAKE_Fortran_MODULE_DIRECTORY here if desired for standalone builds, e.g.:
    # set(CMAKE_Fortran_MODULE_DIRECTORY \"${CMAKE_BINARY_DIR}/modules\")
else()
    # --- SUBMODULE MODE ---
    # 'fortenum' is being included by another (parent) CMake project.
    # We use project(name NONE) to set our project name for this scope ('fortenum_project')
    # without re-initializing languages or interfering with the parent project's setup.
    set(FORTENUM_IS_STANDALONE FALSE)
    project(fortenum NONE)
    message(STATUS "Configuring 'fortenum' as a submodule (part of parent project: ${CMAKE_PROJECT_NAME}).")
endif()

# ==============================================================================
# SECTION 2: Core Library Definition (For Consumers of 'fortenum')
# ==============================================================================
# This is the primary section relevant to users who want to incorporate 'fortenum'
# into their own CMake projects. It defines the 'mod_fortenum' INTERFACE library
# target, which makes the Fortran enumeration module available.

message(STATUS "Defining 'mod_fortenum' INTERFACE library target...")

# 'mod_fortenum' is an INTERFACE library. It doesn't compile into a separate
# .a or .so file. Instead, its source files and include directories are
# "interfaced" to any target that links against it.
add_library(fortenum INTERFACE)

# Specify the source file(s) that constitute the 'fortenum' library.
# When another target links to 'mod_fortenum', CMake ensures this source file
# is compiled as part of that target.
target_sources(fortenum INTERFACE
    "${CMAKE_CURRENT_SOURCE_DIR}/src/fortenum.f90"
)

# Specify the include directories required to use 'mod_fortenum'.
# This allows consuming projects to 'use fortenum' and for
# the compiler to locate 'fortenum.f90' and its generated .mod file.
target_include_directories(fortenum INTERFACE
    "${CMAKE_CURRENT_SOURCE_DIR}/src"  # Directory containing fortenum.f90
)

message(STATUS "'mod_fortenum' library defined. Link against it in your project.")

# ==============================================================================
# SECTION 3: Self-Testing Framework (Primarily for Developers of 'fortenum')
# ==============================================================================
# This section configures the build of 'fortenum's own internal tests.
# If you are simply using 'fortenum' as a library in your project, you can
# generally ignore this section. These tests are for ensuring 'fortenum' itself
# works correctly during its development.

# Option to control building of self-tests:
# - Defaults to ON if 'fortenum' is built standalone (FORTENUM_IS_STANDALONE is TRUE).
# - Defaults to OFF if 'fortenum' is a submodule (FORTENUM_IS_STANDALONE is FALSE).
#   Parent projects can override this by setting -DFORTENUM_BUILD_TESTS=ON.
if(FORTENUM_IS_STANDALONE)
    option(FORTENUM_BUILD_TESTS "Build fortenum's self-tests (for development)" ON)
    message(STATUS "Self-tests for 'fortenum' are ON by default in standalone mode.")
else()
    option(FORTENUM_BUILD_TESTS "Build fortenum's self-tests (for submodule)" OFF)
    message(STATUS "Self-tests for 'fortenum' are OFF by default when used as a submodule.")
endif()
message(STATUS "To control test building, use CMake option -DFORTENUM_BUILD_TESTS=ON/OFF. Current value: ${FORTENUM_BUILD_TESTS}")

if(FORTENUM_BUILD_TESTS)
    message(STATUS "Configuring self-tests for 'fortenum'...")

    # Enable CTest, CMake's testing framework.
    # This can be called multiple times; safe if parent project also calls it.
    enable_testing()

    # Define the test executable.
    add_executable(run_fortenum_tests tests/test_fortenum.f90)
    message(STATUS "  Added test executable 'run_fortenum_tests'.")

    # Link the test executable against our 'mod_fortenum' library.
    # This ensures the test program can use the enumeration module.
    target_link_libraries(run_fortenum_tests PRIVATE fortenum)
    message(STATUS "  Linked 'run_fortenum_tests' against 'fortenum'.")

    # Add the test to CTest.
    # 'ctest' will run 'run_fortenum_tests'. The test passes if the executable returns 0.
    add_test(NAME fortenumFunctionalityTest COMMAND run_fortenum_tests)
    message(STATUS "  Added CTest 'fortenumFunctionalityTest'.")
    message(STATUS "Self-tests configured. Run 'ctest' after building.")
else()
    message(STATUS "Skipping configuration of self-tests for 'fortenum' (FORTENUM_BUILD_TESTS is OFF).")
endif()

message(STATUS "Finished configuring 'fortenum' (Mode: ${PROJECT_NAME}, Standalone: ${FORTENUM_IS_STANDALONE}).")
