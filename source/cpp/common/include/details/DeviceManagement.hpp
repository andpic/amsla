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

namespace amsla::common::details {

// Move some data to the device
cl::Buffer writeRawDataToDevice(void const* array,
                                std::size_t num_bytes,
                                AccessType const mem_flag);

// Read some data from the device
void readRawDataFromDevice(cl::Buffer const& device_data,
                           std::size_t num_bytes,
                           void* const to);

}  // namespace amsla::common::details


namespace amsla::common {

// Move data to the device
template <typename DataType>
DeviceData moveToDevice(std::vector<DataType> const& array,
                        AccessType const mem_flag) {
  std::size_t num_bytes = sizeof(DataType) * array.size();
  return DeviceData(amsla::common::details::writeRawDataToDevice(
      &array[0], num_bytes, mem_flag));
}

template <typename DataType>
DeviceData moveToDevice(DataType const& host_data, AccessType const mem_flag) {
  std::size_t num_bytes = sizeof(DataType);
  return DeviceData(amsla::common::details::writeRawDataToDevice(
      &host_data, num_bytes, mem_flag));
}


// Move data to the host, with a blocking read
template <typename DataType>
std::vector<DataType> moveToHost(DeviceData const& device_data,
                                 std::size_t const num_elements) {
  std::vector<DataType> ret_array(num_elements);
  std::size_t num_bytes = sizeof(DataType) * num_elements;
  amsla::common::details::readRawDataFromDevice(device_data.toOpenClBuffer(),
                                                num_bytes, &ret_array[0]);
  return ret_array;
}

template <typename DataType>
DataType moveToHost(DeviceData const& device_data) {
  DataType ret_data;
  std::size_t num_bytes = sizeof(DataType);
  amsla::common::details::readRawDataFromDevice(device_data.toOpenClBuffer(),
                                                num_bytes, &ret_data);
  return ret_data;
}

// Return the type to be used on the device
template <>
struct ToDeviceType<float> {
  typedef cl_float type;
};

template <>
struct ToDeviceType<double> {
  typedef cl_double type;
};

template <>
struct ToDeviceType<uint> {
  typedef cl_uint type;
};


// Return the name of the type as a string
template <>
std::string typeName<double>() {
  return std::string("double");
}

template <>
std::string typeName<float>() {
  return std::string("float");
}

template <>
std::string typeName<uint>() {
  return std::string("uint");
}

}  // namespace amsla::common

#endif