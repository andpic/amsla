/// @file DataStructure.cpp
/// Interface for DataStructure objects.
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

// System includes
#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

// Project includes
#include "DataStructure.hpp"


namespace amsla::common {

// A class managing the data layout
template <typename BaseType>
class DataStructure<BaseType>::DataStructureImpl
    : public amsla::common::DataStructureInterface {
 public:
  // Class constructor
  DataStructureImpl(std::vector<uint> const& row_indices,
                    std::vector<uint> const& column_indices,
                    std::vector<BaseType> const& values,
                    amsla::common::DataStructureInterface::LayoutFactoryMethod<
                        BaseType> const& data_layout_factory) {
    auto num_elements = row_indices.size();
    amsla::common::assertThat(
        column_indices.size() == num_elements && values.size() == num_elements,
        "The input arrays should all have the same size.");

    host_layout_factory_ = data_layout_factory;

    host_data_layout_ = std::unique_ptr<amsla::common::DataLayoutInterface>(
        data_layout_factory(row_indices, column_indices, values, num_elements));

    exportable_sources_ = std::make_unique<amsla::common::DeviceSource>(
        host_data_layout_->exportDeviceSources());
    compileSpecialisedKernels();

    device_buffer_ = std::make_unique<amsla::common::DeviceData>(
        std::move(host_data_layout_->moveToDevice(
            amsla::common::AccessType::READ_AND_WRITE)));
  }

  // Retrieve the IDs of all the nodes in the graph
  std::vector<uint> allNodes() {
    std::string kernel_name("allNodesKernel");

    // Preallocate the output
    std::vector<uint> output;

    auto vector_size = host_data_layout_->maxElements();

    amsla::common::DeviceKernel device_kernel = compiled_kernels_[0];

    auto output_buffer = amsla::common::moveToDevice(
        std::vector<uint>(vector_size), amsla::common::AccessType::WRITE_ONLY);
    auto num_elements_output_buffer = amsla::common::moveToDevice(
        static_cast<uint>(1), amsla::common::AccessType::WRITE_ONLY);
    auto workspace_buffer =
        amsla::common::moveToDevice(std::vector<uint>(2 * vector_size),
                                    amsla::common::AccessType::READ_AND_WRITE);

    // Bind kernel arguments to kernel
    device_kernel.setArgument(0, *device_buffer_);
    device_kernel.setArgument(1, output_buffer);
    device_kernel.setArgument(2, num_elements_output_buffer);
    device_kernel.setArgument(3, workspace_buffer);

    // Run the kernel
    auto num_threads = static_cast<uint>(
        std::ceil(vector_size / static_cast<double>(64)) * 64);
    device_kernel.run(num_threads, num_threads);

    // Block until kernel completion
    output = amsla::common::moveToHost<decltype(output)::value_type>(
        output_buffer, vector_size);
    auto num_elements_output =
        amsla::common::moveToHost<cl_uint>(num_elements_output_buffer);
    amsla::common::waitAllDeviceOperations();

    output.resize(num_elements_output);

    return output;
  }

  // Export the device source to be used with this data structure
  amsla::common::DeviceSource exportDeviceSources() const {
    return *exportable_sources_;
  }

 private:
  // Compile all the kernels for the current device layout
  void compileSpecialisedKernels() {
    std::string kernel_text =
#include "derived/datastructure_kernels.cl"
        ;
    amsla::common::DeviceSource kernel_sources(kernel_text);

    specialiseKernelSources(kernel_sources);

    // Preappend the definitions for the current data structure.
    kernel_sources.include(*exportable_sources_);

    // Compile all kernels and store them by name
    compiled_kernels_ = amsla::common::compileAllKernels(kernel_sources);
  }

  // Specialise kernel sources for the current data layout
  void specialiseKernelSources(amsla::common::DeviceSource& kernel_sources) {
    amsla::common::checkThat(!kernel_sources.isEmpty(),
                             "The generic source is empty.");

    kernel_sources.substituteMacro("DATASTRUCTURE",
                                   host_data_layout_->dataLayoutId());
    kernel_sources.substituteMacro(
        "MAX_ELEMENTS", std::to_string(host_data_layout_->maxElements()));
    kernel_sources.substituteMacro("BASE_TYPE",
                                   amsla::common::typeName<BaseType>());
  }

  // Host-side data
  std::unique_ptr<amsla::common::DataLayoutInterface> host_data_layout_;

  // Device-side data
  std::unique_ptr<amsla::common::DeviceData> device_buffer_;

  amsla::common::DataStructureInterface::LayoutFactoryMethod<BaseType>
      host_layout_factory_;

  // Source code for basic operations on the device
  std::unique_ptr<amsla::common::DeviceSource> exportable_sources_;

  // ID for the data structure
  std::string data_structure_id_;

  // Compiled OpenCL kernels
  std::vector<amsla::common::DeviceKernel> compiled_kernels_;
};


// DataStructure class constructor
template <typename BaseType>
DataStructure<BaseType>::DataStructure(
    std::vector<uint> const& row_indices,
    std::vector<uint> const& column_indices,
    std::vector<BaseType> const& values,
    amsla::common::DataStructureInterface::LayoutFactoryMethod<BaseType> const&
        data_layout_factory)
    : impl_(new DataStructureImpl(row_indices,
                                  column_indices,
                                  values,
                                  data_layout_factory)){};

// Get the IDs of all the nodes in the the graph, delegate to implementation.
template <typename BaseType>
std::vector<uint> DataStructure<BaseType>::allNodes() {
  return impl_->allNodes();
}

// Define destructor as required by the PIMPL idiom.
template <typename BaseType>
DataStructure<BaseType>::~DataStructure() = default;

template class DataStructure<double>;

}  // namespace amsla::common