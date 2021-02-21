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

// System includes
#include <memory>

// Project includes
#include "Assertions.hpp"
#include "DeviceManagement.hpp"

namespace {

// A global variable storing the default context
std::unique_ptr<cl::Context> g_default_context;

// Get the default context
cl::Context& iDefaultContext(uint const platform_number = 0) {
  if (!g_default_context) {
    // Query platforms
    std::vector<cl::Platform> platforms;
    cl::Platform::get(&platforms);
    amsla::common::assertThat(platforms.size() != 0,
                              "No OpenCL platforms found.");

    // Get list of devices on default platform and create context
    cl_context_properties properties[] = {
        CL_CONTEXT_PLATFORM,
        (cl_context_properties)(platforms[platform_number])(), 0};
    g_default_context = std::unique_ptr<cl::Context>(
        new cl::Context(CL_DEVICE_TYPE_ALL, properties));
  }
  return *g_default_context;
}


// A global variable storing the default device
std::unique_ptr<cl::Device> g_default_device;

// Get the default OpenCL device
cl::Device& iDefaultDevice(cl::Context const& context = iDefaultContext()) {
  if (!g_default_device) {
    std::vector<cl::Device> devices = context.getInfo<CL_CONTEXT_DEVICES>();
    amsla::common::assertThat(
        devices.size() > 0, "The OpenCL context does not contain any devices.");
    g_default_device = std::unique_ptr<cl::Device>(new cl::Device(devices[0]));
  }
  // Create command queue for first device
  return *g_default_device;
}


// A global variable storing the default device
std::unique_ptr<cl::CommandQueue> g_default_queue;

// Get the default OpenCL queue
cl::CommandQueue iDefaultQueue(cl::Context const& context = iDefaultContext()) {
  if (!g_default_queue) {
    auto device = iDefaultDevice(context);

    // Create command queue for first device
    g_default_queue = std::unique_ptr<cl::CommandQueue>(
        new cl::CommandQueue(context, device, 0));
  }

  return *g_default_queue;
}


// Convert an AccessType object to a cl_mem_flag
cl_mem_flags iConvertToOpenClAccess(
    amsla::common::AccessType const amsla_type) {
  using AccessType = amsla::common::AccessType;
  switch (amsla_type) {
    case AccessType::READ_ONLY:
      return CL_MEM_READ_ONLY;
    case AccessType::READ_AND_WRITE:
      return CL_MEM_READ_WRITE;
    case AccessType::WRITE_ONLY:
      return CL_MEM_WRITE_ONLY;
    default:
      throw std::runtime_error("Invalid AccessType");
  }
}


// Return a newline string
std::string iNewLine() {
  return std::string("\n");
}

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
  auto build_log =
      a_program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(iDefaultDevice());
  std::string message = "Error when building OpenCL source:" + iNewLine() +
                        iNewLine() + build_log;
  return std::runtime_error(message);
}


// Wrap an OpenCL error with a std::runtime error
std::runtime_error iWrapOpenClError(cl::Error const& err) {
  std::string message = "Error from OpenCL backend:" + iNewLine() + iNewLine() +
                        std::string(err.what());
  return std::runtime_error(message);
}


// Clone an OpenCL buffer
cl::Buffer iCloneOpenClBuffer(cl::Buffer const& from,
                              std::size_t num_bytes,
                              amsla::common::AccessType mem_flag) {
  cl::Buffer ret(iDefaultContext(), iConvertToOpenClAccess(mem_flag),
                 num_bytes);
  try {
    auto queue = iDefaultQueue();
    cl::Event wait_event;
    queue.enqueueCopyBuffer(from, ret, 0, 0, num_bytes, nullptr, &wait_event);
    wait_event.wait();
  } catch (cl::Error err) {
    throw iWrapOpenClError(err);
  }
  return ret;
}

}  // namespace


namespace amsla::common::details {

// Move any data to the device
cl::Buffer writeRawDataToDevice(void const* array,
                                std::size_t num_bytes,
                                amsla::common::AccessType const mem_flag) {
  cl::Buffer out_data(iDefaultContext(), iConvertToOpenClAccess(mem_flag),
                      num_bytes);
  try {
    auto queue = iDefaultQueue();
    queue.enqueueWriteBuffer(out_data, CL_TRUE, 0, num_bytes, array);
  } catch (cl::Error err) {
    throw iWrapOpenClError(err);
  }
  return out_data;
}

// Move any data to the device
void readRawDataFromDevice(cl::Buffer const& device_data,
                           std::size_t num_bytes,
                           void* const to) {
  try {
    auto queue = iDefaultQueue();
    queue.enqueueReadBuffer(device_data, CL_TRUE, 0, num_bytes, to);
  } catch (cl::Error err) {
    throw iWrapOpenClError(err);
  }
}

}  // namespace amsla::common::details


