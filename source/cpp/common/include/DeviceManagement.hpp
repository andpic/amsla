/** @file DeviceManagement.hpp
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

#ifndef _AMSLA_COMMON_DEVICEMANAGEMENT_HPP
#define _AMSLA_COMMON_DEVICEMANAGEMENT_HPP

#define __CL_ENABLE_EXCEPTIONS

// System includes
#include <CL/cl.hpp>
#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

/** @function operator<<
 *  @brief Write an OpenCL error to a standard stream
 *  @param a_stream Output stream.
 *  @param err An OpenCL error.
 */
std::ostream &operator<<(std::ostream &a_stream, cl::Error const err);

namespace amsla::common {

/** @function defaultContext
 * @brief Get the default OpenCL context
 */
cl::Context &defaultContext(void);

/** @function defaultDevice
 *  @brief Get the default OpenCL device.
 */
cl::Device &defaultDevice(cl::Context const &context = defaultContext());

/** @function defaultQueue
 *  @brief Get the default OpenCL command queue.
 */
cl::CommandQueue defaultQueue(cl::Context const &context = defaultContext());

/** @function createBuffer
 *  @brief Create an OpenCL buffer
 */
template <class DataType>
cl::Buffer createBuffer(std::size_t const num_elements = 1,
                        cl_mem_flags const mem_flag = CL_MEM_READ_WRITE);

/** @function moveToDevice
 *  @brief Move given data to the device and return a buffer
 *  @param host_data Pointer to data on the host.
 *  @param num_elements Number of elements in the host array.
 *  @param access_type Type of access.
 *
 *  Creates a buffer, moves the data to the device without blocking the queue.
 */
template <class DataType>
cl::Buffer moveToDevice(std::vector<DataType> const &host_data,
                        cl_mem_flags const mem_flag);

template <class DataType>
cl::Buffer moveToDevice(DataType const &host_data, cl_mem_flags const mem_flag);

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
std::vector<DataType> moveToHost(cl::Buffer const &device_data,
                                 std::size_t const num_elements);

template <class DataType>
DataType moveToHost(cl::Buffer const &device_data);

/** @function waitAllDeviceOperations
 *  @brief Wait until all the operations on the device are completed
 */
void waitAllDeviceOperations(void);

/** @brief Compile a kernel
 *
 *  Given the source of the kernel as a string and the kernel's name, compile
 * it
 *
 *  @params kernel_source The source for the kernel.
 *  @params kernel_name The name of the kernel in the source.
 */
cl::Kernel compileKernel(std::string const &kernel_source,
                         std::string const &kernel_name);

}  // namespace amsla::common

#include "private/DeviceManagement.hpp"

#endif