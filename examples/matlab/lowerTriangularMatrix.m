%LOWERTRIANGULARMATRIX  An example of A²MSLA with lower triangular
%matrices.

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

matrixSize = 200;
matrixDensity = 0.025;

[I, J, V] = iGenerateLowerTriangularMatrix(matrixSize, matrixDensity);
subPlotFormat = {1, 2};

%% Level-set algorithm
levelSetMatrix = amsla.levelSet.Analysis(I, J, V, 'Plot', true);
subplot(subPlotFormat{:}, 1);
title("Level-set");
partition(levelSetMatrix);

%% TASSL algorithm
tasslMatrix = amsla.tassl.Analysis(I, J, V, 10, 'Plot', true);
subplot(subPlotFormat{:}, 2);
title("TASSL");
partition(tasslMatrix);

%% HELPER FUNCTIONS

function [I, J, V] = iGenerateLowerTriangularMatrix(matrixSize, matrixDensity)
% Generate a sparse lower triangular matrix with a semi-random sparsity
% pattern.

% Re-initialise RNG to ensure repeatability
oldRng = rng;
restoreRng = onCleanup(@() rng(oldRng));
rng('default');

% Generate a sparse triangular matrix
aMatrix =  sprand(matrixSize, matrixSize, matrixDensity);
aMatrix = tril(aMatrix) + speye(size(aMatrix));
[I, J, V] = find(aMatrix);
end