cmake_minimum_required(VERSION 3.1)
project(amsla_source)

# USE OPENCL

find_package(OpenCL REQUIRED)
include_directories("${OpenCL_INCLUDE_DIRS}")
link_directories("${OpenCL_LIBRARY}")

# ADD SUBDIRECTORIES

add_subdirectory("common")
add_subdirectory("datastructures")
