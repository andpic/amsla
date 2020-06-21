/// @file DeviceManagement.hpp
/// Wrapper for the OpenCl library
///
/// This contains the definition for DataStructure object. Any data structure
/// has abide by this interface.
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

#ifndef _AMSLA_COMMON_DEVICEMANAGEMENT_HPP
#define _AMSLA_COMMON_DEVICEMANAGEMENT_HPP

#define __CL_ENABLE_EXCEPTIONS
#define CL_TARGET_OPENCL_VERSION 120

// System includes
#include <CL/cl.hpp>
#include <algorithm>
#include <iostream>
#include <string>
#include <utility>
#include <vector>

namespace amsla::common {

/// Convert a host type to a class (OpenCL) type
/// @param HostType The host type being converted.
///
/// Example usage:
///     ToDeviceType<double>::type
template <typename HostType>
struct ToDeviceType {
  typedef HostType type;

 private:
  // Make this struct non-instantiable
  ToDeviceType(){};
};


/// Return the name of the type as a string
/// @param BaseType The type we want the name of.
///
/// Example usage:
///     auto type_name = typeName<double>();
///     type_name is "double"
template <typename Type>
static std::string typeName();


/// Initialise an array of the DeviceType coresponding to the given HostType.
/// @param copy_from Input array.
/// @param copy_to Where to copy the data to.
/// @param max_elements Elements in copy_to.
///
/// The difference of max_elements and the length of copy_from is filled with
/// zeros.
template <typename HostType,
          typename DeviceType = typename ToDeviceType<HostType>::type>
void initialiseDeviceArray(std::vector<HostType> const& copy_from,
                           void* const copy_to,
                           std::size_t const max_elements);


/// Convert vector to a device array
/// @param copy_from Input array.
template <typename HostType,
          typename DeviceType = typename ToDeviceType<HostType>::type>
std::pair<DeviceType*, std::size_t> convertToDeviceArray(
    std::vector<HostType> const& copy_from);


/// Sources for the kernel
class DeviceSource {
 public:
  /// Create a device source
  /// @param source_text Text of the source file.
  explicit DeviceSource(std::string const source_text);

  /// Create a copy of a device source
  /// @param another_source Source to be copied.
  DeviceSource(DeviceSource const& another_source);

  /// Destructor
  ~DeviceSource();

  /// Copy assignment
  /// @param other Another device_source to copy from.
  DeviceSource& operator=(DeviceSource const& other);

  /// Prepend some other source to the current one
  /// @param source_to_include Other source to include;
  void include(DeviceSource const& source_to_include);

  /// Substitute a macro in the current source with some text.
  /// @param macro_name In the source, it appears between double underscores.
  /// @param substitute_text Replaces the whole macro (including undercores).
  void substituteMacro(std::string const macro_name,
                       std::string const substitute_text);

  /// Convert the source to a string.
  std::string toString() const;

  /// Check if the source is empty.
  bool isEmpty() const;

 private:
  class DeviceSourceImpl;
  std::unique_ptr<DeviceSourceImpl> impl_;
};

/// Types of access to device data.
enum class AccessType { READ_ONLY, WRITE_ONLY, READ_AND_WRITE };


/// Data on the device.
class DeviceData {
 public:
  /// Constructor
  /// @param byte_size The number of bytes allocated on the device
  /// @param mem_flag How the data can be accessed.
  DeviceData(std::size_t const byte_size,
             AccessType const mem_flag = AccessType::READ_AND_WRITE);

  /// Constructor from OpenCL buffer
  /// @param a_buffer An OpenCL buffer object
  /// @param byte_size The number of bytes allocated on the device
  /// @param mem_flag How the data can be accessed.
  explicit DeviceData(cl::Buffer const& a_buffer,
                      std::size_t const byte_size,
                      AccessType const mem_flag = AccessType::READ_AND_WRITE);

