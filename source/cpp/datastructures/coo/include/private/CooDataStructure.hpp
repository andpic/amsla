/** @file CooDataStructure.hpp
 *  @brief Sparse data structure in the COO format.
 *
 *  This contains the definitions of a sparse data structure in the COO format.
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

#ifndef _AMSLA_DATASTRUCTURES_PRIVATE_COODATASTRUCTURE_HPP
#define _AMSLA_DATASTRUCTURES_PRIVATE_COODATASTRUCTURE_HPP

// System includes
#include <algorithm>
#include <cmath>
#include <map>
#include <set>
#include <vector>

// Project includes
#include "Assertions.hpp"
#include "CoreTypes.hpp"
#include "DataStructure.hpp"
#include "DeviceManagement.hpp"

namespace {

/** @brief Compute the next closest power of 10 given an unsigned integer value.
 *  @params n An input unigned integer.
 */
uint iComputeClosestPower(uint const n) {
  // Preconditions
  amsla::common::check_that(n > 0, "The input must be greater than 0.");
  double temp_result = std::ceil(std::log10(n));
  return std::max(2.0, temp_result);
}

std::string iReplaceSubstring(std::string in_string,
                              std::string const to_replace,
                              std::string const replace_with) {
  // Preconditions
  amsla::common::check_that(
      !to_replace.empty() && !in_string.empty(),
      "Neither the input string or that to replace can be empty.");

  size_t index = 0;
  while (true) {
    /* Locate the substring to replace. */
    index = in_string.find(to_replace, index);
    if (index == std::string::npos)
      break;

    /* Make the replacement. */
    in_string.replace(index, to_replace.length(), replace_with);

    /* Advance index forward so the next iteration doesn't pick it up as well.
     */
    index += replace_with.length();
  }
  return in_string;
}

/** @struct __DataLayout
 *  @brief A struct that represents the memory layout of the COO data structure.
 */
template <class BaseType, std::size_t max_elements>
struct __attribute__((__packed__)) __DataLayout {
  cl_uint row_indices_[max_elements];
  cl_uint column_indices_[max_elements];
  BaseType values_[max_elements];

  cl_uint num_edges_ = 0;
  cl_uint num_nodes_ = 0;
  cl_uint const max_elements_ = max_elements;
};

template <class BaseType, std::size_t max_elements>
using DataLayout = struct __DataLayout<BaseType, max_elements>;

/** @brief Initialise a DataLayout struct with some given data
 *  @param data_to_initialise A pointer to the struct.
 *  @param row_indices A vector of row indices.
 *  @param column_indices A vector of column indices.
 *  @param values A vector of values.
 */
template <class HostType, class DeviceType>
void iInitialiseArray(DeviceType* copy_to,
                      std::vector<HostType> const& copy_from,
                      std::size_t const num_elements,
                      std::size_t const max_elements) {
  // Preconditions
  amsla::common::check_that(copy_to && max_elements >= num_elements,
                            "Cannot initialise the array.");

  std::copy_n(copy_from.begin(), num_elements, copy_to);
  std::fill(copy_to + num_elements, copy_to + max_elements,
            static_cast<DeviceType>(0));
}

/** @brief Initialise a DataLayout struct with some given data
 *  @param data_to_initialise A pointer to the struct.
 *  @param row_indices A vector of row indices.
 *  @param column_indices A vector of column indices.
 *  @param values A vector of values.
 */
template <class BaseType, std::size_t max_elements>
void iInitialiseDataLayout(
    DataLayout<BaseType, max_elements>* data_to_initialise,
    std::vector<uint> const& row_indices,
    std::vector<uint> const& column_indices,
    std::vector<BaseType> const& values) {
  amsla::common::check_that(
      row_indices.size() == column_indices.size() == values.size(),
      "All the input vectors must have the same size.");

  std::size_t const num_elements = row_indices.size();

  iInitialiseArray(data_to_initialise->row_indices_, row_indices, num_elements,
                   max_elements);
  iInitialiseArray(data_to_initialise->column_indices_, column_indices,
                   num_elements, max_elements);
  iInitialiseArray(data_to_initialise->values_, values, num_elements,
                   max_elements);

  std::set<uint> all_nodes(row_indices.begin(), row_indices.end());
  all_nodes.insert(column_indices.begin(), column_indices.end());
  data_to_initialise->num_nodes_ = all_nodes.size();
  data_to_initialise->num_edges_ = num_elements;
}

#pragma GCC diagnostic ignored "-Wignored-attributes"
#pragma GCC diagnostic push

/** @class CooDataStructureImpl
 *  @brief A class representing a data structure in the COO format.
 *
 *  This class encapsulates all the logic of the COO data structure.
 */
template <class BaseType, std::size_t max_elements>
class CooDataStructureImpl : public amsla::common::DataStructure {
 public:
  /** @brief Class constructor
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

  /** @brief Retrieve the IDs of all the nodes in the graph
   */
  std::vector<uint> allNodes(void) {
    std::string kernel_name("allNodes");

    if (compiled_kernels_.find(kernel_name) == compiled_kernels_.end()) {
      std::string kernel_source =
#include "derived/coo_allNodes.cl"
          ;
      kernel_source = specialiseSource(kernel_source);

      // Preappend the definitions for the current data structure.
      kernel_source = exportSource() + kernel_source;
      compiled_kernels_[kernel_name] =
          amsla::common::compileKernel(kernel_source, kernel_name);
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

  /** @brief Export the device source to be used with this data structure
   */
  std::string exportSource(void) const { return exportable_source_; }

 private:
  // Basetype used on the device
  using DeviceType = typename amsla::common::toDeviceType<BaseType>::type;

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

  /** @brief Initialise the OpenCL exportable source code.
   */
  void initialiseExportableSource() {
    exportable_source_ =
#include "derived/coo_definition.cl"
        ;
    std::string deviceType = amsla::common::openClTypeName<DeviceType>::get();
    deviceType[0] = std::toupper(deviceType[0]);

    // Preconditions
    amsla::common::check_that(exportable_source_.length() != 0,
                              "The OpenCL source is empty.");

    data_structure_id_ = "CooMaxElements" + std::to_string(max_elements) +
                         "BaseType" + deviceType;
    exportable_source_ = specialiseSource(exportable_source_) + "\n";
  }

  /** @brief Specialise some generic OpenCL source for the current data
   * structure
   *  @param generic_source An unspecialised generic source with parts to be
   *         substituted.
   */
  std::string specialiseSource(std::string const& generic_source) {
    amsla::common::check_that(generic_source.length() != 0,
                              "The generic source is empty.");

    std::string specialised_source = generic_source;
    std::string deviceType = amsla::common::openClTypeName<DeviceType>::get();
    specialised_source = iReplaceSubstring(
        specialised_source, "__DATASTRUCTURE__", data_structure_id_);
    specialised_source = iReplaceSubstring(
        specialised_source, "__MAX_ELEMENTS__", std::to_string(max_elements));
    specialised_source =
        iReplaceSubstring(specialised_source, "__BASE_TYPE__", deviceType);
    return specialised_source;
  }

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
#endif