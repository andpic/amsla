classdef tScheduler < matlab.unittest.TestCase
    %TSCHEDULER Tests for the class amsla.common.Scheduler
    
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
        
        InputGraph = struct( ...
            'SimpleLowerTriangular', struct( ...
            ));
        
    end
    
    methods(Test)
        
        function timeSlotAssignmentMatchesExpected(testCase, InputGraph)
        end
        
    end
    
end

%% HELPER FUNCTIONS

function [I, J, V, timeSlots] = iSimpleLowerTriangular()
aGraph = ;
J         = [  1, 1, 1,   2,   3,   4, 4,   5, 5, 3,   6, 6,   7,   8, 6,  9,   9,  10];
I         = [  1, 2, 3,   2,   3,   4, 5,   5, 6, 6,   6, 7,   7,   8, 8, 10,   9,  10];
V         = [  1, 1, 1,   1,   1,   1, 1,   1, 1, 1,   1, 1,   1,   1, 1,  1,   1,   1];
timeSlots = [nan, 1, 1, nan, nan, nan, 1, nan, 2, 2, nan, 3, nan, nan, 3,  1, nan, nan];
end

