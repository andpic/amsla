/** @file DataStructure.hpp
 * Interface for DataStructure objects.
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

#ifndef _AMSLA_COMMON_DATASTRUCTURE_HPP
#define _AMSLA_COMMON_DATASTRUCTURE_HPP

// System includes
#include <algorithm>
#include <string>
#include <vector>

namespace amsla::common {

/** Interface for all data structures.
 */
class DataStructure {
 public:
  /** Construct the data structure starting from an array of matrix elements
   */
  virtual DataStructure(std::vector<uint> const& row_indices,
                        std::vector<uint> const& column_indices,
                        std::vector<BaseType> const& values) = 0;

  /** All the node IDs in the graph.
   */
  virtual std::vector<uint> allNodes() = 0;
};  // class DataStructure

}  // namespace amsla::common

// A class managing the data layout
template <class BaseType, std::size_t max_elements>
class CooDataStructureImpl : public amsla::common::DataStructure {
 public:
  /** Class constructor
   */
  CooDataStructureImpl(std::vector<uint> const& row_indices,
                       std::vector<uint> const& column_indices,
                       std::vector<BaseType> const& values) {
    iInitialiseDataLayout(&host_data_structure_, row_indices, column_indices,
                          values);
    device_buffer_ =
        amsla::common::moveToDevice(host_data_structure_, CL_MEM_READ_WRITE);
    initialiseExportableSource();
  }

  /** Retrieve the IDs of all the nodes in the graph
   */
  std::vector<uint> allNodes(void) {
    std::string kernel_name("allNodesKernel");

    if (compiled_kernels_.find(kernel_name) == compiled_kernels_.end()) {
      std::string kernel_sources =
#include "derived/coo_kernels.cl"
          ;
      kernel_sources = specialiseSource(kernel_sources);

      // Preappend the definitions for the current data structure.
      kernel_sources = exportSource() + kernel_sources;
      compiled_kernels_[kernel_name] =
          amsla::common::compileKernel(kernel_sources, kernel_name);
    }

    // Preallocate the output
    std::vector<cl_uint> output;

    try {
      auto vector_size = max_elements;

      cl::Kernel device_kernel = compiled_kernels_[kernel_name];
      cl::Buffer output_buffer =
          amsla::common::createBuffer<decltype(output)::value_type>(
              vector_size, CL_MEM_WRITE_ONLY);
      cl::Buffer num_elements_output_buffer =
          amsla::common::createBuffer<cl_uint>(1, CL_MEM_WRITE_ONLY);
      cl::Buffer workspace_buffer =
          amsla::common::createBuffer<decltype(output)::value_type>(
              2 * vector_size, CL_MEM_READ_WRITE);

      // Bind kernel arguments to kernel
      device_kernel.setArg(0, device_buffer_);
      device_kernel.setArg(1, output_buffer);
      device_kernel.setArg(2, num_elements_output_buffer);
      device_kernel.setArg(3, workspace_buffer);

      // Number of work items in each local work group
      auto num_threads = static_cast<uint>(
          std::ceil(vector_size / static_cast<double>(64)) * 64);
      cl::NDRange global_size(num_threads);
      cl::NDRange local_size = global_size;

      // Enqueue kernel
      auto queue = amsla::common::defaultQueue();
      queue.enqueueNDRangeKernel(device_kernel, cl::NullRange, global_size,
                                 local_size);

      // Block until kernel completion
      output = amsla::common::moveToHost<decltype(output)::value_type>(
          output_buffer, vector_size);
      auto num_elements_output =
          amsla::common::moveToHost<cl_uint>(num_elements_output_buffer);
      amsla::common::waitAllDeviceOperations();

      output.resize(num_elements_output);

    } catch (cl::Error err) {
      std::cerr << err << std::endl;
      throw err;
    }

    return output;
  }

  /** Export the device source to be used with this data structure
   */
  std::string exportSource(void) const { return exportable_source_; }

 private:
  // Basetype used on the device
  using DeviceType = typename amsla::common::ToDeviceType<BaseType>::type;

  // Host-side data
  DataLayout<DeviceType, max_elements> host_data_structure_;

  // Device-side data
  cl::Buffer device_buffer_;

  // Source code for basic operations on the device
  std::string exportable_source_;

  // ID for the data structure
  std::string data_structure_id_;

  // Compiled OpenCL kernels
  std::map<std::string, cl::Kernel> compiled_kernels_;

};  // class CooDataStructureImpl

#pragma GCC diagnistic pop

}  // namespace

namespace amsla::datastructures {
template <class BaseType>
CooDataStructure<BaseType>::CooDataStructure(
    std::vector<uint> const& row_indices,
    std::vector<uint> const& column_indices,
    std::vector<BaseType> const& values) {
  uint const nearest_power = iComputeClosestPower(row_indices.size());

  switch (nearest_power) {
    case 2:
      impl_ = std::unique_ptr<DataStructure>(
          new CooDataStructureImpl<BaseType, static_cast<std::size_t>(2 * 1e2)>(
              row_indices, column_indices, values));
      break;
    case 3:
      impl_ = std::unique_ptr<DataStructure>(
          new CooDataStructureImpl<BaseType, static_cast<std::size_t>(2 * 1e3)>(
              row_indices, column_indices, values));
      break;
    case 4:
      impl_ = std::unique_ptr<DataStructure>(
          new CooDataStructureImpl<BaseType, static_cast<std::size_t>(2 * 1e4)>(
              row_indices, column_indices, values));
      break;
    case 5:
      impl_ = std::unique_ptr<DataStructure>(
          new CooDataStructureImpl<BaseType, static_cast<std::size_t>(2 * 1e5)>(
              row_indices, column_indices, values));
      break;
    default:
      throw std::runtime_error("Unsupported size.");
  }
}

template <class BaseType>
std::vector<uint> CooDataStructure<BaseType>::allNodes(void) {
  return impl_->allNodes();
}

}  // namespace amsla::datastructures

#include "details/DataStructure.hpp"

#endif