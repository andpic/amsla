classdef test_DataStructure < amsla.test.tools.AmslaTest
    %TEST_DATASTRUCTURE Tests for class amsla.common.DataStructure
    
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
    
    
    methods (Test)
        
        %% "Graph API" for nodes and edges
        
        function checkChildrenOfNodeVector(testCase)
            % Check the method "childrenOfNode" with a vector input.
            
            % Create a graph
            [aGraph, ~, ~, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
            nodes = 1:10;
            expectedOutput = {[2, 3], [], 6, 5, 6, [7, 8], [], [], 10, []};
            
            testCase.verifyEqual( ...
                childrenOfNode(aGraph, nodes), ...
                expectedOutput);
        end
        
        function checkWeightsOfEdgeUnsortedAndRepetitions(testCase)
            % Check method "weightsOfEdge" with vector inputs.
            
            % Create a graph
            [aGraph, ~, ~, V] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
            edges = [3, 2, 2, 10, 5, 4];
            expectedWeights = V(edges)';
            
            testCase.verifyEqual( ...
                weightOfEdge(aGraph, edges), ...
                expectedWeights, ...
                "The weights do not match those expected.");
        end
        
        function checkExitingEdgesOfNodeVector(testCase)
            % Check method "exitingEdgesOfNode" with vector inputs.
            
            % Create a graph
            [aGraph, I, J, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
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
            [aGraph, ~, ~, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
            nodes = 1:10;
            
            expectedOutput = {[], 1, 1, [], 4, [3, 5], 6, 6, [], 9};
            
            testCase.verifyEqual( ...
                parentsOfNode(aGraph, nodes), ...
                expectedOutput);
        end
        
        function checkParentsOfNodeVectorWithDuplicates(testCase)
            % Check the method "parentsOfNode" with a vector input and duplicates.
            
            % Create a graph
            [aGraph, ~, ~, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
            nodes = [6, 2, 6];
            
            expectedOutput = {[3, 5], 1, [3, 5]};
            
            testCase.verifyEqual( ...
                parentsOfNode(aGraph, nodes), ...
                expectedOutput);
        end
        
        function checkEnteringEdgesOfNodeVector(testCase)
            % Check method "exitingEdgesOfNode" with vector inputs.
            
            % Create a graph
            [aGraph, I, J, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
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
            [aGraph, I, J, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
            nodes = 1:10;
            % Expected output is obtained by edges sorted by row first and
            % then by column
            [sortedI, sortedJ] = iSortEdges(I,J);
            expectedOutput = arrayfun(@(x) find(sortedI==x & sortedJ==x)', nodes, 'UniformOutput', true);
            
            testCase.verifyEqual( ...
                loopEdgesOfNode(aGraph, nodes), ...
                expectedOutput);
        end
    end
    
    properties(TestParameter)
        
        EdgeNodeAssignment = struct( ...
            'Scalar', struct( ...
            'InputEdge', { 1 }, ...
            'ExitNode',  { 1 }), ...
            ...
            'Vector', struct( ...
            'InputEdge', { [1, 3, 5] }, ...
            'ExitNode',  { [1, 2, 3] }));
        
    end
    
    methods(Test)
        
        function exitNodesOfEdgesMatchExpected(testCase, EdgeNodeAssignment)
            % Check that, given some input edge IDs, the exit nodes are
            % identified correctly,
            
            aGraph = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
            inputEdge = EdgeNodeAssignment.InputEdge;
            expectedExitNode = EdgeNodeAssignment.ExitNode;
            
            actualExitNode = aGraph.exitingNodeOfEdge(inputEdge);
            
            testCase.verifyEqual(actualExitNode, expectedExitNode, ...
                "Output exit nodes are not what was expected.");
        end
    end
    
    %% Sub-graph API
    methods(Test)
        
        function listOfSubGraphsShouldBeEmptyWhenNotPartitioned(testCase)
            % The method "listOfSubGraph" should be empty if the graph
            % hasn't been partitioned.
            
            % Create a graph
            [aGraph, ~, ~, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
            subGraphIds = aGraph.listOfSubGraphs();
            testCase.verifyEmpty(subGraphIds, ...
                "The list of sub-graphs should be empty when the graph hasn't been partitioned.");
        end
        
        function listOfSubGraphShouldBeEmptyIfNotAllNodesAreAssigned(testCase)
            % The method "listOfSubGraph" should return an empty array if
            % not all nodes have been assigned.
            
            % Create a partially-assigned graph
            aGraph = iFullAssignedSimpleGraph();
            aGraph.setSubGraphOfNode(1, iNullId());
            
            subGraphIds = aGraph.listOfSubGraphs();
            testCase.verifyEmpty(subGraphIds, ...
                "The list of sub-graphs should be empty when at least one node is not assigned.");
        end
        
        function listOfSubGraphShouldMatchOnFullPartitioning(testCase)
            % The method "listOfSubGraph" should return the IDS of all the
            % sub-graphs when the partitioning is complete.
            
            aGraph = iFullAssignedSimpleGraph();
            
            subGraphIds = aGraph.listOfSubGraphs();
            testCase.verifyEqual(subGraphIds, 1:5, ...
                "The list of sub-graphs is incorrect.");
        end
        
        function listOfSubGraphShouldBeEmptyAfterReset(testCase)
            % The method "listOfSubGraph" should return an empty array after
            % the method "resetSubGraphs".
            
            aGraph = iFullAssignedSimpleGraph();
            iResetSubGraphs(aGraph);
            
            subGraphIds = aGraph.listOfSubGraphs();
            testCase.verifyEmpty(subGraphIds, ...
                "The list of sub-graphs should be empty after a reset.");
        end
        
        function checkSetGetSubGraphOfNodeVector(testCase)
            % Check method "setSubGraphOfNode" when inputs are a vector.
            
            % Create a graph
            [aGraph, ~, ~, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
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
            [aGraph, ~, ~, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
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
            [aGraph, ~, ~, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
            inputs = [1, 1, 1, 2, 3];
            subGraphs = [1, 2, 1, 2, 3];
            
            % Check that an error is thrown
            testCase.verifyThrowsError( ...
                @() aGraph.setSubGraphOfNode(inputs, subGraphs));
        end
        
        %% Time-slot API
        
        function assignmentOfEdgeToTimeSlotIsRecordedCorrectly(testCase)
            % Check that the assignment to an edge to a time-slot is recorded
            % correctly in the object.
            
            [aGraph, ~, ~, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
            edgeId = 1;
            initialTimeSlot = aGraph.timeSlotOfEdge(edgeId);
            testCase.verifyEqual(initialTimeSlot, iNullId(), ...
                "Initially, all edges should be assigned to time-slot ID null.");
            
            expectedTimeSlotId = 10;
            aGraph.setTimeSlotOfEdge(edgeId, expectedTimeSlotId);
            actualTimeSlotId = aGraph.timeSlotOfEdge(edgeId);
            testCase.verifyEqual(actualTimeSlotId, expectedTimeSlotId, ...
                "The edge was not correctly assigned to the time-slot.");
            
            iResetTimeSlots(aGraph);
            actualTimeSlotId = aGraph.timeSlotOfEdge(edgeId);
            testCase.verifyEqual(actualTimeSlotId, iNullId(), ...
                "After a reset, all edges should be assigned to time-slot ID null.");
        end
        
        function edgesInSubGraphAndTimeSlotFoundCorrectly(testCase)
            % Check that the edges in a given time-slot ID and sub-graph ID
            % are identified correctly.
            
            [aGraph, ~, ~, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
            aGraph = iSimpleMatrixLevelSetPartitioning(aGraph);
            aGraph = iSimpleMatrixLevelSetScheduling(aGraph);
            
            expectedEdgeIds = [2, 4, 7, 17]';
            actualEdgeIds = aGraph.edgesInSubGraphAndTimeSlot(2, -2);
            testCase.verifyEqual(actualEdgeIds, expectedEdgeIds, ...
                "Edges in the second sub-graph were not identified correctly.");
        end
        
        function timeSlotsInSubGraph(testCase)
            % Check that the time slots in a given sub-graph are identified
            % correctly.
            
            [aGraph, ~, ~, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();
            
            aGraph = iSimpleMatrixLevelSetPartitioning(aGraph);
            aGraph = iSimpleMatrixLevelSetSchedulingMultipleTimeSlots(aGraph);
            
            expectedTimeSlots = [-2, 1]';
            actualTimeSlots = aGraph.timeSlotsInSubGraph(2);
            testCase.verifyEqual(actualTimeSlots, expectedTimeSlots, ...
                "The time-slots in the 2nd sub-graph were not identified correctly.");
            
            expectedTimeSlots = [-2, -1]';
            actualTimeSlots = aGraph.timeSlotsInSubGraph(3);
            testCase.verifyEqual(actualTimeSlots, expectedTimeSlots, ...
                "The time-slots in the 3rd sub-graph were not identified correctly.");
        end
    end
end

%% HELPER FUNCTIONS

function [sortedI, sortedJ] = iSortEdges(I,J)
sortedEdges = sortrows([I', J'], [1, 2]);
sortedI = sortedEdges(:, 1);
sortedJ = sortedEdges(:, 2);
end

function aGraph = iFullAssignedSimpleGraph()
[aGraph, ~, ~, ~] = amsla.test.tools.getSimpleLowerTriangularMatrix();

aGraph.setSubGraphOfNode( ...
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], ...
    [1, 1, 1, 2, 2, 3, 4, 4, 5, 5]);
end

function id = iNullId()
id = amsla.common.nullId();
end

function ds = iSimpleMatrixLevelSetPartitioning(ds)
nodeIds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
subgIds = [1, 2, 2, 1, 2, 3, 4, 4, 1, 2];
ds.setSubGraphOfNode(nodeIds, subgIds);
end

function ds = iSimpleMatrixLevelSetScheduling(ds)
edgeIdSlot = [...
    1,  iNullId; ...
    2,  -2; ...
    3,  iNullId; ...
    4,  -2; ...
    5,  iNullId; ...
    6,  iNullId; ...
    7,  -2; ...
    8,  iNullId; ...
    9,  -2; ...
    10, -2; ...
    11, iNullId; ...
    12, -2; ...
    13, iNullId; ...
    14, -2; ...
    15, iNullId; ...
    16, iNullId; ...
    17, -2; ...
    18, iNullId];
edgeIds = edgeIdSlot(:, 1);
timeSlotIds = edgeIdSlot(:, 2);
ds.setTimeSlotOfEdge(edgeIds, timeSlotIds);
end

function ds = iSimpleMatrixLevelSetSchedulingMultipleTimeSlots(ds)
edgeIdSlot = [...
    1,  iNullId; ...
    2,  -2; ...
    3,  iNullId; ...
    4,  1; ...
    5,  iNullId; ...
    6,  iNullId; ...
    7,  -2; ...
    8,  iNullId; ...
    9,  -2; ...
    10, -1; ...
    11, iNullId; ...
    12, -2; ...
    13, iNullId; ...
    14, -2; ...
    15, iNullId; ...
    16, iNullId; ...
    17, -2; ...
    18, iNullId];
edgeIds = edgeIdSlot(:, 1);
timeSlotIds = edgeIdSlot(:, 2);
ds.setTimeSlotOfEdge(edgeIds, timeSlotIds);
end

function iResetTimeSlots(dataStructure)
allEdges = dataStructure.listOfEdges();
dataStructure.setTimeSlotOfEdge(allEdges, amsla.common.nullId(size(allEdges)));
end

function iResetSubGraphs(dataStructure)
allNodes = dataStructure.listOfNodes();
dataStructure.setSubGraphOfNode(allNodes, amsla.common.nullId(size(allNodes)));
end