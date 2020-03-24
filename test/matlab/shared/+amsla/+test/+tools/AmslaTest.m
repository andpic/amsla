classdef (Abstract) AmslaTest < matlab.unittest.TestCase
    %AMSLATESTS Test for AMSLA.
    
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
    
    %% TEST SETUP
    
    methods (TestClassSetup)
        
        function addPath(testCase)
            % Add the path to the EnhancedGraph class.
            
            sourceDir = amsla.test.tools.internal.extractSourceDir();
            if ~iIsOnPath(sourceDir)
                oldPath = path();
                addpath(sourceDir);
                testCase.addTeardown(@path, oldPath);
            end
        end
        
    end
    
    %% HELPER METHODS
    
    methods (Access=protected)
        
        function verifyThrowsError(testCase, functionCall)
            % Verify that the function call throws an error
            import matlab.unittest.constraints.Throws;
            testCase.verifyThat( ...
                functionCall, ...
                Throws(?MException));
        end        
   
        
    
    end
end

%% HELPER FUNCTIONS

function tf = iIsOnPath(aDir)
pathString = string(path());
pathList = split(pathString, ";");
tf = any(pathList == aDir);
end