namespace amsla::common {

// Wait until all the operations in the queue are done
void waitAllDeviceOperations() {
  auto queue = iDefaultQueue();
  queue.finish();
}


// DeviceSource is implemented with the PIMPL idiom using a std::unique_ptr.


// Implementation of DeviceSource
class DeviceSource::DeviceSourceImpl {
 private:
  std::string text_;

 public:
  DeviceSourceImpl(std::string const source_text) : text_(source_text) {}

  // Include some other source in the current one.
  void include(DeviceSourceImpl const& source_to_include) {
    text_ = source_to_include.text_ + std::string("\n") + text_;
  }

  // Substitute a macro in the current source with some text.
  void substituteMacro(std::string const macro_name,
                       std::string const substitute_text) {
    text_ = iReplaceSubstring(text_, "__" + macro_name + "__", substitute_text);
  }

  // Convert the source to a string
  std::string toString() const { return text_; }

  // Check that the kernel is not empty
  bool isEmpty() const { return text_.length() == 0; }
};


// Constructing a DeviceSource object
DeviceSource::DeviceSource(std::string const source_text) {
  impl_ = std::unique_ptr<DeviceSourceImpl>(new DeviceSourceImpl(source_text));
}

// Copy constuctor for a DeviceSource object
DeviceSource::DeviceSource(DeviceSource const& another_source) {
  impl_ = std::unique_ptr<DeviceSourceImpl>(
      new DeviceSourceImpl(*another_source.impl_));
}

// Copy assignment
DeviceSource& DeviceSource::operator=(DeviceSource const& other) {
  if (&other != this) {
    impl_ =
        std::unique_ptr<DeviceSourceImpl>(new DeviceSourceImpl(*other.impl_));
  }
  return *this;
}

// Delegate to the implementation
void DeviceSource::include(DeviceSource const& source_to_include) {
  impl_->include(*source_to_include.impl_);
}

void DeviceSource::substituteMacro(std::string const macro_name,
                                   std::string const substitute_text) {
  impl_->substituteMacro(macro_name, substitute_text);
}

// Convert the source to a string.
std::string DeviceSource::toString() const {
  return impl_->toString();
}

/// Check if the source is empty.
bool DeviceSource::isEmpty() const {
  return impl_->isEmpty();
}

// Default destructor, need here after the definition of DeviceSourceImpl is
// complete
DeviceSource::~DeviceSource() = default;


// Implementation of DeviceData using the PIMPL idiom


// Implementation
class DeviceData::DeviceDataImpl {
 private:
  cl::Buffer buffer_;
  std::size_t num_bytes_;
  amsla::common::AccessType access_type_;

 public:
  using AccessType = amsla::common::AccessType;

  DeviceDataImpl(std::size_t const byte_size, AccessType const mem_flag)
      : buffer_(iDefaultContext(), iConvertToOpenClAccess(mem_flag), byte_size),
        num_bytes_(byte_size),
        access_type_(mem_flag) {}

  explicit DeviceDataImpl(cl::Buffer&& a_buffer,
                          std::size_t const num_bytes,
                          AccessType const mem_flag) {
    buffer_ = std::move(a_buffer);
    num_bytes_ = num_bytes;
    access_type_ = mem_flag;
  }

  // Copy constructor
  DeviceDataImpl(DeviceDataImpl const& from) {
    buffer_ =
        iCloneOpenClBuffer(from.buffer_, from.num_bytes_, from.access_type_);
    num_bytes_ = from.num_bytes_;
    access_type_ = from.access_type_;
  }

  // Convert to an OpenCL buffer
  cl::Buffer const& toOpenClBuffer() { return buffer_; };
};


// Constructor
DeviceData::DeviceData(std::size_t const byte_size, AccessType const mem_flag) {
  impl_ =
      std::unique_ptr<DeviceDataImpl>(new DeviceDataImpl(byte_size, mem_flag));
}

// Constructor from OpenCL buffer
DeviceData::DeviceData(cl::Buffer&& a_buffer,
                       std::size_t const byte_size,
                       AccessType const mem_flag) {
  impl_ = std::unique_ptr<DeviceDataImpl>(
      new DeviceDataImpl(std::move(a_buffer), byte_size, mem_flag));
}

// Create a copy of device data
DeviceData::DeviceData(DeviceData const& other) {
  impl_ = std::unique_ptr<DeviceDataImpl>(new DeviceDataImpl(*other.impl_));
}

// Copy assignment
DeviceData& DeviceData::operator=(const DeviceData& other) {
  if (&other != this) {
    impl_ = std::unique_ptr<DeviceDataImpl>(new DeviceDataImpl(*other.impl_));
  }
  return *this;
}

// Convert to an OpenCL buffer
cl::Buffer const& DeviceData::toOpenClBuffer() const {
  return impl_->toOpenClBuffer();
}

// Default destructor, need here after the definition of DeviceDataImpl is
// complete
DeviceData::~DeviceData() = default;


// DeviceKernel is implemented with the PIMPL idiom


// Implementation of DeviceKernel
class DeviceKernel::DeviceKernelImpl {
 private:
  cl::Kernel kernel_;
  std::string kernel_name_;

