classdef tGraphWrapper < a2msla.test.tools.A2mslaTest
    %TGRAPHRAPPER Tests for the class a2msla.levelSet.internal.GraphWrapper
    
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
    
    %% findRoots
    
    properties(TestParameter)
        GraphToTest = struct(...
            'WithoutLoops',  iGraphWithoutLoops(), ...
            'WithLoops',     iGraphWithLoops() ...
            );
    end
    
    methods(Test)
        
        function rootsAreIdentifiedInAllGraphTypes(testCase, GraphToTest)
            % Root vertices are identified correctly whether the vertex has
            % a loop over itself or not.
            
            actualRoots = GraphToTest.findRoots();
            expectedRoots = [1, 4, 9];
            
            testCase.verifyEqual(actualRoots, expectedRoots, ...
                "Graph roots were not identified correctly.");
        end
        
    end
    
    
end

%% HELPER FUNCTIONS

function [aGraph, I, J, V] = iGraphWithLoops()
[I, J, V] = iExampleGraph();
aGraph = a2msla.levelSet.internal.GraphWrapper(I, J, V);
end

function [aGraph, I, J, V] = iGraphWithoutLoops()
[I, J, V] = iExampleGraph();
isLoop = I==J;
I(isLoop) = [];
J(isLoop) = [];
V(isLoop) = [];
aGraph = a2msla.levelSet.internal.GraphWrapper(I, J, V);
end

function [I, J, V] = iExampleGraph()
J = [1, 1, 1, 2, 3, 4, 4, 5, 5,  3,  6,  6,  7,  8,  6,  9,  9, 10];
I = [1, 2, 3, 2, 3, 4, 5, 5, 6,  6,  6,  7,  7,  8,  8, 10,  9, 10];
numberOfElements = numel(J);
V = ones(1, numberOfElements);
end