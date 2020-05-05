// System includes
#include <gtest/gtest.h>
#include <limits.h>
#include <vector>

// Project includes
#include "DeviceManagement.hpp"

namespace {

/** @brief Check that a valid context is created without errors.
 */
TEST(DeviceManagement, context_created_without_errors) {
  cl::Context context = amsla::common::defaultContext();
}

/** @brief Check that a valid device is created without errors.
 */
TEST(DeviceManagement, default_device_created_without_errors) {
  amsla::common::defaultDevice();
}

/** Test that data can be moved to the device without errors
 */
TEST(DeviceManagement, data_moved_to_device_without_errors) {
  std::vector<uint> const row_indices = {1, 2, 3, 4};
  cl::Buffer device_buffer =
      amsla::common::moveToDevice(row_indices, CL_MEM_READ_WRITE);
  amsla::common::waitAllDeviceOperations();
}

}  // namespace