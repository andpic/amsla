classdef test_TriangularSolver < amsla.test.tools.AmslaTest
    %TEST_TRIANGULARSOLVER Tests for the class
    %amsla.common.TriangularSolver.
    
    % Copyright 2020 Andrea Picciau
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
    
    %% TEST METHODS
    
    % Simple, small triangular linear system
    
    properties(TestParameter)
        AnalysisAlgorithm = struct( ...
            'LevelSet', { @(ds) amsla.test.tools.levelSetAnalysis(ds) }, ...
            'Tassl',    { @(ds) amsla.test.tools.tasslAnalysis(ds, 3) });
    end
    
    methods(Test)
        function simpleLinearSystem(testCase, AnalysisAlgorithm)
            % Check that a simple linear system is solved correctly by the
            % solver object, using different partitioners on the data
            % structure.
            
            [dataStructure, I, J, V] = ...
                amsla.test.tools.getSimpleLowerTriangularMatrix();
            
            testCase.verifyOutput(dataStructure, I, J, V, AnalysisAlgorithm);
        end
    end
    
    % Sparse matrices from the gallery
    
    properties(TestParameter)
        GalleryMatrix = struct( ...
            "Wathen",       iTriangular(iWathen(2, 1)), ...
            "WathenLarge",  iTriangular(iWathen(10, 3)), ...
            "Neumann",      iTriangular(gallery("neumann", 64)));
    end
    
    methods(Test)
        function galleryLinearSystems(testCase, GalleryMatrix, AnalysisAlgorithm)
            % Check the output of over gallery matrices.
            
            [I, J, V] = find(GalleryMatrix);
            dataStructure = amsla.common.DataStructure(I, J, V);
            
            testCase.verifyOutput(dataStructure, I, J, V, AnalysisAlgorithm);
        end
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
        function verifyOutput(testCase, dataStructure, I, J, V, analysisAlgorithm)
            % Expected output
            matrix = sparse(I, J, V);
            rhs = ones(size(matrix, 1), 1);
            expectedOutput = matrix\rhs;
            
            % Actual Output
            analysisAlgorithm(dataStructure);
            solver = amsla.common.TriangularSolver(dataStructure);
            actualOutput = solver.solve(rhs);
            
            testCase.verifyEqual(actualOutput, expectedOutput, ...
                "AbsTol", 1e-7, ...
                "RelTol", 1e-6,  ...
                "Wrong output of method 'solve'.");
        end
    end
end

%% HELPER FUNCTIONS

function outData = iTriangular(inData)
outData = tril(inData)+speye(size(inData));
end

function data = iWathen(a, b)
rng('default');
data = gallery('wathen', a, b);
end