classdef test_Scheduler < amsla.test.tools.AmslaTest
    %TEST_SCHEDULER Tests for the class amsla.common.Scheduler
    
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
        
        GraphAssignmentPair = struct( ...
            'SimpleLowerTriangularOneSubGraph', struct( ...
            'InputGraph',           { iSimpleLowerTriangularOneSubGraph() }, ...
            'ExpectedAssignment',   { iSimpleLowerTriangularOneSubGraphAssignment() }), ...
            ...
            'SimpleLowerTriangularMultipleSubGraphs', struct( ...
            'InputGraph',           { iSimpleLowerTriangularMultipleSubGraphs() }, ...
            'ExpectedAssignment',   { iSimpleLowerTriangularMultipleSubGraphsAssignment() }), ...
            ...
            'SmallWarthenMultipleSubGraphs', struct( ...
            'InputGraph',           { iSmallWarthenMultipleSubGraphs() }, ...
            'ExpectedAssignment',   { iSmallWarthenMultipleSubGraphsAssignment() }), ...
            ...
            ...
            'SmallWarthenOneSubGraph', struct( ...
            'InputGraph',           { iSmallWarthenOneSubGraph() }, ...
            'ExpectedAssignment',   { iSmallWarthenOneSubGraphAssignment() }));
        
    end
    
    methods(Test)
        
        function timeSlotAssignmentMatchesExpected(testCase, GraphAssignmentPair)
            % Check that the edge time-slot assignment matches what is
            % expected.
            
            inputGraph = GraphAssignmentPair.InputGraph;
            scheduler = amsla.common.Scheduler(inputGraph);
            
            testCase.verifyWarningFree(@() scheduler.scheduleOperations(), ...
                "The method 'scheduleOperations' did not complete without problems.");
            
            testCase.verifyTimeSlotAssignment(inputGraph, ...
                GraphAssignmentPair.ExpectedAssignment);
        end
        
    end
    
    %% HELPER METHODS
    
    methods(Access=private)
        
        function verifyTimeSlotAssignment(testCase, inputGraph, expectedAssignment)
            %verifyTimeSlotAssignment - Verify that the edge time-slot
            %assignment matches what is expected.
            
            validateattributes(inputGraph, {'amsla.common.DataStructure'}, {'nonempty', 'scalar'});
            validateattributes(expectedAssignment, {'table'}, {'nonempty'});
            
            listOfNodes = inputGraph.listOfNodes();
            for currNode = listOfNodes
                
                % Verify that exiting edges match the expected assignment
                exitingEdges = inputGraph.exitingEdgesOfNode(currNode);
                
                for currEdge = exitingEdges
                    currExitingNode = inputGraph.exitingNodeOfEdge(currEdge);
                    actualTimeSlot = inputGraph.timeSlotOfEdge(currEdge);
                    
                    expectedTimeSlot = expectedAssignment.TimeSlot( ...
                        expectedAssignment.I == currExitingNode & ...
                        expectedAssignment.J == currNode);
                    
                    testCase.verifyEqual(actualTimeSlot, expectedTimeSlot, ...
                        sprintf("Mismatch in assignment for time slot ID %d (%d -> %d)", ...
                        currEdge, currNode, currExitingNode));
                end
                
            end
        end
        
    end
    
end

%% HELPER FUNCTIONS

function aGraph = iSimpleLowerTriangularOneSubGraph()
[I, J, V] = iSimpleLowerTriangularGraph();
aGraph = amsla.common.DataStructure(I, J, V);
iAssignAllNodesToOneSubGraph(aGraph);
end

function expectedAssignment = iSimpleLowerTriangularOneSubGraphAssignment()
[I, J, ~, timeSlots, ~] = iSimpleLowerTriangularGraph();
expectedAssignment = table(J', I', timeSlots', ...
    'VariableNames', {'J', 'I', 'TimeSlot'});
end

