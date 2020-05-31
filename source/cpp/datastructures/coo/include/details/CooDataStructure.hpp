/** @file CooDataStructure.hpp
 * Sparse data structure in the COO format.
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

#ifndef _AMSLA_DATASTRUCTURES_DETAILS_COODATASTRUCTURE_HPP
#define _AMSLA_DATASTRUCTURES_DETAILS_COODATASTRUCTURE_HPP

// System includes
#include <algorithm>
#include <cmath>
#include <map>
#include <set>
#include <vector>

// Project includes
#include "Assertions.hpp"
#include "DataStructure.hpp"
#include "DeviceManagement.hpp"

namespace {

// Compute the closest power of 10.
uint iComputeClosestPower(uint const n) {
  amsla::common::checkThat(n > 0, "The input must be greater than 0.");

  double temp_result = std::ceil(std::log10(n));
  return std::max(2.0, temp_result);
}

// Shorthand
using DeviceSource = amsla::common::DeviceSource;

/** Layout of the data on the host, mirroring the layout on the device.
 */
template <typename BaseType, std::size_t max_elements>
class CooDataLayout : public amsla::common::DataLayoutInterface {
 public:
  // Constructor
  CooDataLayout(std::vector<uint> const& row_indices,
                std::vector<uint> const& column_indices,
                std::vector<BaseType> const& values) {
    amsla::common::checkThat(
        row_indices.size() == column_indices.size() == values.size(),
        "All the input vectors must have the same size.");

    std::size_t const num_elements = row_indices.size();

    amsla::common::initialiseDeviceLikeArray(internal_layout_.row_indices_,
                                             row_indices, max_elements);
    amsla::common::initialiseDeviceLikeArray(internal_layout_.column_indices_,
                                             column_indices, max_elements);
    amsla::common::initialiseDeviceLikeArray(internal_layout_.values_, values,
                                             max_elements);

    std::set<uint> all_nodes(row_indices.begin(), row_indices.end());
    all_nodes.insert(column_indices.begin(), column_indices.end());
    internal_layout_.num_nodes_ = all_nodes.size();
    internal_layout_.num_edges_ = num_elements;
  }

  // Export device sources that are customised for the CooDataLayout
  DeviceSource exportDeviceSources() {
    DeviceSource exportable_source(
#include "derived/coo_definitions.cl"
    );
    amsla::common::checkThat(!exportable_source.isEmpty(),
                             "The OpenCL source is empty.");
    return specialiseDeviceSources(exportable_source);
  }

  // Compute an ID for this type of data layout
  std::string dataLayoutId() {
    std::string type_name = amsla::common::typeName<BaseType>();
    type_name[0] = std::toupper(type_name[0]);

    return "CooMaxElements" + std::to_string(max_elements) + "BaseType" +
           type_name;
  }

  // Max number of elements
  std::size_t maxElements() { return max_elements; }

  // Move data layout to the device
  amsla::common::Buffer moveToDevice(
      amsla::common::AccessType const access_mode) {
    return amsla::common::moveToDevice(internal_layout_, access_mode);
  }

 private:
  using IdDeviceType = typename amsla::common::ToDeviceType<uint>::type;
  using BaseDeviceType = typename amsla::common::ToDeviceType<BaseType>::type;

  // Data layout on the device
  struct __attribute__((__packed__)) DeviceLayout {
    // Elements in the matrix
    IdDeviceType row_indices_[max_elements];
    IdDeviceType column_indices_[max_elements];
    BaseDeviceType values_[max_elements];

    // Number of elements in the matrix.
    IdDeviceType num_edges_ = 0;

    // Number of nodes in the matrix.
    IdDeviceType num_nodes_ = 0;

    // Maximum number of edges allowed in the matrix.
    IdDeviceType const max_elements_ = max_elements;
  };

  // Internal data layout
  DeviceLayout internal_layout_;

  // Specialise the device sources for this data layout
  DeviceSource specialiseDeviceSources(DeviceSource const& generic_source) {
    amsla::common::checkThat(!generic_source.isEmpty(),
                             "The generic source is empty.");

    auto specialised_source = generic_source;
    std::string device_type = amsla::common::typeName<BaseType>();
    specialised_source.substituteMacro("DATASTRUCTURE", dataLayoutId());
    specialised_source.substituteMacro("MAX_ELEMENTS",
                                       std::to_string(max_elements));
    specialised_source.substituteMacro("BASE_TYPE", device_type);
    return specialised_source;
  }
};

template <typename BaseType>
amsla::common::DataLayoutInterface* createCooDataLayout(
    std::vector<uint> const& row_indexes,
    std::vector<uint> const& column_indexes,
    std::vector<BaseType> const& values,
    uint const max_elements) {
  return new CooDataLayout<BaseType, 100>(row_indexes, column_indexes, values);
}

}  // namespace

namespace amsla::datastructures {

template <typename BaseType>
amsla::datastructures::CooDataStructure<BaseType>::CooDataStructure(
    std::vector<uint> const& row_indexes,
    std::vector<uint> const& column_indexes,
    std::vector<BaseType> const& values)
    : amsla::common::DataStructure<BaseType>(row_indexes,
                                             column_indexes,
                                             values,
                                             createCooDataLayout<BaseType>) {}
}  // namespace amsla::datastructures

#endif
