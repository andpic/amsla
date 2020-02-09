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
            
            % Expected output
            matrix = sparse(I, J, V);
            rhs = ones(size(matrix, 1), 1);
            expectedOutput = matrix\rhs;
            
            % Actual Output
            AnalysisAlgorithm(dataStructure);
            solver = amsla.common.TriangularSolver(dataStructure);
            actualOutput = solver.solve(rhs);
            
            testCase.verifyEqual(actualOutput, expectedOutput, ...
                "Wrong output of method 'solve'.");
        end
    end
end