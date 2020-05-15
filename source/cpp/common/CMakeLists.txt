cmake_minimum_required(VERSION 3.1)
project(amsla_common)

### BUILD AS A LIBRARY

include_all_OpenCL_files()

file(GLOB_RECURSE all_cpp_sources "*.cpp")
add_library(amsla_common STATIC 
    "${all_cpp_sources}")

target_include_directories(amsla_common PUBLIC 
    "${PROJECT_SOURCE_DIR}/include")
target_link_libraries(amsla_common PUBLIC OpenCL::OpenCL)