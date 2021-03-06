classdef(Abstract) PartitionerTests < amsla.test.tools.AmslaTest
    %PARTITIONERTESTS Tests for the Partitioner classes
    
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
    
    methods (Access=protected, Static)
        
        analyserObject = createPartitionerObject(I, J, V, maxSubg);
        
    end
    
    methods(Access=protected, Abstract)
        
        verifyPartitioningResultOfExampleGraph(testCase, actualPartitioningResult);
        
    end
    
    %% Graph is correctly reset
    
    properties(TestParameter)
        
        ExampleGraph = struct( ...
            'LowerTriangularWithDiagonal',     iGenerateMatrixWithDiagonal(), ...
            'LowerTriangularWithoutDiagonal',  iGenerateMatrixWithoutDiagonal());
        
    end
    
    methods(Test)
        function exampleGraphIsPartitionedAsExpected(testCase, ExampleGraph)
            % Check that the input graph is partitioned as expected.
            
            [I, J, V] = find(ExampleGraph);
            underlyingObject = amsla.common.DataStructure(I, J, V);
            
            % Partition the matix
            amslaMatrix = testCase.createPartitionerObject(underlyingObject, 10);
            partitioningResult = partition(amslaMatrix);
            
            % Verify partitioning results
            testCase.verifyTrue(partitioningResult.WasPartitioned, ...
                "Could not partition the given graph.");
        end
    end
    
    %% Manage corner cases for a single root in the sub-graph
    
    methods (Test)
        function managesSingleRootInSubGraph(testCase)
            % Check that distributing the roots into the sub-graphs does
            % not give an error if there is only one root in the whole graph.
            
            aMatrix =  gallery('poisson', 10);
            aMatrix = tril(aMatrix);
            [I, J, V] = find(aMatrix);
            underlyingObject = amsla.common.DataStructure(I, J, V);
            
            objectUnderTest = testCase.createPartitionerObject(underlyingObject, 10);
            objectUnderTest.partition();
        end
    end
end

%% HELPER FUNCTIONS

function aMatrix = iGenerateMatrixWithoutDiagonal()

% Re-initialise RNG to ensure repeatability
oldRng = rng;
restoreRng = onCleanup(@() rng(oldRng));
rng('default');

matrixSize = 200;
matrixDensity = 0.025;

% Generate a sparse triangular matrix
aMatrix =  sprand(matrixSize, matrixSize, matrixDensity);
aMatrix = tril(aMatrix);
end

function aMatrix = iGenerateMatrixWithDiagonal()
baseMatrix = iGenerateMatrixWithoutDiagonal();
aMatrix = baseMatrix + speye(size(baseMatrix));
end
