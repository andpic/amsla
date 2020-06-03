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

# ADD SUBDIRECTORIES

add_subdirectory("source/cpp")
add_subdirectory("test/cpp")
