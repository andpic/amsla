classdef test_SparseMatrix < amsla.test.tools.AmslaPerformanceTest
    %TEST_SPARSEMATRIX Performance tests for SparseMatrix.
    
    % Copyright 2018-2019 Andrea Picciau
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
    
    %% SETUP/TEARDOWN
    
    methods(TestClassSetup)
        
        function suppressWarningAboutSize(testCase)
            % Suppress the warning about sub-graph size in the levelSet
            % case.
            
            testCase.applyFixture(iSuppressWarning("amsla:levelSet:sizeIgnored"));
        end
        
    end
    
    %% TEST SPECS
    
    % Analysis
    
    properties(TestParameter)
        
        Algorithm = struct( ...
            "LevelSet",  { "levelset" }, ...
            "Tassl",     { "Tassl" });
        
        DataSize = struct( ...
            "Size16",  { 2^4 }, ...
            "Size32",  { 2^5 }, ...
            "Size64",  { 2^6 }, ...
            "Size128", { 2^7 }, ...
            "Size256", { 2^8 });
        
    end
    
    methods(Test)
        
        function measureWorkflowOnToeppen(testCase, Algorithm, DataSize)
            % Execute the whole workflow over "Toeppen" matrices from MATLAB's
            % gallery.

            data = iTriangular(gallery("toeppen", DataSize));
            [I,J,V] = find(data);
            
            % Analysis
            matrix = amsla.SparseMatrix(I, J, V, Algorithm);
            testCase.startMeasuring("analyse");
            matrix = matrix.analyse(10);
            testCase.stopMeasuring("analyse");

            % Triangular solve
            rhs = ones([size(data, 1), 1]);
            testCase.startMeasuring("solve");
            result = matrix.solve(rhs); %#ok<NASGU>
            testCase.stopMeasuring("solve");
        end
        
    end
    
end

%% HELPER FUNCTION

function outData = iTriangular(inData)
outData = tril(inData)+speye(size(inData));
end

function fixture = iSuppressWarning(warningCode)
fixture = matlab.unittest.fixtures.SuppressedWarningsFixture(warningCode);
end