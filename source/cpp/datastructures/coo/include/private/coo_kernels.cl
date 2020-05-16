/** @file coo_kernels.cl
 *  @brief Implementation of the kernel for "allNodes"
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

__kernel void allNodesKernel(
    __global __DATASTRUCTURE__ const* const data_structure,
    __global uint* const output,
    __global uint* const num_elements_output,
    __global uint* const workspace) {
  allNodes(data_structure, output, num_elements_output, workspace);
}