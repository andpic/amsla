/** @file device_functions.cl
 * Library of functions usable inside OpenCL kernels.
 *
 *  This file contains functions that can be used inside OpenCL kernels to
 *  implement more sophisticated algorithms.
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

/** Copy data from one array to another.
 *  @param from_array Source of the copy.
 *  @param to_array Destination of the copy.
 *  @param first_index Index to start from for the copy.
 *  @param end_index After-end index for the copy.
 */
void copyArray(__global uint const* from_array,
               __global uint* to_array,
               uint const first_index,
               uint const end_index);

/** Fill an array with given values.
 *  @param to_array Destination of the filling.
 *  @param first_index Index to start from for the filling.
 *  @param end_index After-end index for the filling.
 *  @param value Value for filling the array.
 */
void fillArray(__global uint* to_array,
               uint const first_index,
               uint const end_index,
               uint const value);

/** Print the values of an arryay to screen.
 *  @param array Destination of the filling.
 *  @param num_elements Index to start from for the filling.
 */
void debugPrint(__global uint const* array, const uint num_elements);

/** Sort the input array in descending order.
 *  @param array Input/output array.
 *  @param num_elements Number of elements in the input array.
 *  @param workspace Space for temporary data.
 */
void sort(__global uint* array,
          uint const num_elements,
          __global uint* workspace);

/** Find the unique elements inside an array.
 *  @param array Input/output array.
 *  @param num_elements Number of elements in the array. Both input and output.
 *  @param workspace Space for temporary data.
 */
void unique(__global uint* array,
            __global uint* num_elements,
            __global uint* workspace);

/** Copy some elements of the input array to another array.
 *  @param input_array Array being indexed.
 *  @param indexes_array Array containing the indexes.
 *  @param num_indexes_elements Number of elements in indexes_array.
 *  @param output_array Result of the indexing operation.
 */
void getIndexesOfArray(__global uint const* input_array,
                       __global uint const* indexes_array,
                       uint const num_indexes_elements,
                       __global uint* output_array);

// copyArray ******************************************************************/

void copyArray(__global uint const* from_array,
               __global uint* to_array,
               uint const first_index,
               uint const end_index) {
  __private uint const curr_wi_id = get_global_id(0);
  if (curr_wi_id >= first_index && curr_wi_id < end_index) {
    to_array[curr_wi_id] = from_array[curr_wi_id];
  }
}

// fillArray ******************************************************************/

void fillArray(__global uint* to_array,
               uint const first_index,
               uint const end_index,
               uint const value) {
  uint const curr_wi_id = get_global_id(0);
  if (curr_wi_id >= first_index && curr_wi_id < end_index) {
    to_array[curr_wi_id] = value;
  }
}

// debugPrint *****************************************************************/

void debugPrint(__global uint const* array, const uint num_elements) {
  // This function is only executed by the first work-item
  if (get_global_id(0) != 0)
    return;

  for (uint k = 0; k < num_elements; k++) {
    printf("%d,", array[k]);
  }
  printf("\n");
}

// sort ***********************************************************************/

// Merge two sorted array chunks into one sorted chunk.
void iMergeTwoChunks_(__global uint* input_array,
                      uint const first_index,
                      uint const middle_index,
                      uint const last_index,
                      __global uint* workspace) {
  __private uint const num_elements = last_index - first_index;

  // Create a temporary copy for the merge
  __global uint* temp_array = workspace;
  copyArray(&input_array[first_index], temp_array, 0, num_elements);
  barrier(CLK_GLOBAL_MEM_FENCE);

  // This function should be executed only by one work-item.
  __private uint const curr_wi_id = get_global_id(0);
  if (curr_wi_id != first_index)
    return;

  __private uint i = 0;
  __private uint j = middle_index - first_index;

  // While there are elements in the left or right runs...
  for (uint k = first_index; k < last_index; k++) {
    // If left run head exists and is <= existing right run head.
    if (i < (middle_index - first_index) &&
        (j >= num_elements || temp_array[i] <= temp_array[j])) {
      input_array[k] = temp_array[i];
      i++;
    } else {
      input_array[k] = temp_array[j];
      j++;
    }
  }
}