  /// Move constructor from OpenCL buffer
  /// @param a_buffer An OpenCL buffer object
  /// @param byte_size The number of bytes allocated on the device
  /// @param mem_flag How the data can be accessed.
  explicit DeviceData(cl::Buffer&& a_buffer,
                      std::size_t const byte_size,
                      AccessType const mem_flag = AccessType::READ_AND_WRITE);

  /// Create a copy of device data
  /// @param other Data to be copied.
  DeviceData(DeviceData const& other);

  /// Destructor
  ~DeviceData();

  /// Copy assignment
  /// @param other Another device data to copy from.
  DeviceData& operator=(const DeviceData& other);

  /// Get the DeviceData as an OpenCL buffer
  cl::Buffer const& toOpenClBuffer() const;

 private:
  class DeviceDataImpl;
  std::unique_ptr<DeviceDataImpl> impl_;
};


/// Move given data to the device and return a buffer
/// @param host_data Pointer to data on the host.
/// @param num_elements Number of elements in the host array.
/// @param access_type Type of access.
///
/// Creates a buffer, moves the data to the device without blocking the queue.
template <typename DataType>
DeviceData moveToDevice(DataType const& host_data,
                        AccessType const mem_flag = AccessType::READ_AND_WRITE);


/// Move given data from the device to the host
/// @param device_data A buffer for the data on the device
///
/// Move the data from the device to the host without blocking the execution
/// queue.
template <typename DataType>
DataType moveToHost(DeviceData const& device_data);

/// Move given data from the device to the host, when the data is an array.
/// @param device_data A buffer for the data on the device
/// @param num_elements Number of elements in the host array.
///
/// Move the data from the device to the host without blocking the execution
/// queue.
template <typename DataType>
std::vector<DataType> moveToHost(DeviceData const& device_data,
                                 std::size_t const num_elements);


class DeviceKernel;

/// Compile an OpenCL kernel
///
/// Given the source of the kernel as a string and the kernel's name, compile
/// it
///
/// @params kernel_source The source for the kernel.
/// @params kernel_name The name of the kernel in the source.
DeviceKernel compileKernel(DeviceSource const& kernel_source,
                           std::string const& kernel_name);

/// Compile all OpenCL kernels in the source
///
/// Given the source of the kernel as a string and the kernel's name, compile
/// it
///
/// @params kernel_source The source for the kernel.
/// @params kernel_name The name of the kernel in the source.
std::vector<DeviceKernel> compileAllKernels(DeviceSource const& kernel_source);


/// Wrapper for an OpenCL kernel
class DeviceKernel {
 public:
  /// Create a copy of device kernel
  /// @param other Data to be copied.
  DeviceKernel(DeviceKernel const& other);

  /// Destructor
  ~DeviceKernel();

  /// Copy assignment
  /// @param other Another kernel to copy from.
  DeviceKernel& operator=(const DeviceKernel& other);

  /// Get the name of the current kernel.
  std::string name();

  /// Set an argument to the kernel
  /// @param argument_number Number of the argument to be set.
  /// @param device_data Device data to be given as argument.
  void setArgument(uint const argument_number, DeviceData const& device_data);

  /// Run the device kernel
  /// @param num_threads Total number of threads to execute the kernel with
  /// @param num_threads_per_block Number of blocks to group the threads into.
  void run(std::size_t num_threads, std::size_t num_threads_per_block);

  // Friend functions to construct a kernel object

  friend DeviceKernel compileKernel(DeviceSource const& kernel_source,
                                    std::string const& kernel_name);

  friend std::vector<DeviceKernel> compileAllKernels(
      DeviceSource const& kernel_source);

 private:
  // Construct a kernel object
  DeviceKernel(cl::Program const& program, std::string const& name);

  class DeviceKernelImpl;
  std::unique_ptr<DeviceKernelImpl> impl_;
};


/// Wait until all the operations on the device are completed
void waitAllDeviceOperations();

}  // namespace amsla::common

#include "details/DeviceManagement.hpp"

#endif