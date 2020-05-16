/** @file test_CooDataStructure.cpp
 *  @brief Tests for the CooDataStructure in amsla_datasructures.
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
#include <gtest/gtest.h>
#include <limits.h>
#include <algorithm>
#include <string>
#include <vector>

// Project includes
#include "CooDataStructure.hpp"

// Helpers ********************************************************************/

namespace {

template <class BaseType>
auto iGetSimpleCoo() {
  std::vector<uint> const row_indices = {1, 2, 3, 4};
  std::vector<uint> const col_indices = {2, 3, 4, 5};
  std::vector<BaseType> const values = {1.0, 2.0, 3.0, 4.0};
  return amsla::datastructures::CooDataStructure(row_indices, col_indices,
                                                 values);
}

// Test specs *****************************************************************/

/** @brief Check that a CooDataStructure object can be created and destroyed
 * without errors.
 */
TEST(CooDataStructure, object_created_and_destroyed) {
  auto dataStructure = iGetSimpleCoo<double>();
}

/** @brief Check that a CooDataStructure object can be created and destroyed
 * without errors.
 */
TEST(CooDataStructure, allNodes_does_not_error) {
  std::vector<uint> const row_indices = {3, 2, 1, 4};
  std::vector<uint> const col_indices = {4, 3, 2, 5};
  std::vector<double> const values = {1.0, 2.0, 3.0, 4.0};
  auto dataStructure =
      amsla::datastructures::CooDataStructure(row_indices, col_indices, values);
  auto actual_output = dataStructure.allNodes();

  std::vector<uint> expected_output = {1, 2, 3, 4, 5};

  EXPECT_EQ(actual_output.size(), expected_output.size())
      << "Actual and expected output size mismatch";

  for (std::size_t i = 0; i < row_indices.size(); i++) {
    EXPECT_EQ(actual_output[i], expected_output[i])
        << "Error at index " << std::to_string(i);
  }
}

}  // namespace