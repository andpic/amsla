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

#ifndef _AMSLA_DATASTRUCTURES_COODATASTRUCTURE_HPP
#define _AMSLA_DATASTRUCTURES_COODATASTRUCTURE_HPP

// System includes
#include <algorithm>
#include <cmath>
#include <map>
#include <set>
#include <vector>

// Project includes
#include "DataStructure.hpp"

namespace amsla::datastructures {

/** A COO data structure
 *
 *  This is the interface that
 */
template <typename BaseType>
class CooDataStructure : public amsla::common::DataStructure<BaseType> {
 public:
  CooDataStructure(std::vector<uint> const& row_indexes,
                   std::vector<uint> const& column_indexes,
                   std::vector<BaseType> const& values);
};

}  // namespace amsla::datastructures

#include "details/CooDataStructure.hpp"

#endif