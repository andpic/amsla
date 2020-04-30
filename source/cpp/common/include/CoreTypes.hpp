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

// System includes
#include <type_traits>

// Project includes
#include "DeviceManagement.hpp"

#pragma GCC system_header

namespace amsla::common {

/** @brief Convert a host type to a class (OpenCL) type
 *  @param HostType The host type being converted.
 */
template <class HostType>
struct toDeviceType {
  typedef void type;
};

template <>
struct toDeviceType<float> {
  typedef cl_float type;
};

template <>
struct toDeviceType<double> {
  typedef cl_double type;
};

template <>
struct toDeviceType<uint> {
  typedef cl_uint type;
};

/** @brief Return the name of the type as a string
 *  @param BaseType The type we want the name of
 */
template <class HostType>
struct openClTypeName {
  static const char* get() { return typeid(HostType).name(); };
};

template <>
struct openClTypeName<cl_float> {
  static const char* get() { return "float"; };
};

template <>
struct openClTypeName<cl_double> {
  static const char* get() { return "double"; };
};

}  // namespace amsla::common

#endif