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
blockSize = 20;

[I, J, V] = iGenerateLowerTriangularMatrix(matrixSize, blockSize);
subPlotFormat = {1, 2};

figure();

%% Level-set algorithm
levelSetMatrix = amsla.SparseMatrix(I, J, V, "LevelSet");
subplot(subPlotFormat{:}, 1);
title("Level-set");
levelSetMatrix = analyse(levelSetMatrix, "PlotProgress", true);

%% TASSL algorithm
tasslMatrix = amsla.SparseMatrix(I, J, V, "TASSL");
subplot(subPlotFormat{:}, 2);
title("TASSL");
tasslMatrix = analyse(tasslMatrix, blockSize, "PlotProgress", true);

%% HELPER FUNCTIONS

function [I, J, V] = iGenerateLowerTriangularMatrix(matrixSize, blockSize)
% Generate a sparse lower triangular matrix with a semi-random sparsity
% pattern.

% Re-initialise RNG to ensure repeatability
oldRng = rng;
restoreRng = onCleanup(@() rng(oldRng));
rng('default');

% Generate a sparse triangular matrix
aMatrix = sparse(matrixSize, matrixSize);
numBlocks = floor(matrixSize/blockSize);

for blockNumber = 1:numBlocks
    startRow = 1 + blockSize*(blockNumber-1);
    endRow = blockSize*blockNumber;
    aMatrix(startRow:endRow, startRow:endRow) = sprandsym(blockSize, 0.5); %#ok<SPRIX>
end
numConnections = numBlocks;
lastDensity = numConnections/(blockSize*matrixSize);
aMatrix((end-blockSize+1):end, :) = ...
    aMatrix((end-blockSize+1):end, :) + sprand(blockSize, matrixSize, lastDensity);

aMatrix = aMatrix + speye(size(aMatrix));
aMatrix = tril(aMatrix);

[I, J, V] = find(aMatrix);
end