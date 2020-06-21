/** @file coo_definitions.cl
 * OpenCL sources for the data structure COO
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

#pragma OPENCL EXTENSION cl_khr_fp64 : enable

/** Definition of the data structure
 */
typedef struct __DATASTRUCTURE___ {
  uint row_indices_[__MAX_ELEMENTS__];
  uint column_indices_[__MAX_ELEMENTS__];
  __BASE_TYPE__ values_[__MAX_ELEMENTS__];

  uint num_edges_;
  uint num_nodes_;
  uint max_elements_;
} __DATASTRUCTURE__;

/** Get all the indices of nodes in the graph.
 *
 *  @param data_structure The COO data structure being processed.
 *  @param output Output indices.
 *  @param num_elements_output Number of elements in the output array.
 *  @param workspace Temporary workspace.
 */
void allNodes(__global __DATASTRUCTURE__ const* data_structure,
              __global uint* output,
              __global uint* num_elements_output,
              __global uint* workspace) {
  // Get global thread ID
  __private uint const curr_wi_id = get_global_id(0);
  __private uint const num_edges = data_structure->num_edges_;
  __private uint const initial_num_unique_elements = 2 * num_edges;

  __global uint* num_unique_elements = &workspace[0];
  __global uint* array_copy = &workspace[1];
  __global uint* workspace_for_unique =
      &workspace[1 + initial_num_unique_elements];

  // Copying row and column indices to a temporary space
  copyArray(data_structure->row_indices_, array_copy, 0, num_edges);
  copyArray(data_structure->column_indices_, &array_copy[num_edges], 0,
            num_edges);
  if (curr_wi_id == 0)
    *num_unique_elements = initial_num_unique_elements;
  barrier(CLK_GLOBAL_MEM_FENCE);

  // Compute the unique elements
  unique(array_copy, num_unique_elements, workspace_for_unique);
  barrier(CLK_GLOBAL_MEM_FENCE);

  // Copy out the output
  copyArray(array_copy, output, 0, *num_unique_elements);
  if (curr_wi_id == 0)
    *num_elements_output = *num_unique_elements;
}