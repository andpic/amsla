cmake_minimum_required(VERSION 3.1)
project(amsla_data_structures)

# Compile the sources

add_library(amsla_common STATIC "${all_cpp_sources}")

# Link dependencies
target_link_libraries(amsla_common INTERFACE OpenCL::OpenCL)
target_include_directories(amsla_common "${PROJECT_SOURCE_DIR}/include")
