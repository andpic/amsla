/// @file test_DeviceManagement.cpp
/// Tests for the header DeviceManagement in amsla_common.
///
/// @author Andrea Picciau <andrea@picciau.net>
///
/// @copyright Copyright 2019-2020 Andrea Picciau
///
/// @license Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///    http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.

// System includes
#include <gtest/gtest.h>
#include <limits.h>
#include <fstream>
#include <string>
#include <vector>

// Project includes
#include "DeviceManagement.hpp"


/// Check that a DeviceSource object can be created and that a single kernel
/// can be compiled
TEST(DeviceManagement, create_DeviceSource_and_single_Kernel) {
  std::string source_text =
#include "derived/simple_kernels.cl"
      ;
  auto curr_source = amsla::common::DeviceSource(source_text);
  std::string curr_name = "simple_add";
  auto curr_kernel = compileKernel(curr_source, curr_name);
}


// Test that an error is thrown when one tries to compile a bad OpenCL kernel.
TEST(DeviceManagement, bad_OpenCL_source_throws_exception) {
  std::string source_text =
#include "derived/bad_kernel.cl"
      ;
  auto curr_source = amsla::common::DeviceSource(source_text);
  std::string curr_name = "bad_add";
  EXPECT_THROW(compileKernel(curr_source, curr_name), std::runtime_error);
}


// Test that an error is thrown when one tries to compile kernel that is not in
// the given source.
TEST(DeviceManagement, non_existing_kernel_throws_exception) {
  std::string source_text =
#include "derived/simple_kernels.cl"
      ;
  auto curr_source = amsla::common::DeviceSource(source_text);
  std::string curr_name = "add";
  EXPECT_THROW(compileKernel(curr_source, curr_name), std::runtime_error);
}


/// Test that data can be moved to the device without errors
TEST(DeviceManagement, data_moved_to_device_without_errors) {
  std::vector<uint> const row_indices = {1, 2, 3, 4};
  auto device_buffer = amsla::common::moveToDevice(
      row_indices, amsla::common::AccessType::READ_AND_WRITE);
  amsla::common::waitAllDeviceOperations();
}


/// Test that data can be moved to the device and then back to the host without
/// errors
TEST(DeviceManagement, data_moved_to_device_and_back_without_errors) {
  std::vector<uint> const row_indices = {1, 2, 3, 4};
  std::size_t num_rows = row_indices.size();
  auto device_buffer = amsla::common::moveToDevice(
      row_indices, amsla::common::AccessType::READ_AND_WRITE);

  std::vector<uint> data_back =
      amsla::common::moveToHost<uint>(device_buffer, num_rows);

  for (std::size_t i = 0; i < num_rows; i++) {
    EXPECT_EQ(row_indices[i], data_back[i]);
  }
}


/// Check that the copy constructor of DeviceData actually clones the internal
/// data.
///
/// The check is done by copying a DeviceData object and then executing a
/// kernel that increments the data on the original object. If the data was
/// cloned, the copy has retained the original values.
TEST(DeviceManagement, DeviceData_copy_constructor_clones_data) {
  std::string source_text =
#include "derived/simple_kernels.cl"
      ;
  auto curr_source = amsla::common::DeviceSource(source_text);
  auto curr_kernel = compileKernel(curr_source, "simple_increment");

  // Create a first array
  std::vector<uint> const row_indices = {1, 2, 3, 4};
  auto row_indices_size = row_indices.size();
  auto device_buffer = amsla::common::moveToDevice(
      row_indices, amsla::common::AccessType::READ_AND_WRITE);
  amsla::common::waitAllDeviceOperations();

  // Create a clone
  amsla::common::DeviceData device_buffer_clone = device_buffer;
  amsla::common::waitAllDeviceOperations();

  // Execute operations on the clone
  curr_kernel.setArgument(0, device_buffer);
  curr_kernel.run(row_indices_size, row_indices_size);
  amsla::common::waitAllDeviceOperations();

  // Expect the results to be different from the original values
  auto after_kernel =
      amsla::common::moveToHost<std::vector<uint>>(device_buffer_clone);
  auto original =
      amsla::common::moveToHost<std::vector<uint>>(device_buffer_clone);
  for (std::size_t i = 0; i < row_indices_size; i++) {
    EXPECT_EQ(after_kernel[i], original[i] + 1);
  }
}