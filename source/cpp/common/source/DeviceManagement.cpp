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

// Write an OpenCL error to a std::ostream
std::ostream& operator<<(std::ostream& a_stream, cl::Error const err) {
  a_stream << "ERROR: " << err.what() << "(" << err.err() << ")";
  return a_stream;
}

namespace {

// A global variable storing the default context
std::unique_ptr<amsla::common::Context> g_default_context;

// A global variable storing the default device
std::unique_ptr<amsla::common::Device> g_default_device;

// A global variable storing the default device
std::unique_ptr<amsla::common::CommandQueue> g_default_queue;

// Get shared device functions
amsla::common::DeviceSource iExportDeviceFunctions(void) {
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
void waitAllDeviceOperations(void) {
  auto queue = defaultQueue();
  queue.finish();
}

// Kernel compilation
Kernel compileKernel(DeviceSource const& kernel_source,
                     std::string const& kernel_name) {
  checkThat(~kernel_source.isEmpty() && kernel_name.length() != 0,
            "Empty kernel provided.");

  auto context = defaultContext();
  std::vector<cl::Device> devices = {defaultDevice()};

  // Build kernel from source string
  std::string source_string = kernel_source.toString();
  cl::Program::Sources source(
      1, std::make_pair(source_string.c_str(), source_string.length()));
  auto program = cl::Program(context, source);
  Kernel kernel;

  // Build the kernel and write the error to output
  try {
    program.build(devices);
    // Create kernel object
    kernel = Kernel(program, kernel_name.c_str());
  } catch (cl::Error err) {
    std::cerr << err << std::endl;
    std::cerr << "=== BUILD SOURCE ===" << std::endl
              << source_string << std::endl;

    if (err.what() == "clBuildProgram") {
      auto build_log = program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(devices[0]);
      std::cerr << "=== BUILD LOG ===" << std::endl << build_log << std::endl;
    }
    throw err;
  }

  return kernel;
}

// Implementation of DeviceSource
DeviceSource::DeviceSource(std::string const source_text) {
  auto source_base = iExportDeviceFunctions();
  DeviceSource added_source(source_text);
  source_base.include(added_source);
  text_ = source_base.toString();
}

// Include some other source in the current one.
void DeviceSource::include(DeviceSource const& source_to_include) {
  text_ = text_ + std::string("\n") + source_to_include.text_;
}

// Substitute a macro in the current source with some text.
void DeviceSource::substituteMacro(std::string const macro_name,
                                   std::string const substitute_text) {
  text_ = iReplaceSubstring(text_, "__" + macro_name + "__", substitute_text);
}

// Convert the source to a string
std::string DeviceSource::toString(void) const {
  return text_;
}

// Check that the kernel is not empty
bool DeviceSource::isEmpty(void) const {
  return text_.length() == 0;
}

}  // namespace amsla::common

#endif