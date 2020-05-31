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
#include <functional>
#include <memory>
#include <string>
#include <type_traits>
#include <vector>

// Project includes
#include "DeviceManagement.hpp"

namespace amsla::common {

/** Interface for all DataLayouts, that describe the data layout on the device.
 */
class DataLayoutInterface {
 public:
  /** Get the ID of the current data layout.
   */
  virtual std::string dataLayoutId() = 0;

  /** Get specialised device sources for the current data layout.
   */
  virtual DeviceSource exportDeviceSources() = 0;

  /** Maximum number of elements that can be stored in the data layout.
   */
  virtual std::size_t maxElements() = 0;

  /** Move the data layout to the device.
   */
  virtual amsla::common::Buffer moveToDevice(amsla::common::AccessType) = 0;

  /** Virtual destructor for the interface class.
   */
  virtual ~DataLayoutInterface(){};
};

/** Interface for all data structure-type objects.
 */
class DataStructureInterface {
 public:
  /** Shorthand for the signature of the DataLayout factory method.
   */
  template <typename BaseType>
  using LayoutFactoryMethod =
      std::function<DataLayoutInterface*(std::vector<uint> const&,
                                         std::vector<uint> const&,
                                         std::vector<BaseType> const&,
                                         uint const)>;

  /** All the node IDs in the graph.
   */
  virtual std::vector<uint> allNodes() = 0;

  /** Virtual destructor for the interface class.
   */
  virtual ~DataStructureInterface(){};
};

/** Interface for all data structures.
 */
template <typename BaseType>
class DataStructure : public DataStructureInterface {
 public:
  /** Construct the data structure starting from an array of matrix
   * elements.
   *  @param row_indices The indices of rows of elements in the matrix.
   *  @param column_indices The indices of columns of elements.
   *  @param values The values of elements in the matrix.
   *  @param data_layout_factory A data layout factory method.
   */
  DataStructure(std::vector<uint> const& row_indices,
                std::vector<uint> const& column_indices,
                std::vector<BaseType> const& values,
                DataStructureInterface::LayoutFactoryMethod<BaseType> const&
                    data_layout_factory);

  /** All the node IDs in the graph.
   */
  std::vector<uint> allNodes();

 private:
  std::unique_ptr<DataStructureInterface> impl_;
};

}  // namespace amsla::common

#include "details/DataStructure.hpp"

#endif