 public:
  // Construct a kernel object
  DeviceKernelImpl(cl::Program const& program, std::string const& name)
      : kernel_(program, name.c_str()) {
    std::string temp_string = kernel_.getInfo<CL_KERNEL_FUNCTION_NAME>();
    kernel_name_ = iRemoveEmptyChar(temp_string);
  }

  // Get the name of the current kernel.
  std::string name() { return kernel_name_; }

  // Set an argument to the kernel
  void setArgument(uint const argument_number, DeviceData const& device_data) {
    kernel_.setArg(argument_number, device_data.toOpenClBuffer());
  }

  // Run the device kernel
  void run(std::size_t num_threads, std::size_t num_threads_per_block) {
    cl::NDRange global_size(num_threads);
    cl::NDRange local_size = num_threads_per_block;

    // Enqueue kernel
    auto queue = iDefaultQueue();
    queue.enqueueNDRangeKernel(kernel_, cl::NullRange, global_size, local_size);
  }
};


/// Create a copy of device kernel
DeviceKernel::DeviceKernel(DeviceKernel const& other) {
  impl_ = std::unique_ptr<DeviceKernelImpl>(new DeviceKernelImpl(*other.impl_));
}

/// Copy assignment
DeviceKernel& DeviceKernel::operator=(const DeviceKernel& other) {
  if (&other != this) {
    impl_ =
        std::unique_ptr<DeviceKernelImpl>(new DeviceKernelImpl(*other.impl_));
  }
  return *this;
}

// Get the name of the current kernel.
std::string DeviceKernel::name() {
  return impl_->name();
}

// Set an argument to the kernel
void DeviceKernel::setArgument(uint const argument_number,
                               DeviceData const& device_data) {
  impl_->setArgument(argument_number, device_data);
}

// Run the device kernel
void DeviceKernel::run(std::size_t num_threads,
                       std::size_t num_threads_per_block) {
  impl_->run(num_threads, num_threads_per_block);
}

// Construct a kernel object
DeviceKernel::DeviceKernel(cl::Program const& program,
                           std::string const& name) {
  impl_ =
      std::unique_ptr<DeviceKernelImpl>(new DeviceKernelImpl(program, name));
}

// Default destructor, need here after the definition of DeviceKernelImpl is
// complete
DeviceKernel::~DeviceKernel() = default;


// Kernel compilation
DeviceKernel compileKernel(DeviceSource const& kernel_source,
                           std::string const& kernel_name) {
  checkThat(!kernel_source.isEmpty() && kernel_name.length() != 0,
            "Empty kernel provided.");

  auto all_kernels = amsla::common::compileAllKernels(kernel_source);

  for (DeviceKernel& curr_kernel : all_kernels) {
    std::string curr_kernel_name = curr_kernel.name();
    if (curr_kernel_name == kernel_name) {
      return curr_kernel;
    }
  }

  throw std::runtime_error("Source does not contain required kernel.");
}

// Compile all kernels in the source
std::vector<DeviceKernel> compileAllKernels(DeviceSource const& kernel_source) {
  checkThat(!kernel_source.isEmpty(), "Empty kernel provided.");

  auto context = iDefaultContext();
  std::vector<cl::Device> devices = {iDefaultDevice()};

  DeviceSource source_to_compile = kernel_source;
  source_to_compile.include(iExportDeviceFunctions());
  std::string source_string = source_to_compile.toString();

  // Build kernel from source string
  cl::Program::Sources source(
      1, std::make_pair(source_string.c_str(), source_string.length()));
  auto program = cl::Program(context, source);
  std::vector<DeviceKernel> all_kernels;

  // Build the kernel and write the error to output
  try {
    program.build(devices);
    auto kernel_names = iGetKernelNames(program);

    // Create kernel objects
    for (auto curr_name : kernel_names)
      all_kernels.push_back(DeviceKernel(program, curr_name));
  } catch (cl::Error err) {
    throw iCreateBuildError(program);
  }

  return all_kernels;
}


}  // namespace amsla::common