function [aGraph, I, J, V] = getSimpleLowerTriangularMatrix()
%AMSLA.TEST.TOOLS.GETSIMPLELOWERTRIANGULARMATRIX Construct a simple matrix
%to be used in tests.
%
%   [G, I, J, V] = AMSLA.TEST.TOOLS.GETSIMPLELOWERTRIANGULARMATRIX
%       Create a simple lower triangular matrix and also return the row
%       indices (I) the column indices (J) and the values (V) of the
%       entries.

% Copyright 2019 Andrea Picciau
%
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
%
%    http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

J = [1, 1, 1, 2, 3, 4, 4, 5, 5,  3,  6,  6,  7,  8,  6,  9,  9, 10];
I = [1, 2, 3, 2, 3, 4, 5, 5, 6,  6,  6,  7,  7,  8,  8, 10,  9, 10];
numberOfElements = numel(J);
V = ones(1, numberOfElements);
aGraph = amsla.common.DataStructure(I, J, V);
end