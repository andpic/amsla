/** @file CooDataStructure.hpp
 *  @brief Sparse data structure in the COO format.
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

#ifndef _AMSLA_COMMON_COODATASTRUCTURE_HPP
#define _AMSLA_COMMON_COODATASTRUCTURE_HPP

// System includes
#include <CL/cl.hpp>
#include <algorithm>
#include <vector>
#include <cmath>
#include <set>

// Project includes
#include "Assertions.hpp"
#include "CoreTypes.hpp"
#include "OpenClWrapper.hpp"
#include "DataStructure.hpp"

namespace
{

/** @brief Compute the next closest power of 10 given an unsigned integer value.
 *  @params n An input unigned integer.
 */
uint iComputeClosestPower(uint const n)
{
    double temp_result = std::ceil(std::log10(n));
    return std::max(2.0, temp_result);
}      

/** @struct __DataLayout
 *  @brief A struct that represents the memory layout of the COO data structure.
 */
template <class BaseType, std::size_t max_elements>
struct __attribute__((__packed__)) __DataLayout
{
    NodeId _row_indices[max_elements];
    NodeId _column_indices[max_elements];
    BaseType _values[max_elements];

    cl_uint _num_edges = 0;
    cl_uint _num_nodes = 0;
    cl_uint const _max_elements = max_elements;
};

template <class BaseType, std::size_t max_elements>
using DataLayout =
    struct __DataLayout<BaseType, max_elements>;

/** @class CooDataStructureImpl
 *  @brief A class representing a data structure in the COO format.
 * 
 *  This class encapsulates all the logic of the COO data structure.
 */
template <class BaseType, std::size_t max_elements>
class CooDataStructureImpl : public DataStructure
{

public:
    CooDataStructureImpl(std::vector<uint> const &row_indices,
                         std::vector<uint> const &column_indices,
                         std::vector<BaseType> const &values)
    {
        amsla::common::check_that(row_indices.size() == column_indices.size() == values.size(),
                                  "All the input vectors must have the same size.");

        std::size_t const num_elements = row_indices.size();

        std::copy_n(row_indices.begin(), num_elements, _host_data_structure._row_indices);
        std::copy_n(column_indices.begin(), num_elements, _host_data_structure._column_indices);
        std::copy_n(values.begin(), num_elements, _host_data_structure._values);

        std::set<uint> all_nodes(row_indices.begin(), row_indices.end());
        all_nodes.insert(column_indices.begin(), column_indices.end());
        _host_data_structure._num_nodes = all_nodes.size();
        _host_data_structure._num_edges = num_elements;
    }

private:
    // Host-side data
    DataLayout<BaseType, max_elements> _host_data_structure;

    // Device-side data
    cl::Buffer _device_buffer;

}; // class CooDataStructureImpl

} // namespace

namespace amsla::common
{
template <class BaseType>
class CooDataStructure : public DataStructure
{

public:
    CooDataStructure(std::vector<uint> const &row_indices,
                     std::vector<uint> const &column_indices,
                     std::vector<BaseType> const &values)
    {
        uint const nearest_power = iComputeClosestPower(row_indices.size());

        switch (nearest_power)
        {
        case 2:
            _impl = std::unique_ptr<DataStructure>(
                new CooDataStructureImpl<BaseType, static_cast<std::size_t>(2 * 1e2)>(
                    row_indices, column_indices, values));
            break;
        case 3:
            _impl = std::unique_ptr<DataStructure>(
                new CooDataStructureImpl<BaseType, static_cast<std::size_t>(2 * 1e3)>(
                    row_indices, column_indices, values));
            break;
        case 4:
            _impl = std::unique_ptr<DataStructure>(
                new CooDataStructureImpl<BaseType, static_cast<std::size_t>(2 * 1e4)>(
                    row_indices, column_indices, values));
            break;
        case 5:
            _impl = std::unique_ptr<DataStructure>(
                new CooDataStructureImpl<BaseType, static_cast<std::size_t>(2 * 1e5)>(
                    row_indices, column_indices, values));
            break;
        default:
            throw std::runtime_error("Invalid size.");
        }
    }

private:
    std::unique_ptr<DataStructure> _impl;

}; // class CooDataStructure

} // namespace amsla::common
#endif