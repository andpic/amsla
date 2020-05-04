cmake_minimum_required(VERSION 3.1)
project(amsla)

### SYSTEM-WIDE BUILD SETTINGS

set(DCMAKE_GENERATOR_PLATFORM x64)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

### USE OPENCL

find_package(OpenCL REQUIRED)
include_directories("${OpenCL_INCLUDE_DIRS}")
link_directories("${OpenCL_LIBRARY}")

### ADD SUBDIRECTORIES

add_subdirectory("source/cpp")
add_subdirectory("test/cpp")
