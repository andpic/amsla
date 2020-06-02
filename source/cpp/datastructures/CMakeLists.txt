cmake_minimum_required(VERSION 3.1)
project(amsla_datastructures)

# BUILD AS A LIBRARY

include_all_opencl_files()
add_library(amsla_datastructures INTERFACE)

target_include_directories(amsla_datastructures
                           INTERFACE "${PROJECT_SOURCE_DIR}/coo/include")
target_link_libraries(amsla_datastructures INTERFACE amsla_common)
