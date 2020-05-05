// System includes
#include <gtest/gtest.h>
#include <limits.h>
#include <vector>

// Project includes
#include "CooDataStructure.hpp"

namespace {

template <class BaseType>
auto iGetSimpleCoo() {
  std::vector<uint> const row_indices = {1, 2, 3, 4};
  std::vector<uint> const col_indices = {2, 3, 4, 5};
  std::vector<BaseType> const values = {1.0, 2.0, 3.0, 4.0};
  return amsla::datastructures::CooDataStructure(row_indices, col_indices,
                                                 values);
}

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
  auto dataStructure = iGetSimpleCoo<double>();
  auto result = dataStructure.allNodes();
}

}  // namespace