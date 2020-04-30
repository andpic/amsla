// System includes
#include <gtest/gtest.h>
#include <limits.h>
#include <vector>

// Project includes
#include "DeviceManagement.hpp"

namespace {

// Tests factorial of negative numbers.
TEST(OpenCL, defaultContext) {
  cl::Context context = amsla::common::defaultContext();
}

// Tests factorial of negative numbers.
TEST(OpenCL, defaultDevice) { amsla::common::defaultDevice(); }

// Tests factorial of negative numbers.
TEST(OpenCL, moveToDevice) {
  std::vector<uint> const row_indices = {1, 2, 3, 4};
  cl::Buffer device_buffer =
      amsla::common::moveToDevice(row_indices, CL_MEM_READ_WRITE);
  amsla::common::waitAllDeviceOperations();
}

}  // namespace