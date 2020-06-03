cmake_minimum_required(VERSION 3.1)
project(amsla_source)

# USE OPENCL

find_package(OpenCL REQUIRED)
include_directories("${OpenCL_INCLUDE_DIRS}")
link_directories("${OpenCL_LIBRARY}")

# GENERATE INCLUDABLE STRINGS FROM OPENCL CODE

# Make the OpenCL kernels includable at build time
function(make_includable input_file output_file)
  file(READ "${input_file}" content)
  set(delim "for_c++_include")
  set(content "R\"${delim}(\n${content})${delim}\"")
  file(WRITE "${output_file}" "${content}")
endfunction(make_includable)

# Make the OpenCL files includable
function(include_all_OpenCL_files)

  # Clean the derived directory if it exists
  file(GLOB_RECURSE all_opencl_files "*.cl")
  foreach(curr_opencl_file ${all_opencl_files})
    get_filename_component(curr_folder "${curr_opencl_file}" DIRECTORY)
    if(${curr_folder} MATCHES ".*derived.*")
      if(EXISTS ${curr_folder})
        message(STATUS "Deleting folder ${curr_folder}")
        file(REMOVE_RECURSE "${curr_folder}")
      endif()
    endif()
  endforeach()

  # Loop through all the OpenCL files
  file(GLOB_RECURSE all_opencl_sources "*.cl")
  foreach(curr_opencl_source ${all_opencl_sources})
    get_filename_component(curr_opencl_folder "${curr_opencl_source}" DIRECTORY)
    get_filename_component(curr_opencl_filename "${curr_opencl_source}" NAME)

    message(STATUS "Making OpenCL file includable: ${curr_opencl_source}")
    set(file_derived "${curr_opencl_folder}/derived/${curr_opencl_filename}")
    make_includable("${curr_opencl_source}" "${file_derived}")
  endforeach()
endfunction(include_all_OpenCL_files)

# ADD SUBDIRECTORIES

add_subdirectory("common")
add_subdirectory("datastructures")
