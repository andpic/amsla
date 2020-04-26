/** @file DataStructure.hpp
 *  @brief Interface for DataStructure objects.
 *
 *  This contains the definition for DataStructure object. Any data structure has
 *  abide by this interface.
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
#include <string>
#include <vector>
#include <algorithm>

// Project includes
#include "CoreTypes.hpp"

/** @class DataStructure
 *  @brief Interface for all data structures.
 */
class DataStructure
{
public:
    /** @brief All the node IDs in the graph.
         */
    virtual std::vector<NodeId> allNodes() = 0;
}; // class DataStructure

} // namespace amsla::common
#endif