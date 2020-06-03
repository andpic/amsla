cmake_minimum_required(VERSION 3.1)
project(amsla_tests)

# RUN TESTS USING GOOGLE TEST

enable_testing()
find_package(GTest REQUIRED)
include_directories("${GTEST_INCLUDE_DIRS}")

# BUILD ALL TESTS

function(configure_build amsla_module)
  message(STATUS "Building ${amsla_module}")

  file(GLOB sources "*.cpp")
  set(executable_name "test_${amsla_module}")
  add_executable("${executable_name}" "${sources}")

  # Link to libraries
  target_link_libraries(
    "${executable_name}"
    PRIVATE "${GTEST_BOTH_LIBRARIES}"
    PRIVATE Threads::Threads
    PRIVATE "${amsla_module}")

  add_test("${executable_name}" "${executable_name}")

  install(TARGETS "${executable_name}" DESTINATION "bin")
endfunction(configure_build)

# ADD SUBDIRECTORIES

add_subdirectory("common")
add_subdirectory("datastructures")
