cmake_minimum_required(VERSION 3.1)
project(amsla_tests)

# RUN TESTS USING GOOGLE TEST

# Download and unpack googletest at configure time
configure_file(CMakeLists.txt.in googletest-download/CMakeLists.txt)
execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/googletest-download )
if(result)
  message(FATAL_ERROR "CMake step for googletest failed: ${result}")
endif()
execute_process(COMMAND ${CMAKE_COMMAND} --build .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/googletest-download )
if(result)
  message(FATAL_ERROR "Build step for googletest failed: ${result}")
endif()
# Prevent overriding the parent project's compiler/linker
# settings on Windows
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
# Add googletest directly to our build. This defines
# the gtest and gtest_main targets.
add_subdirectory(${CMAKE_CURRENT_BINARY_DIR}/googletest-src
                 ${CMAKE_CURRENT_BINARY_DIR}/googletest-build
                 EXCLUDE_FROM_ALL)

# USE PTHREADS 

find_package(Threads)

# BUILD ALL TESTS
enable_testing()

function(configure_build amsla_module)
  message(STATUS "Building ${amsla_module}")

  file(GLOB sources "*.cpp")
  set(executable_name "test_${amsla_module}")
  add_executable("${executable_name}" "${sources}")

  # Link to libraries
  target_link_libraries(
    "${executable_name}"
    PRIVATE gtest_main
    PRIVATE Threads::Threads
    PRIVATE "${amsla_module}")

  add_test("${executable_name}" "${executable_name}")

  install(TARGETS "${executable_name}" DESTINATION "bin")
endfunction(configure_build)

# ADD SUBDIRECTORIES

add_subdirectory("common")
add_subdirectory("datastructures")
