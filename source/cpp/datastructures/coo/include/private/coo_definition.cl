#pragma OPENCL EXTENSION cl_khr_fp64 : enable

// Definition of the data structure
typedef struct __DATASTRUCTURE___ {
  uint row_indices_[__MAX_ELEMENTS__];
  uint column_indices_[__MAX_ELEMENTS__];
  __BASE_TYPE__ values_[__MAX_ELEMENTS__];

  uint num_edges_;
  uint num_nodes_;
  uint max_elements_;
} __DATASTRUCTURE__;
