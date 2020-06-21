/// @file simple_kernels.cl
/// Example OpenCL kernels for testing
///
/// This contains the definition for DataStructure object. Any data structure
/// has abide by this interface.
///
/// @author Andrea Picciau <andrea@picciau.net>
///
/// @copyright Copyright 2019-2020 Andrea Picciau
///
/// @license Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///    http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.

void kernel simple_increment(global int* A) {
  A[get_global_id(0)] = A[get_global_id(0)] + 1;
}

void kernel simple_add(global const int* A,
                       global const int* B,
                       global int* C) {
  C[get_global_id(0)] = A[get_global_id(0)] + B[get_global_id(0)];
}

void kernel simple_mult(global const int* A,
                        global const int* B,
                        global int* C) {
  C[get_global_id(0)] = A[get_global_id(0)] * B[get_global_id(0)];
}