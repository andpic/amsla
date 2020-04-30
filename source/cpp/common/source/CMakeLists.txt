cmake_minimum_required(VERSION 3.1)

### HANDLE OPENCL SOURCES

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

### BUILD AS A LIBRARY

file(GLOB all_cpp_sources "*.cpp")
add_library(amsla_common STATIC 
    "${all_cpp_sources}")

target_include_directories(amsla_common PUBLIC 
    "${PROJECT_SOURCE_DIR}/include")
target_link_libraries(amsla_common PUBLIC OpenCL::OpenCL)
