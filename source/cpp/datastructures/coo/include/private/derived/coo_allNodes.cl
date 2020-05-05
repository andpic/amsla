R"for_c++_include(
__kernel void allNodes(__global const __DATASTRUCTURE__ *data_structure,
                       __global uint *output) {
  // Get our global thread ID
  uint const index = get_global_id(0);
  uint const n = data_structure->_max_elements;

  // Make sure we do not go out of bounds
  if (index < n) {
    output[index] = data_structure->_row_indices[index] +
                    data_structure->_column_indices[index];
  }
})for_c++_include"