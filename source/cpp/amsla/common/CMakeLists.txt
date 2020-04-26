cmake_minimum_required(VERSION 3.1)
project(struct_kernel_argument)

# GENERAL COMPILATION SETTINGS
set(DCMAKE_GENERATOR_PLATFORM x64)

# USE C++17

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# USE OPENCL

find_package(OpenCL REQUIRED)
include_directories("${OpenCL_INCLUDE_DIRS}")
link_directories("${OpenCL_LIBRARY}")

# GENERATE INCLUDABLE STRINGS FROM OPENCL CODE

# Make the OpenCL kernels includable at buil time
function(make_includable input_file output_file)
    file(READ "${input_file}" content)
    set(delim "for_c++_include")
    set(content "R\"${delim}(\n${content})${delim}\"")
    file(WRITE "${output_file}" "${content}")
endfunction(make_includable)

# Find all the OpenCL files
file(GLOB all_opencl_sources "*.cl")

# Clean the derived directory if it exists
set(derived_dir "${CMAKE_CURRENT_SOURCE_DIR}/derived")
if(EXISTS "${derived_dir}")
    message(STATUS "Cleaning derived/")
    file(REMOVE_RECURSE "${derived_dir}")
endif()

# Loop through all the OpenCL files
foreach(file_global ${all_opencl_sources})
    file(RELATIVE_PATH file_relative "${CMAKE_CURRENT_SOURCE_DIR}" "${file_global}")
    message(STATUS "Making OpenCL file includable: ${file_relative}")
    set(file_derived "${derived_dir}/${file_relative}")
    make_includable("${file_relative}" "${file_derived}")
endforeach()

# USE THREADS

find_package(Threads REQUIRED)

# RUN TESTS USING GOOGLE TEST

enable_testing()
find_package(GTest REQUIRED)
include_directories("${GTEST_INCLUDE_DIRS}")

# BUILD ALL TESTS

function(configure_build input_source)
    get_filename_component(executable_name "${input_source}" NAME_WE)
    add_executable("${executable_name}" "${input_source}")

    # Link to libraries
    target_link_libraries("${executable_name}" OpenCL::OpenCL)
    target_link_libraries("${executable_name}" "${GTEST_BOTH_LIBRARIES}")
    target_link_libraries("${executable_name}" Threads::Threads)

    add_test("${executable_name}" "${executable_name}")

    install(TARGETS "${executable_name}" DESTINATION "bin")
endfunction(configure_build)

# Find all the test files
file(GLOB all_test_sources "test_*.cpp")

# Loop through all the test files
foreach(file_global ${all_test_sources})
    configure_build("${file_global}")
endforeach()