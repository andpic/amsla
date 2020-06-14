/// @file test_Assertions.cpp
/// Tests for the header Assertions in amsla_common.
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
#include <gtest/gtest.h>
#include <limits.h>
#include <fstream>
#include <string>
#include <vector>

// Project includes
#include "Assertions.hpp"

/// Check that an exception is thrown when the function assertThat fails.
TEST(Assertions, exception_is_thrown_when_assertThat_fails) {
  EXPECT_THROW(amsla::common::assertThat(false, "Dummy"), std::runtime_error);
}