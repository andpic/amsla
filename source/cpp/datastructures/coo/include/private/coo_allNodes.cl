void copyArray(__global uint const *const from_array,
               __global uint *const to_array, uint const first_index,
               uint const end_index) {
  uint const curr_wi_id = get_global_id(0);
  if (curr_wi_id >= first_index && curr_wi_id < end_index) {
    to_array[curr_wi_id] = from_array[curr_wi_id];
  }
}

void fillArray(__global uint *const to_array, uint const first_index,
               uint const end_index, uint const value) {
  uint const curr_wi_id = get_global_id(0);
  if (curr_wi_id >= first_index && curr_wi_id < end_index) {
    to_array[curr_wi_id] = value;
  }
}

void debugPrint(__global uint const *const array, const uint num_elements) {
  if (get_global_id(0) == 0) {
    for (uint k = 0; k < num_elements; k++) {
      printf("%d,", array[k]);
    }
    printf("\n");
  }
}

//  Left source half is A[ iBegin:iMiddle-1].
// Right source half is A[iMiddle:iEnd-1   ].
// Result is            B[ iBegin:iEnd-1   ].
void iMergeTwoChunks_(__global uint *const input_array, uint const first_index,
                      uint const middle_index, uint const last_index,
                      __global uint *const throwaway_data) {
  uint const num_elements = last_index - first_index;

  // Create a temporary copy for the merge
  __global uint *temp_array = throwaway_data;
  copyArray(&input_array[first_index], temp_array, 0, num_elements);
  barrier(CLK_GLOBAL_MEM_FENCE);

  // This function should be executed only by the
  uint const curr_wi_id = get_global_id(0);
  if (curr_wi_id != first_index) return;

  uint i = 0;
  uint j = middle_index - first_index;

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

// Sort the given run of array A[] using array B[] as a source.
// iBegin is inclusive; iEnd is exclusive (A[iEnd] is not in the set).
// Array A[] has the items to sort; array B[] is a work array.
void sort(__global uint *const input_array, uint const num_elements,
          __global uint *const workspace) {
  // recursively sort both runs from array A[] into B[]
  uint const num_repetitions = (uint)ceil(log2((double)num_elements));
  for (uint curr_rep = 0; curr_rep < num_repetitions; ++curr_rep) {
    uint const chunk_size = (uint)pown((float)2, (curr_rep + 1));
    uint const num_chunks = (uint)ceil((double)num_elements / chunk_size);

    // split the run longer than 1 item into halves
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
    // merge the resulting runs from array B[] into A[]

    barrier(CLK_GLOBAL_MEM_FENCE);
  }
}

void getIndexesOfArray(__global uint const *const input_array,
                       __global uint const *const indexes_array,
                       uint const num_indexes_elements,
                       __global uint *const output_array) {
  __private uint const curr_wi_id = get_global_id(0);

  if (curr_wi_id >= 0 && curr_wi_id < num_indexes_elements) {
    output_array[curr_wi_id] = input_array[indexes_array[curr_wi_id]];
  }
}

#pragma OPENCL EXTENSION cl_khr_global_int32_base_atomics : enable

void iUnsortedIndexesOfUnique_(__global uint *const input_array,
                               uint const num_elements,
                               __global uint *const indexes_of_unique,
                               __global uint *const num_unique_elements) {
  __private uint const curr_wi_id = get_global_id(0);

  if (curr_wi_id == 0) atomic_xchg(num_unique_elements, 0);
  barrier(CLK_GLOBAL_MEM_FENCE);

  if (curr_wi_id >= 0 && curr_wi_id < num_elements) {
    if (curr_wi_id == 0 ||
        input_array[curr_wi_id] != input_array[curr_wi_id - 1]) {
      __private uint loc = atomic_inc(num_unique_elements);
      indexes_of_unique[loc] = curr_wi_id;
    }
  }
}

void unique(__global uint *const input_array, __global uint *const num_elements,
            __global uint *const workspace) {
  sort(input_array, *num_elements, workspace);
  barrier(CLK_GLOBAL_MEM_FENCE);

  volatile __global uint *num_unique_elements = &workspace[0];
  __global uint *indexes_of_unique = &workspace[1];
  __global uint *output_array = &workspace[1 + *num_elements];

  iUnsortedIndexesOfUnique_(input_array, *num_elements, indexes_of_unique,
                            num_unique_elements);
  barrier(CLK_GLOBAL_MEM_FENCE);

  sort(indexes_of_unique, *num_unique_elements, output_array);
  barrier(CLK_GLOBAL_MEM_FENCE);

  getIndexesOfArray(input_array, indexes_of_unique, *num_unique_elements,
                    output_array);
  barrier(CLK_GLOBAL_MEM_FENCE);

  copyArray(output_array, input_array, 0, *num_unique_elements);
  if (get_global_id(0) == 0) *num_elements = *num_unique_elements;
}

__kernel void allNodes(__global const __DATASTRUCTURE__ *data_structure,
                       __global uint *output,
                       __global uint *num_elements_output,
                       __global uint *workspace) {
  // Get our global thread ID
  __private uint const curr_wi_id = get_global_id(0);
  __private uint const num_edges = data_structure->num_edges_;
  __private uint const initial_num_unique_elements = 2 * num_edges;

  __global uint *num_unique_elements = &workspace[0];
  __global uint *array_copy = &workspace[1];
  __global uint *throwaway_data = &workspace[1 + initial_num_unique_elements];

  copyArray(data_structure->row_indices_, array_copy, 0, num_edges);
  copyArray(data_structure->column_indices_, &array_copy[num_edges], 0,
            num_edges);
  if (curr_wi_id == 0) *num_unique_elements = initial_num_unique_elements;
  barrier(CLK_GLOBAL_MEM_FENCE);

  unique(array_copy, num_unique_elements, throwaway_data);
  barrier(CLK_GLOBAL_MEM_FENCE);

  copyArray(array_copy, output, 0, *num_unique_elements);
  if (curr_wi_id == 0) *num_elements_output = *num_unique_elements;
}