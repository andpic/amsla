/** @file DeviceManagement.cpp
 *  @brief Wrapper for the OpenCl library
 *
 *  This contains the definition for DataStructure object. Any data structure
 * has abide by this interface.
 *
 *  @author Andrea Picciau <andrea@picciau.net>
 *
 *  @copyright Copyright 2019-2020 Andrea Picciau
 *
 *  @license Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#ifndef _AMSLA_COMMON_PRIVATE_DEVICEMANAGEMENT_HPP
#define _AMSLA_COMMON_PRIVATE_DEVICEMANAGEMENT_HPP

// System includes
#include <tuple>

// Project includes
#include "Assertions.hpp"

namespace {

/** @brief Create an OpenCL buffer
 */
template <class DataType>
std::pair<cl::Buffer, std::size_t> iCreateBuffer(DataType const *array,
                                                 std::size_t num_elements,
                                                 cl_mem_flags const mem_flag) {
  cl::Context context = amsla::common::defaultContext();
  std::size_t bytes_to_copy = sizeof(DataType) * num_elements;
  cl::Buffer out_array = cl::Buffer(context, mem_flag, bytes_to_copy);

  return std::make_pair(out_array, bytes_to_copy);
}

/** @brief Move data to the device
 */
template <class DataType>
cl::Buffer iMoveRawDataToDevice(DataType const *array, std::size_t num_elements,
                                cl_mem_flags const mem_flag) {
  cl::Buffer out_array;
  try {
    std::size_t bytes_to_copy = 0;
    std::tie(out_array, bytes_to_copy) =
        iCreateBuffer(array, num_elements, mem_flag);

    cl::CommandQueue queue = amsla::common::defaultQueue();
    queue.enqueueWriteBuffer(out_array, CL_FALSE, 0, bytes_to_copy, array);
  } catch (cl::Error err) {
    std::cerr << err << std::endl;
    throw err;
  }

  return out_array;
}

}  // namespace

/** @function createBuffer
 *  @brief Create an OpenCL buffer
 */
template <class DataType>
cl::Buffer amsla::common::createBuffer(std::vector<DataType> const &array,
                                       cl_mem_flags const mem_flag) {
  std::pair<cl::Buffer, std::size_t> buffer_and_size =
      iCreateBuffer(&array[0], array.size(), mem_flag);
  return cl::Buffer(buffer_and_size.first());
}

/** @function createBuffer
 *  @brief Create an OpenCL buffer
 */
template <class DataType>
cl::Buffer amsla::common::createBuffer(DataType const &data,
                                       cl_mem_flags const mem_flag) {
  std::pair<cl::Buffer, std::size_t> buffer_and_size =
      iCreateBuffer(&data, 1, mem_flag);
  return cl::Buffer(buffer_and_size.first());
}

/** @function moveToDevice
 *  @brief Move given data to the device and return a buffer
 *  @param host_data Pointer to data on the host.
 *  @param num_elements Number of elements in the host array.
 *  @param access_type Type of access.
 *
 *  Creates a buffer, moves the data to the device without blocking the queue.
 */
template <class DataType>
cl::Buffer amsla::common::moveToDevice(std::vector<DataType> const &array,
                                       cl_mem_flags const mem_flag) {
  return iMoveRawDataToDevice(&array[0], array.size(), mem_flag);
}

template <class DataType>
cl::Buffer amsla::common::moveToDevice(DataType const &host_data,
                                       cl_mem_flags const mem_flag) {
  return iMoveRawDataToDevice(&host_data, 1, mem_flag);
}

/** @function moveToHost
 *  @brief Move given data from the device to the host
 *  @param device_data A buffer for the data on the device
 *  @param host_data Pointer to data on the host.
 *  @param num_elements Number of elements in the host array.
 *
 *  Move the data from the device to the host without blocking the execution
 *  queue.
 */
template <class DataType>
void amsla::common::moveToHost(cl::Buffer const &device_data,
                               DataType *host_data,
                               std::size_t const num_elements) {
  cl::CommandQueue queue = defaultQueue();

  auto bytes_to_copy = sizeof(DataType) * num_elements;
  queue.enqueueReadBuffer(device_data, CL_FALSE, 0, bytes_to_copy, host_data);
}

#endif