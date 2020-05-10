void iCopyArray(__global uint const *from_array, __global uint *to_array,
                uint const first_index, uint const end_index) {
  uint const curr_wi_id = get_global_id(0);
  if (curr_wi_id >= first_index && curr_wi_id < end_index) {
    to_array[curr_wi_id] = from_array[curr_wi_id];
  }
}

//  Left source half is A[ iBegin:iMiddle-1].
// Right source half is A[iMiddle:iEnd-1   ].
// Result is            B[ iBegin:iEnd-1   ].
void iMerge(__global uint *input_array, uint const first_index,
            uint const middle_index, uint const last_index,
            __global uint *throwaway_data) {
  uint const num_elements = last_index - first_index;

  // Create a temporary copy for the merge
  __global uint *temp_array = throwaway_data;
  iCopyArray(&input_array[first_index], temp_array, 0, num_elements);
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

void debugPrint(__global uint const *array, const uint num_elements) {
#if DEBUG
  if (get_global_id(0) == 0) {
    for (uint k = 0; k < num_elements; k++) {
      printf("%d,", array[k]);
    }
    printf("\n");
  }
#endif
}

// Sort the given run of array A[] using array B[] as a source.
// iBegin is inclusive; iEnd is exclusive (A[iEnd] is not in the set).
// Array A[] has the items to sort; array B[] is a work array.
void sort(__global uint *input_array, uint const num_elements,
          __global uint *throwaway_data) {
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

      iMerge(input_array, first_index, middle_index, last_index,
             &throwaway_data[first_index]);
      first_index = last_index;
    }
    // merge the resulting runs from array B[] into A[]

    barrier(CLK_GLOBAL_MEM_FENCE);
  }
}

__kernel void allNodes(__global const __DATASTRUCTURE__ *data_structure,
                       __global uint *output, __global uint *workspace) {
  // Get our global thread ID
  uint const index = get_global_id(0);
  uint const n = data_structure->num_edges_;

  __global uint *array_copy = &workspace[0];
  __global uint *throwaway_data = &workspace[n];

  iCopyArray(data_structure->row_indices_, array_copy, 0, n);
  barrier(CLK_GLOBAL_MEM_FENCE);
  sort(array_copy, n, throwaway_data);
  iCopyArray(array_copy, output, 0, n);
  barrier(CLK_GLOBAL_MEM_FENCE);

  debugPrint(output, n);
}