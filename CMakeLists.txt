cmake_minimum_required(VERSION 3.1)
project(amsla)

# SYSTEM-WIDE BUILD SETTINGS

set(DCMAKE_GENERATOR_PLATFORM x64)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# CONFIGURE CODE COVERAGE

option(CODE_COVERAGE "Enable coverage reporting" OFF)

if(CODE_COVERAGE AND CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  message(STATUS "Configuring build for code coverage")

  # Add required flags (GCC & LLVM/Clang)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage")
  set(CMAKE_EXE_LINKER_FLAGS "--coverage")
endif()

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

add_subdirectory("source/cpp")
add_subdirectory("test/cpp")
