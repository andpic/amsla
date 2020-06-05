/** @file DeviceManagement.cpp
 * Wrapper for the OpenCl library
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

#ifndef _AMSLA_COMMON_DEVICEMANAGEMENT_CPP
#define _AMSLA_COMMON_DEVICEMANAGEMENT_CPP

// System includes
#include <memory>

// Project includes
#include "Assertions.hpp"
#include "DeviceManagement.hpp"

namespace {

// A global variable storing the default context
std::unique_ptr<amsla::common::Context> g_default_context;


// A global variable storing the default device
std::unique_ptr<amsla::common::Device> g_default_device;


// A global variable storing the default device
std::unique_ptr<amsla::common::CommandQueue> g_default_queue;


// Get shared device functions
amsla::common::DeviceSource iExportDeviceFunctions() {
  std::string ret =
#include "derived/device_functions.cl"
      ;
  return amsla::common::DeviceSource(ret);
}


// Replace a substring with another.
std::string iReplaceSubstring(std::string in_string,
                              std::string const to_replace,
                              std::string const replace_with) {
  amsla::common::checkThat(
      !to_replace.empty() && !in_string.empty(),
      "Neither the input string or that to replace can be empty.");

  size_t index = 0;
  while (true) {
    // Locate the substring to replace.
    index = in_string.find(to_replace, index);
    if (index == std::string::npos)
      break;

    // Make the replacement.
    in_string.replace(index, to_replace.length(), replace_with);

    // Advance index forward so the next iteration doesn't pick it up as well.
    index += replace_with.length();
  }
  return in_string;
}

// Remove final '\0' in strings
std::string iRemoveEmptyChar(std::string& a_string) {
  std::size_t string_len = a_string.length();
  if (string_len > 0 && a_string[string_len - 1] == '\0') {
    a_string = a_string.substr(0, string_len - 1);
  }
  return a_string;
}


// Get the names of all OpenCL kernels inside the program
std::vector<std::string> iGetKernelNames(cl::Program const& a_program) {
  std::string names_in_string{a_program.getInfo<CL_PROGRAM_KERNEL_NAMES>() +
                              ';'};
  std::vector<std::string> kernel_names;

  size_t split_position;
  // ";" is the standard delimiter
  std::string delimiter{';'};

  while ((split_position = names_in_string.find(delimiter)) !=
         std::string::npos) {
    // Remove empty terminal character
    std::string curr_name = names_in_string.substr(0, split_position);

    kernel_names.push_back(curr_name);
    names_in_string.erase(0, split_position + delimiter.length());
  }
  return kernel_names;
}


// Create a build error
std::runtime_error iCreateBuildError(cl::Program const& a_program) {
  auto build_log = a_program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(
      amsla::common::defaultDevice());
  std::string message =
      "Error when building OpenCL source:" + '\n' + '\n' + build_log;
  return std::runtime_error(message);
}

}  // namespace

namespace amsla::common {

// Get the default Context
Context& defaultContext(uint const platform_number) {
  if (!g_default_context) {
    // Query platforms
    std::vector<cl::Platform> platforms;
    cl::Platform::get(&platforms);
    assertThat(platforms.size() != 0, "No OpenCL platforms found.");

    // Get list of devices on default platform and create context
    cl_context_properties properties[] = {
        CL_CONTEXT_PLATFORM,
        (cl_context_properties)(platforms[platform_number])(), 0};
    g_default_context =
        std::unique_ptr<Context>(new Context(CL_DEVICE_TYPE_ALL, properties));
  }
  return *g_default_context;
}

Device& defaultDevice(Context const& context) {
  if (!g_default_device) {
    std::vector<cl::Device> devices = context.getInfo<CL_CONTEXT_DEVICES>();
    assertThat(devices.size() > 0,
               "The OpenCL context does not contain any devices.");
    g_default_device = std::unique_ptr<Device>(new Device(devices[0]));
  }
  // Create command queue for first device
  return *g_default_device;
}

CommandQueue defaultQueue(Context const& context) {
  if (!g_default_queue) {
    auto device = defaultDevice(context);

    // Create command queue for first device
    g_default_queue =
        std::unique_ptr<CommandQueue>(new CommandQueue(context, device, 0));
  }

  return *g_default_queue;
}

// Wait until all the operations in the queue are done
void waitAllDeviceOperations() {
  auto queue = defaultQueue();
  queue.finish();
}


// Get the name of the kernel
std::string Kernel::name() {
  std::string ret_string = getInfo<CL_KERNEL_FUNCTION_NAME>();
  return iRemoveEmptyChar(ret_string);
}


// Kernel compilation
Kernel compileKernel(DeviceSource const& kernel_source,
                     std::string const& kernel_name) {
  checkThat(~kernel_source.isEmpty() && kernel_name.length() != 0,
            "Empty kernel provided.");

  auto all_kernels = compileAllKernels(kernel_source);

  for (Kernel& curr_kernel : all_kernels) {
    std::string curr_kernel_name = curr_kernel.name();
    if (curr_kernel_name == kernel_name) {
      return curr_kernel;
    }
  }

  throw std::runtime_error("Source does not contain required kernel.");
}

// Compile all kernels in the source
std::vector<Kernel> compileAllKernels(DeviceSource const& kernel_source) {
  checkThat(~kernel_source.isEmpty(), "Empty kernel provided.");

  auto context = defaultContext();
  std::vector<cl::Device> devices = {defaultDevice()};

  DeviceSource source_to_compile = kernel_source;
  source_to_compile.include(iExportDeviceFunctions());
  std::string source_string = source_to_compile.toString();

  // Build kernel from source string
  cl::Program::Sources source(
      1, std::make_pair(source_string.c_str(), source_string.length()));
  auto program = cl::Program(context, source);
  std::vector<Kernel> all_kernels;

  // Build the kernel and write the error to output
  try {
    program.build(devices);
    auto kernel_names = iGetKernelNames(program);

    // Create kernel objects
    for (auto curr_name : kernel_names)
      all_kernels.push_back(Kernel(program, curr_name));
  } catch (cl::Error err) {
    throw iCreateBuildError(program);
  }

  return all_kernels;
}

// Constructor for DeviceSource objects
DeviceSource::DeviceSource(std::string const source_text) {
  text_ = std::string("\n") + source_text;
}

// Include some other source in the current one.
void DeviceSource::include(DeviceSource const& source_to_include) {
  text_ = source_to_include.text_ + std::string("\n") + text_;
}

// Substitute a macro in the current source with some text.
void DeviceSource::substituteMacro(std::string const macro_name,
                                   std::string const substitute_text) {
  text_ = iReplaceSubstring(text_, "__" + macro_name + "__", substitute_text);
}

// Convert the source to a string
std::string DeviceSource::toString() const {
  return text_;
}

// Check that the kernel is not empty
bool DeviceSource::isEmpty() const {
  return text_.length() == 0;
}

}  // namespace amsla::common

#endif