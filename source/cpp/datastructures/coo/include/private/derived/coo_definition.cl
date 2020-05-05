R"for_c++_include(
#pragma OPENCL EXTENSION cl_khr_fp64 : enable

// Definition of the data structure
typedef struct ___DATASTRUCTURE__ {
  uint _row_indices[__MAX_ELEMENTS__];
  uint _column_indices[__MAX_ELEMENTS__];
  __BASE_TYPE__ _values[__MAX_ELEMENTS__];

  uint _num_edges;
  uint _num_nodes;
  uint _max_elements;
} __DATASTRUCTURE__;
)for_c++_include"