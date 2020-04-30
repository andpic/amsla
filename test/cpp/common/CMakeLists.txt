cmake_minimum_required(VERSION 3.1)
project(amsla_common_tests)

# Find all the test files
file(GLOB all_test_sources "test_*.cpp")

# Loop through all the test files

foreach(file_global ${all_test_sources})
    configure_build("${file_global}" amsla_common)
endforeach()