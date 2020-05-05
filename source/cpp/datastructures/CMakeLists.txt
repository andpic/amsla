cmake_minimum_required(VERSION 3.1)
project(amsla_datastructures)

# BUILD AS A LIBRARY

include_all_OpenCL_files()
file(GLOB_RECURSE all_cpp_sources "*.cpp")
add_library(amsla_datastructures STATIC 
    "${all_cpp_sources}")

target_include_directories(amsla_datastructures PUBLIC 
    "${PROJECT_SOURCE_DIR}/coo/include")
target_link_libraries(amsla_datastructures PUBLIC amsla_common)
target_link_libraries(amsla_datastructures PUBLIC OpenCL::OpenCL)

