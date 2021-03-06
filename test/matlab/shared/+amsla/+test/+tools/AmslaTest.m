classdef (Abstract) AmslaTest < amsla.test.tools.internal.AmslaTest
    %AMSLATESTS Test for AMSLA.
    
    % Copyright 2019-2020 Andrea Picciau
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
