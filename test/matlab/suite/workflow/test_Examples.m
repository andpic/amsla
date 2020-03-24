classdef test_Examples < amsla.test.tools.AmslaTest
    %TEST_EXAMPLES Runs examples as workflow tests.
    
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
    
    properties(TestParameter)
        
        ExampleScript = struct( ...
            "lowerTriangularMarix",     {"lowerTriangularMatrix.m"});
        
    end
    
    methods(Test)
        
        function runExample(testCase, ExampleScript)
            % Run an example as a test.
            
            existingFigures = get(groot, "Children");
            testCase.addTeardown(@() iRestoreFiguresTo(existingFigures));
            
            % Change folder to the examples
            testCase.applyFixture(iChangeToFolderFixture(iExamplesFolder()));
            
            % Run script
            run(ExampleScript);
        end
        
    end
end

%% HELPER FUNCTIONS

function folderPath = iExamplesFolder()
folderPath = fullfile(amsla.test.tools.internal.extractSourceDir, ...
    "..", ...
    "..", ...
    "examples", ...
    "matlab");
end

function fix = iChangeToFolderFixture(newFolder)
fix = matlab.unittest.fixtures.CurrentFolderFixture(newFolder);
end

function iRestoreFiguresTo(existingFigures)
currentFigures = get(groot, "Children");
figuresToClose = setdiff(currentFigures, existingFigures);
close(figuresToClose);
end