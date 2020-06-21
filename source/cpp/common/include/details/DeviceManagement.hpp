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

// Initialise an array of the DeviceType coresponding to the given HostType.
template <typename HostType,
          typename DeviceType = typename ToDeviceType<HostType>::type>
void initialiseDeviceArray(std::vector<HostType> const& copy_from,
                           DeviceType* const copy_to,
                           std::size_t const max_elements) {
  auto const num_elements = copy_from.size();
  amsla::common::checkThat(copy_to && max_elements >= num_elements,
                           "Cannot initialise the array.");
  amsla::common::checkThat(copy_to, "Cannot copy to nullptr");

  // Convert copy_from to the corresponding device type. For example:
  // double -> cl_double
  auto from_size = copy_from.size();
  std::copy(copy_from.begin(), copy_from.end(), copy_to);
  std::fill(&copy_to[num_elements], &copy_to[max_elements],
            static_cast<DeviceType>(0));
}


// Convert a host vector to the corresponding device array
template <typename HostType,
          typename DeviceType = typename ToDeviceType<HostType>::type>
std::pair<DeviceType*, std::size_t> convertToDeviceArray(
    std::vector<HostType> const& copy_from) {
  auto array_size = copy_from.size();
  DeviceType* ret = new DeviceType[array_size];
  std::size_t num_bytes = sizeof(DeviceType) * array_size;
  initialiseDeviceArray(copy_from, ret, array_size);
  return std::make_pair(ret, num_bytes);
}


// Move data to the device
template <typename DataType>
DeviceData moveToDevice(std::vector<DataType> const& array,
                        AccessType const mem_flag) {
  // Convert host DataType to device DeviceType
  std::size_t array_size = array.size();
  std::size_t num_bytes = 0;
  using DeviceType = typename ToDeviceType<DataType>::type;
  DeviceType* device_like_array;
  std::tie(device_like_array, num_bytes) = convertToDeviceArray(array);
  DeviceData ret(amsla::common::details::writeRawDataToDevice(
                     device_like_array, num_bytes, mem_flag),
                 num_bytes, mem_flag);
  delete device_like_array;
  return ret;
}

template <typename DataType>
DeviceData moveToDevice(DataType const& host_data, AccessType const mem_flag) {
  // Convert host DataType to device DeviceType
  using DeviceType = typename amsla::common::ToDeviceType<DataType>::type;
  DeviceType device_like_data(host_data);

  // Write as DeviceType
  std::size_t num_bytes = sizeof(DeviceType);
  return DeviceData(amsla::common::details::writeRawDataToDevice(
                        &device_like_data, num_bytes, mem_flag),
                    num_bytes, mem_flag);
}


// Move data to the host, with a blocking read
template <typename DataType>
std::vector<DataType> moveToHost(DeviceData const& device_data,
                                 std::size_t const num_elements) {
  // Convert host DataType to device DeviceType
  using DeviceType = typename amsla::common::ToDeviceType<DataType>::type;
  DeviceType device_like_array[num_elements];

  // Read into a DeviceType array
  std::size_t num_bytes = sizeof(DeviceType) * num_elements;
  amsla::common::details::readRawDataFromDevice(
      device_data.toOpenClBuffer(), num_bytes,
      static_cast<void*>(device_like_array));

  // Copy data into a DataType (host) vector
  std::vector<DataType> ret_array(num_elements);
  std::copy(&device_like_array[0], &device_like_array[num_elements],
            ret_array.begin());
  return ret_array;
}

template <typename DataType>
DataType moveToHost(DeviceData const& device_data) {
  // Convert host Datatype to device DeviceType
  using DeviceType = typename amsla::common::ToDeviceType<DataType>::type;
  DeviceType device_like_data;

  // Read into a DeviceType
  std::size_t num_bytes = sizeof(DeviceType);
  amsla::common::details::readRawDataFromDevice(device_data.toOpenClBuffer(),
                                                num_bytes, &device_like_data);

  DataType ret_data(device_like_data);
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