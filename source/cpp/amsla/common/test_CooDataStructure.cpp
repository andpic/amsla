#include <limits.h>
#include <vector>

#include <gtest/gtest.h>
#include "CooDataStructure.hpp"

namespace
{

// Tests factorial of negative numbers.
TEST(CooDataStructure, simple_constructor)
{

    std::vector<uint> const row_indices = {1, 2, 3, 4};
    std::vector<uint> const column_indices = {2, 3, 4, 5};
    std::vector<double> const values = {0.1, 0.2, 0.3, 0.4};

    amsla::common::CooDataStructure objectUnderTest(row_indices, column_indices, values);
}

} // namespace