/// @file DeviceManagement.hpp
/// @brief Wrapper for the OpenCl library
///
/// This contains all the definitions and implementations
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

#ifndef _AMSLA_COMMON_DETAILS_DEVICEMANAGEMENT_HPP
#define _AMSLA_COMMON_DETAILS_DEVICEMANAGEMENT_HPP

// System includes
#include <tuple>

// Project includes
#include "Assertions.hpp"

namespace {

// Convert an AccessType object to a cl_mem_flag
cl_mem_flags iConvertToOpenClAccess(
    amsla::common::AccessType const amsla_type) {
  switch (amsla_type) {
    case amsla::common::AccessType::READ_ONLY:
      return CL_MEM_READ_ONLY;
    case amsla::common::AccessType::READ_AND_WRITE:
      return CL_MEM_READ_WRITE;
    case amsla::common::AccessType::WRITE_ONLY:
      return CL_MEM_WRITE_ONLY;
    default:
      throw std::runtime_error("Invalid AccessType");
  }
}


// Wrap an OpenCL error with a std::runtime error
std::runtime_error iWrapOpenClError(cl::Error const& err) {
  std::string message =
      "Error from OpenCL backend:" + '\n' + '\n' + std::string(err.what());
  return std::runtime_error(message);
}


// Move any data to the device
template <typename DataType>
amsla::common::Buffer iMoveRawDataToDevice(
    DataType const* array,
    std::size_t num_elements,
    amsla::common::AccessType const mem_flag) {
  amsla::common::Buffer out_array;

  try {
    std::size_t bytes_to_copy = sizeof(DataType) * num_elements;
    out_array = amsla::common::createBuffer<DataType>(num_elements, mem_flag);

    auto queue = amsla::common::defaultQueue();
    queue.enqueueWriteBuffer(out_array, CL_FALSE, 0, bytes_to_copy, array);
  } catch (cl::Error err) {
    throw iWrapOpenClError(err);
  }

  return out_array;
}

}  // namespace

namespace amsla::common {

// Return the name of the type as a string
template <>
std::string typeName<double>() {
  return std::string("double");
}

template <>
std::string typeName<float>() {
  return std::string("float");
}

// Create a buffer
template <typename DataType>
Buffer createBuffer(std::size_t const num_elements, AccessType const mem_flag) {
  std::size_t bytes_to_copy = sizeof(DataType) * num_elements;
  Buffer out_array(defaultContext(), iConvertToOpenClAccess(mem_flag),
                   bytes_to_copy);
  return out_array;
}

// Move data to the device
template <typename DataType>
Buffer moveToDevice(std::vector<DataType> const& array,
                    AccessType const mem_flag) {
  return iMoveRawDataToDevice(&array[0], array.size(), mem_flag);
}

template <typename DataType>
Buffer moveToDevice(DataType const& host_data, AccessType const mem_flag) {
  return iMoveRawDataToDevice(&host_data, 1, mem_flag);
}

// Move data to the host, with a blocking read
template <typename DataType>
std::vector<DataType> moveToHost(Buffer const& device_data,
                                 std::size_t const num_elements) {
  auto queue = defaultQueue();

  auto bytes_to_copy = sizeof(DataType) * num_elements;
  std::vector<DataType> ret_data(num_elements);
  // Blocking read
  queue.enqueueReadBuffer(device_data, CL_TRUE, 0, bytes_to_copy, &ret_data[0]);
  return ret_data;
}

template <typename DataType>
DataType moveToHost(Buffer const& device_data) {
  auto queue = defaultQueue();

  auto bytes_to_copy = sizeof(DataType);
  DataType ret_data;
  // Blocking read
  queue.enqueueReadBuffer(device_data, CL_TRUE, 0, bytes_to_copy, &ret_data);
  return ret_data;
}

// Intialise device layout on the host
template <typename HostType>
void initialiseDeviceLikeArray(void* const copy_to,
                               std::vector<HostType> const& copy_from,
                               std::size_t const max_elements) {
  auto const num_elements = copy_from.size();
  checkThat(copy_to && max_elements >= num_elements,
            "Cannot initialise the array.");

  // Convert copy_from to the corresponding device type. For example:
  // double -> cl_double
  using DeviceType = typename ToDeviceType<HostType>::type;
  std::vector<DeviceType> device_from(copy_from);

  auto copy_to_device = static_cast<DeviceType*>(copy_to);
  std::copy_n(device_from.begin(), num_elements, copy_to_device);
  std::fill(copy_to_device + num_elements, copy_to_device + max_elements,
            static_cast<DeviceType>(0));
}

}  // namespace amsla::common

#endif