function aGraph = iSimpleLowerTriangularMultipleSubGraphs()
[I, J, V] = iSimpleLowerTriangularGraph();
aGraph = amsla.common.DataStructure(I, J, V);
aGraph.setSubGraphOfNode( ...
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], ...
    [1, 1, 1, 2, 2, 3, 3, 3, 4,  4,  4]);
end

function expectedAssignment = iSimpleLowerTriangularMultipleSubGraphsAssignment()
[I, J, ~, ~, timeSlots] = iSimpleLowerTriangularGraph();
expectedAssignment = table(J', I', timeSlots', ...
    'VariableNames', {'J', 'I', 'TimeSlot'});
end

function [I, J, V, timeSlotOneSubGraph, timeSlotMultipleSubGraphs] = iSimpleLowerTriangularGraph()
allData = [ ...
    1,  1,   3,   1,   1;
    2,  1,   1,   2,   2;
    3,  1,   1,   2,   2;
    2,  2,   1,  iN,  iN;
    3,  3,   1,  iN,  iN;
    4,  4,   1,  iN,  iN;
    5,  4,   1,   1,   1;
    5,  5,   1,  iN,  iN;
    6,  5,   1,   3,  -1;
    6,  3,   1,   3,  -1;
    6,  6,   3,   4,   1;
    7,  6,   1,   5,   2;
    7,  7,   1,  iN,  iN;
    8,  8,   1,  iN,  iN;
    8,  6,   1,   5,   2;
    10, 9,   2,   1,   1;
    9,  9,   1,  iN,  iN;
    10, 10,  1,  iN,  iN;
    11, 10,  1,   2,   2;
    11, 11,  3,   3,   3];

I = allData(:, 1);
J = allData(:, 2);
V = allData(:, 3);
timeSlotOneSubGraph = allData(:, 4);
timeSlotMultipleSubGraphs = allData(:, 5);
end

function aGraph = iSmallWarthenMultipleSubGraphs()
[I, J, V] = iSmallWarthenGraph();
aGraph = amsla.common.DataStructure(I, J, V);
aGraph.setSubGraphOfNode( ...
    [1, 2, 3, 4, 5], ...
    [1, 1, 1, 2, 2]);
end

function expectedAssignment = iSmallWarthenMultipleSubGraphsAssignment()
[I, J, ~, ~, timeSlots] = iSmallWarthenGraph();
expectedAssignment = table(J, I, timeSlots, ...
    'VariableNames', {'J', 'I', 'TimeSlot'});
end

function [I, J, V, timeSlotOneSubGraph, timeSlotMultipleSubGraphs] = iSmallWarthenGraph()
allData = [ ...
    1, 1,  11.863, 1,  1;
    2, 1, -10.863, 2,  2;
    2, 2,  58.936, 3,  3;
    3, 1,   3.621, 4,  4;
    3, 2, -10.863, 4,  4;
    3, 3,   23.94, 5,  5;
    4, 3, -12.077, 6, -1;
    4, 4,  65.412, 7,  1;
    5, 3,  4.0257, 8, -1;
    5, 4, -12.077, 8,  2;
    5, 5,  13.077, 9,  3];

I = allData(:, 1);
J = allData(:, 2);
V = allData(:, 3);
timeSlotOneSubGraph = allData(:, 4);
timeSlotMultipleSubGraphs = allData(:, 5);
end

function aGraph = iSmallWarthenOneSubGraph()
[I, J, V] = iSmallWarthenGraph();
aGraph = amsla.common.DataStructure(I, J, V);
iAssignAllNodesToOneSubGraph(aGraph);
end

function expectedAssignment = iSmallWarthenOneSubGraphAssignment()
[I, J, ~, timeSlots, ~] = iSmallWarthenGraph();
expectedAssignment = table(J, I, timeSlots, ...
    'VariableNames', {'J', 'I', 'TimeSlot'});
end

function iAssignAllNodesToOneSubGraph(dataStructure)
allNodes = dataStructure.listOfNodes();
dataStructure.setSubGraphOfNode(allNodes, ones(size(allNodes)));
end

function outData = iN()
outData = amsla.common.nullId(1);
end