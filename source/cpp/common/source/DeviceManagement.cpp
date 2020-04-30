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

#ifndef _AMSLA_COMMON_DEVICEMANAGEMENT_CPP
#define _AMSLA_COMMON_DEVICEMANAGEMENT_CPP

// System includes
#include <memory>

// Project includes
#include "Assertions.hpp"
#include "DeviceManagement.hpp"

/** @function operator<<
 *  @brief Write an OpenCL error to a standard stream
 *  @param a_stream Output stream.
 *  @param err An OpenCL error.
 */
std::ostream &operator<<(std::ostream &a_stream, cl::Error const err) {
  a_stream << "ERROR: " << err.what() << "(" << err.err() << ")";
  return a_stream;
}

namespace {

/** @brief A global variable storing the default context
 */
std::unique_ptr<cl::Context> g_default_context;

/** @brief A global variable storing the default device
 */
std::unique_ptr<cl::Device> g_default_device;

}  // namespace

/** @function defaultContext
 * @brief Get the default OpenCL context
 */
cl::Context &amsla::common::defaultContext(void) {
  if (!g_default_context) {
    // Query platforms
    std::vector<cl::Platform> platforms;
    cl::Platform::get(&platforms);
    amsla::common::assert_that(platforms.size() != 0,
                               "No OpenCL platforms found.");

    // Get list of devices on default platform and create context
    cl_context_properties properties[] = {
        CL_CONTEXT_PLATFORM, (cl_context_properties)(platforms[0])(), 0};
    g_default_context = std::unique_ptr<cl::Context>(
        new cl::Context(CL_DEVICE_TYPE_ALL, properties));
  }
  return *g_default_context;
}

/** @function defaultDevice
 *  @brief Get the default OpenCL device.
 */
cl::Device &amsla::common::defaultDevice(cl::Context const &context) {
  if (!g_default_device) {
    std::vector<cl::Device> devices = context.getInfo<CL_CONTEXT_DEVICES>();
    amsla::common::assert_that(
        devices.size() > 0, "The OpenCL context does not contain any devices.");
    g_default_device = std::unique_ptr<cl::Device>(new cl::Device(devices[0]));
  }
  // Create command queue for first device
  return *g_default_device;
}

/** @function defaultQueue
 *  @brief Get the default OpenCL command queue.
 */
cl::CommandQueue amsla::common::defaultQueue(cl::Context const &context) {
  cl::Device device = defaultDevice(context);

  // Create command queue for first device
  return cl::CommandQueue(context, device, 0);
}

/** @function waitAllDeviceOperations
 *  @brief Wait until all the operations on the device are completed
 */
void amsla::common::waitAllDeviceOperations(void) {
  cl::CommandQueue queue = defaultQueue();
  queue.finish();
}

/** @brief Compile a kernel
 *
 *  Given the source of the kernel as a string and the kernel's name, compile
 * it
 *
 *  @params kernel_source The source for the kernel.
 *  @params kernel_name The name of the kernel in the source.
 */
cl::Kernel amsla::common::compileKernel(std::string const &kernel_source,
                                        std::string const &kernel_name) {
  check_that(kernel_source.length() != 0 && kernel_name.length() != 0,
             "Empty kernel provided.");
  cl::Context context = defaultContext();
  std::vector<cl::Device> devices = {defaultDevice()};

  // Build kernel from source string
  cl::Program::Sources source(
      1, std::make_pair(kernel_source.c_str(), kernel_source.length()));
  cl::Program program = cl::Program(context, source);
  cl::Kernel kernel;

  // Build the kernel and write the error to output
  try {
    program.build(devices);
    // Create kernel object
    kernel = cl::Kernel(program, kernel_name.c_str());
  } catch (cl::Error err) {
    std::cerr << err << std::endl;
    std::cerr << "=== BUILD SOURCE ===" << std::endl
              << kernel_source << std::endl;

    if (err.what() == "clBuildProgram") {
      auto build_log = program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(devices[0]);
      std::cerr << "=== BUILD LOG ===" << std::endl << build_log << std::endl;
    }
    throw err;
  }

  return kernel;
}

#endif