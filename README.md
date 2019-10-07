![amsla-logo.png](https://i.postimg.cc/QdpfZ4Rn/amsla-logo.png)

**Algorithm-architecture-matching for sparse linear algebra**. AMSLA is 
a sparse linear algebra library for many-core and multi-core processors that
automatically optimizes the data structures and their parameters based on the
processors' architectures.

## Background
Sparse linear algebra is at the core of the simulation and optimization of
mathematical models used in physics and engineering.

AMSLA explores the performance and numerics of sparse linear algebra on
many-core and multi-core computer processors. Inside these processors, when
sparse linear algebra algorithms are executed, the pattern of accesses to
memory is irregular. Because of this, the application's performance is
completely dependent on the problem's structure, which is captured by the
sparsity patterns of the corresponding matrix.

AMSLA selects the data structure representing the problem's sparse matrix and
optimizes its parameters, matching them to the processor's architecture.

## References
*A. Picciau*. Concurrency and data locality for sparse linear algebra on modern
processors. PhD thesis. August 2017. Supervised by Prof. G.A.  Constantinides
and Dr. E.C. Kerrigan. 
[PDF](https://spiral.imperial.ac.uk/handle/10044/1/58884).

## Copyright
Copyright 2018-2019 Andrea Picciau

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License.  You may obtain a copy of the
License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License. 
