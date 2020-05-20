/** @file Assertions.cpp
 * Shared definitions of assertions.
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

#ifndef _AMSLA_COMMON_ASSERTIONS_CPP
#define _AMSLA_COMMON_ASSERTIONS_CPP

// System includes
#include <iostream>
#include <stdexcept>
#include <string>

// Project includes
#include "Assertions.hpp"

namespace amsla::common {

void assertThat(bool const must_be_true, std::string const diagnostic) {
  if (!must_be_true) {
    throw std::runtime_error(diagnostic);
  }
}

// Disable check when not in debug mode
void checkThat(bool const must_be_true, std::string const diagnostic) {
#if DEBUG
  assertThat(must_be_true, diagnostic);
#endif
}

}  // namespace amsla::common

#endif