classdef tEnhancedGraph < amsla.test.tools.AmslaTest
    %TENHANCEDGRAPH Tests for class amsla.common.EnhancedGraph
    
    % Copyright 2018 Andrea Picciau
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
    
    methods (Test)
        
        function checkChildrenOfNodeVector(testCase)
            % Check the method "childrenOfNode" with a vector input.
            
            % Create a graph
            [aGraph, ~, ~, ~] = iGetASimpleMatrix();
            
            nodes = 1:10;
            expectedOutput = {[2, 3], [], 6, 5, 6, [7, 8], [], [], 10, []};
            
            testCase.verifyEqual( ...
                childrenOfNode(aGraph, nodes), ...
                expectedOutput);
        end
        
        function checkExitingEdgesOfNodeVector(testCase)
            % Check method "exitingEdgesOfNode" with vector inputs.
            
            % Create a graph
            [aGraph, I, J, ~] = iGetASimpleMatrix();
            
            nodes = 1:10;
            
            % Expected output is obtained by edges sorted by row first and
            % then by column
            [sortedI, sortedJ] = iSortEdges(I,J);
            expectedOutput = arrayfun(@(x) find(sortedI~=x & sortedJ==x)', nodes, 'UniformOutput', false);
            
            testCase.verifyEqual( ...
                exitingEdgesOfNode(aGraph, nodes), ...
                expectedOutput);
        end
        
        function checkParentsOfNodeVector(testCase)
            % Check the method "parentsOfNode" with a vector input.
            
            % Create a graph
            [aGraph, ~, ~, ~] = iGetASimpleMatrix();
            
            nodes = 1:10;
            
            expectedOutput = {[], 1, 1, [], 4, [3, 5], 6, 6, [], 9};
            
            testCase.verifyEqual( ...
                parentsOfNode(aGraph, nodes), ...
                expectedOutput);
        end
        
        function checkParentsOfNodeVectorWithDuplicates(testCase)
            % Check the method "parentsOfNode" with a vector input and duplicates.
            
            % Create a graph
            [aGraph, ~, ~, ~] = iGetASimpleMatrix();
            
            nodes = [6, 2, 6];
            
            expectedOutput = {[3, 5], 1, [3, 5]};
            
            testCase.verifyEqual( ...
                parentsOfNode(aGraph, nodes), ...
                expectedOutput);
        end
        
        function checkEnteringEdgesOfNodeVector(testCase)
            % Check method "exitingEdgesOfNode" with vector inputs.
            
            % Create a graph
            [aGraph, I, J, ~] = iGetASimpleMatrix();
            
            nodes = 1:10;
            % Expected output is obtained by edges sorted by row first and
            % then by column
            [sortedI, sortedJ] = iSortEdges(I,J);
            expectedOutput = arrayfun(@(x) find(sortedI==x & sortedJ~=x)', nodes, 'UniformOutput', false);
            
            testCase.verifyEqual( ...
                enteringEdgesOfNode(aGraph, nodes), ...
                expectedOutput);
        end
        
        function checkLoopEdgesOfNodeVector(testCase)
            % Check method "exitingEdgesOfNode" with vector inputs.
            
            % Create a graph
            [aGraph, I, J, ~] = iGetASimpleMatrix();
            
            nodes = 1:10;
            % Expected output is obtained by edges sorted by row first and
            % then by column
            [sortedI, sortedJ] = iSortEdges(I,J);
            expectedOutput = arrayfun(@(x) find(sortedI==x & sortedJ==x)', nodes, 'UniformOutput', true);
            
            testCase.verifyEqual( ...
                loopEdgesOfNode(aGraph, nodes), ...
                expectedOutput);
        end
        
        function checkListOfComponentsEmpty(testCase)
            % Check method "listOfComponents" when components where not
            % computed.
            
            % Create a graph
            [aGraph, ~, ~, ~] = iGetASimpleMatrix();
            
            expectedOutput = [];
            
            testCase.verifyEqual( ...
                listOfComponents(aGraph), ...
                expectedOutput);
        end
        
        function checkListOfComponentsAfterComputation(testCase)
            % Check method "listOfComponents" after components have been
            % computed.
            
            % Create a graph
            [aGraph, ~, ~, ~] = iGetASimpleMatrix();
            
            aGraph.computeComponents();
            
            expectedOutput = [1, 2];
            
            testCase.verifyEqual( ...
                listOfComponents(aGraph), ...
                expectedOutput);
        end
        
        function checkListOfComponentsWithSizes(testCase)
            % Check method "listOfComponents" after components have been
            % computed.
            
            % Create a graph
            [aGraph, ~, ~, ~] = iGetASimpleMatrix();
            
            aGraph.computeComponents();
            
            expectedComponentIds = [1, 2];
            expectedComponentSizes = [8, 2];
            
            [actualIds, actualSizes] = listOfComponents(aGraph);
            
            testCase.verifyEqual( ...
                actualIds, ...
                expectedComponentIds);
            
            testCase.verifyEqual( ...
                actualSizes, ...
                expectedComponentSizes);
        end
        
        function checkRootsOfComponentsAfterComputation(testCase)
            % Check method "rootsOfComponent" after components have been
            % computed.
            
            % Create a graph
            [aGraph, ~, ~, ~] = iGetASimpleMatrix();
            
            aGraph.computeComponents();
            
            expectedOutput = {[1, 4], 9};
            
            testCase.verifyEqual( ...
                rootsOfComponent(aGraph, [1, 2]), ...
                expectedOutput);
        end
        
        function checkComponentOfNodeVector(testCase)
            % Check method "componentOfNode" after components have been
            % computed, when inputs are a vector.
            
            % Create a graph
            [aGraph, ~, ~, ~] = iGetASimpleMatrix();
            
            aGraph.computeComponents();
            
            inputs = 1:10;
            expectedOutput = [ones(1,8), 2*ones(1,2)];
            
            testCase.verifyEqual( ...
                componentOfNode(aGraph, inputs), ...
                expectedOutput);
        end
        
        function checkSetGetSubGraphOfNodeVector(testCase)
            % Check method "setSubGraphOfNode" when inputs are a vector.
            
            % Create a graph
            [aGraph, ~, ~, ~] = iGetASimpleMatrix();
            
            inputs = 1:10;
            subGraphs = 100-inputs;
            
            % Set sub-graphs
            aGraph.setSubGraphOfNode(inputs, subGraphs);
            
            testCase.verifyEqual( ...
                subGraphOfNode(aGraph, inputs), ...
                subGraphs);
        end
        
        function checkSetGetSubGraphOfNodeVectorDuplicated(testCase)
            % Check method "setSubGraphOfNode" when inputs are a vector
            % with duplicate entries
            
            % Create a graph
            [aGraph, ~, ~, ~] = iGetASimpleMatrix();
            
            inputs = [1, 1, 1, 2, 3];
            subGraphs = 100-inputs;
            
            % Set sub-graphs
            aGraph.setSubGraphOfNode(inputs, subGraphs);
            
            testCase.verifyEqual( ...
                subGraphOfNode(aGraph, inputs), ...
                subGraphs);
        end
        
        function checkSetGetSubGraphOfNodeVectorAmbiguous(testCase)
            % Check method "setSubGraphOfNode" when inputs are a vector
            % with duplicate and ambiguous entries
            
            % Create a graph
            [aGraph, ~, ~, ~] = iGetASimpleMatrix();
            
            inputs = [1, 1, 1, 2, 3];
            subGraphs = [1, 2, 1, 2, 3];
            
            % Check that an error is thrown
            testCase.verifyThrowsError( ...
                @() aGraph.setSubGraphOfNode(inputs, subGraphs));
        end
        
    end
end

function [aGraph, I, J, V] = iGetASimpleMatrix()
J = [1, 1, 1, 2, 3, 4, 4, 5, 5,  3,  6,  6,  7,  8,  6,  9,  9, 10];
I = [1, 2, 3, 2, 3, 4, 5, 5, 6,  6,  6,  7,  7,  8,  8, 10,  9, 10];
numberOfElements = numel(J);
V = ones(1, numberOfElements);
aGraph = amsla.common.DataStructure(I, J, V);
end

function [sortedI, sortedJ] = iSortEdges(I,J)
sortedEdges = sortrows([I', J'], [1, 2]);
sortedI = sortedEdges(:, 1);
sortedJ = sortedEdges(:, 2);
end
