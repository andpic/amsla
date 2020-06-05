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
#include <vector>

namespace amsla::common {

// Start ignoring attributes in template argument
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wignored-attributes"

/// Convert a host type to a class (OpenCL) type
/// @param HostType The host type being converted.
///
/// Example usage:
///     ToDeviceType<double>::type
template <typename HostType>
struct ToDeviceType {
  typedef void type;

 private:
  // Make this struct non-instantiable
  ToDeviceType(){};
};

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

// Stop ignoring attributes on template argument
#pragma GCC diagnostic pop


/// Return the name of the type as a string
/// @param BaseType The type we want the name of.
///
/// Example usage:
///     auto type_name = typeName<double>();
///     type_name is "double"
template <typename Type>
static std::string typeName();


/// Wrapper for an OpenCL context
using Context = cl::Context;


/// Wrapper for an OpenCL device
using Device = cl::Device;


/// Wrapper for an OpenCL queue
using CommandQueue = cl::CommandQueue;


/// Types of access to device data.
enum class AccessType { READ_ONLY, WRITE_ONLY, READ_AND_WRITE };


/// Wrapper for an OpenCL buffer
using Buffer = cl::Buffer;


/// Sources for the kernel
class DeviceSource {
 public:
  /// Create a device source
  /// @param source_text Text of the source file.
  explicit DeviceSource(std::string const source_text = "");

  /// Include some other source in the current one.
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
  std::string text_;
};


/// Wrapper for an OpenCL kernel
class Kernel : public cl::Kernel {
 public:
  /// Get the name of the current kernel.
  std::string name();

  // Friend functions to construct a kernel object
  friend Kernel compileKernel(DeviceSource const& kernel_source,
                              std::string const& kernel_name);

  friend std::vector<Kernel> compileAllKernels(
      DeviceSource const& kernel_source);

 private:
  // Construct a kernel object
  Kernel(cl::Program const& program, std::string const& name)
      : cl::Kernel(program, name.c_str(), nullptr){};
};


/// Get the default context
/// @param platform_number The number of platform given in clinfo
Context& defaultContext(uint const platform_number = 0);


/// Get the default OpenCL device.
Device& defaultDevice(Context const& context = defaultContext());


/// Get the default OpenCL command queue.
CommandQueue defaultQueue(Context const& context = defaultContext());


/// Create an OpenCL buffer
template <typename DataType>
Buffer createBuffer(std::size_t const num_elements = 1,
                    AccessType const mem_flag = AccessType::READ_AND_WRITE);


/// Move given data to the device and return a buffer
/// @param host_data Pointer to data on the host.
/// @param num_elements Number of elements in the host array.
/// @param access_type Type of access.
///
/// Creates a buffer, moves the data to the device without blocking the queue.
template <typename DataType>
Buffer moveToDevice(std::vector<DataType> const& host_data,
                    AccessType const mem_flag = AccessType::READ_AND_WRITE);

template <typename DataType>
Buffer moveToDevice(DataType const& host_data,
                    AccessType const mem_flag = AccessType::READ_AND_WRITE);


/// Move given data from the device to the host
/// @param device_data A buffer for the data on the device
/// @param host_data Pointer to data on the host.
/// @param num_elements Number of elements in the host array.
///
/// Move the data from the device to the host without blocking the execution
/// queue.
template <typename DataType>
std::vector<DataType> moveToHost(Buffer const& device_data,
                                 std::size_t const num_elements);

template <typename DataType>
DataType moveToHost(Buffer const& device_data);


/// Wait until all the operations on the device are completed
void waitAllDeviceOperations();


/// Compile an OpenCL kernel
///
/// Given the source of the kernel as a string and the kernel's name, compile
/// it
///
/// @params kernel_source The source for the kernel.
/// @params kernel_name The name of the kernel in the source.
Kernel compileKernel(DeviceSource const& kernel_source,
                     std::string const& kernel_name);


/// Compile all OpenCL kernels in the source
///
/// Given the source of the kernel as a string and the kernel's name, compile
/// it
///
/// @params kernel_source The source for the kernel.
/// @params kernel_name The name of the kernel in the source.
std::vector<Kernel> compileAllKernels(DeviceSource const& kernel_source);


/// Initialise an array of a device type with some given data
/// @param copy_to A pointer to the device-like data.
/// @param copy_from A vector of data on the host.
/// @param max_elements The maximum number of elements in copy_to.
template <typename HostType>
void initialiseDeviceLikeArray(void* const copy_to,
                               std::vector<HostType> const& copy_from,
                               std::size_t const max_elements);

}  // namespace amsla::common

#include "details/DeviceManagement.hpp"

#endif