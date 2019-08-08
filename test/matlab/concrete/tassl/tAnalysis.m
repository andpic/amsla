classdef tAnalysis < amsla.test.shared.AnalysisTests
    %TANALYSIS Tests for the class amsla.tassl.Analysis
    
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
    
    %% Graph is correctly reset
    
    methods(Test)
        function exampleGraphIsPartitionedAsExpected(testCase)
            % Generate a sparse lower triangular matrix with a semi-random sparsity
            % pattern and check that the partition is correctly reset at every tentative.
            
            % Re-initialise RNG to ensure repeatability
            oldRng = rng;
            testCase.addTeardown(@() rng(oldRng));
            rng('default');
            
            matrixSize = 200;
            matrixDensity = 0.025;
            
            % Generate a sparse triangular matrix
            aMatrix =  sprand(matrixSize, matrixSize, matrixDensity);
            aMatrix = tril(aMatrix);
            [I, J, V] = find(aMatrix);
            
            % TASSL algorithm
            tasslMatrix = amsla.tassl.Analysis(I, J, V, 10);
            partitioningResult = partition(tasslMatrix);
            
            % Verify partitioning results
            testCase.verifyTrue(partitioningResult.WasPartitioned, ...
                "TASSL could not partition the given graph.");
            testCase.verifyEqual(partitioningResult.NumberOfTentatives, 3, ...
                "TASSL should have taken 3 tentatives to partition this graph.");
            testCase.verifyEqual(partitioningResult.FinalCriterion, "descend outdegree", ...
                "TASSL should have used 'descend outdegree' to partition this graph.");
            testCase.verifyEqual(partitioningResult.RootNodeDensity, 0.250, ...
                "Wrong number of root nodes per sub-graph to partition this graph with TASSL.");
        end
    end
    
    %% IMPLEMENTATION OF ABSTRACT METHODS IN THE BASE CLASS
    
    methods(Access=public)
        function analysisObject = createAnalysisObject(~, I, J, V, maxSubGraphSize)
            analysisObject = amsla.tassl.Analysis(I, J, V, maxSubGraphSize);
        end
    end
end