void sort(__global uint* input_array,
          uint const num_elements,
          __global uint* workspace) {
  // Implement sort as a reduction in log2(num_elements) steps
  uint const num_repetitions = (uint)ceil(log2((double)num_elements));
  for (uint curr_rep = 0; curr_rep < num_repetitions; ++curr_rep) {
    // In every step, the chunk size is doubled
    uint const chunk_size = (uint)pown((float)2, (curr_rep + 1));
    uint const num_chunks = (uint)ceil((double)num_elements / chunk_size);

    // Every chunk is the result of merging 2 chunks from the previous step
    uint first_index = 0;
    for (uint curr_chunk = 0; curr_chunk < num_chunks; ++curr_chunk) {
      uint const end_of_chunk = first_index + chunk_size;
      uint last_index =
          end_of_chunk > num_elements ? num_elements : end_of_chunk;
      uint middle_index = (uint)round(first_index + ((double)chunk_size) / 2);

      iMergeTwoChunks_(input_array, first_index, middle_index, last_index,
                       &workspace[first_index]);
      first_index = last_index;
    }

    // Synchronise after every step
    barrier(CLK_GLOBAL_MEM_FENCE);
  }
}

// getIndexesOfArray **********************************************************/

void getIndexesOfArray(__global uint const* input_array,
                       __global uint const* indexes_array,
                       uint const num_indexes_elements,
                       __global uint* output_array) {
  __private uint const curr_wi_id = get_global_id(0);

  if (curr_wi_id >= 0 && curr_wi_id < num_indexes_elements) {
    output_array[curr_wi_id] = input_array[indexes_array[curr_wi_id]];
  }
}

// unique *********************************************************************/

#pragma OPENCL EXTENSION cl_khr_global_int32_base_atomics : enable

// Get the indexes of all unique elements in the input array. The input array
// must be sorted, the output is not.
void iIndexesOfUniqueElements_(__global uint* input_array,
                               uint const num_elements,
                               __global uint* indexes_of_unique,
                               __global uint* num_unique_elements) {
  __private uint const curr_wi_id = get_global_id(0);

  if (curr_wi_id == 0)
    atomic_xchg(num_unique_elements, 0);
  barrier(CLK_GLOBAL_MEM_FENCE);

  if (curr_wi_id >= 0 && curr_wi_id < num_elements) {
    if (curr_wi_id == 0 ||
        input_array[curr_wi_id] != input_array[curr_wi_id - 1]) {
      __private uint loc = atomic_inc(num_unique_elements);
      indexes_of_unique[loc] = curr_wi_id;
    }
  }
}

void unique(__global uint* input_array,
            __global uint* num_elements,
            __global uint* workspace) {
  // Sort input array
  sort(input_array, *num_elements, workspace);
  barrier(CLK_GLOBAL_MEM_FENCE);

  volatile __global uint* num_unique_elements = &workspace[0];
  __global uint* indexes_of_unique = &workspace[1];
  __global uint* output_array = &workspace[1 + *num_elements];

  // Find the indexes of unique elements
  iIndexesOfUniqueElements_(input_array, *num_elements, indexes_of_unique,
                            num_unique_elements);
  barrier(CLK_GLOBAL_MEM_FENCE);

  // Sort the indexes of unique elements
  sort(indexes_of_unique, *num_unique_elements, output_array);
  barrier(CLK_GLOBAL_MEM_FENCE);

  // Index the input array with the indexes of unique elements
  getIndexesOfArray(input_array, indexes_of_unique, *num_unique_elements,
                    output_array);
  barrier(CLK_GLOBAL_MEM_FENCE);

  // Copy the result back to the output
  copyArray(output_array, input_array, 0, *num_unique_elements);
  if (get_global_id(0) == 0)
    *num_elements = *num_unique_elements;
}