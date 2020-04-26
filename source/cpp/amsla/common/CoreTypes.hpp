/** @file CoreTypes.hpp
 *  @brief Fundamental datatypes for AMSLA.
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

#ifndef _AMSLA_COMMON_CORETYPES_HPP
#define _AMSLA_COMMON_CORETYPES_HPP

// Project includes
#include "OpenClWrapper.hpp"

namespace amsla::common {

    using NodeId = cl_uint;

    using EdgeId = cl_uint;

    using SubGraphId = cl_uint;

    using TimeSlotId = cl_uint;

}// namespace amsla::common

#endif