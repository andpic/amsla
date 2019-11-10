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
        
        GraphAssignmentPair = struct( ...
            'SimpleLowerTriangular', struct( ...
            'InputGraph',           { iSimpleLowerTriangularGraph() }, ...
            'ExpectedAssignment',   { iSimpleLowerTriangularAssignment() }) ...
            );
        
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

function aGraph = iSimpleLowerTriangularGraph()
[I, J, V] = iSimpleLowerTriangular();
aGraph = amsla.common.DataStructure(I, J, V);
end

function expectedAssignment = iSimpleLowerTriangularAssignment()
[I, J, ~, timeSlots] = iSimpleLowerTriangular();
expectedAssignment = table(J', I', timeSlots', ...
    'VariableNames', {'J', 'I', 'TimeSlot'});
end

function [I, J, V, timeSlots] = iSimpleLowerTriangular()
J         = [  1, 1, 1,   2,   3,   4, 4,   5, 5, 3,   6, 6,   7,   8, 6,  9,   9,  10];
I         = [  1, 2, 3,   2,   3,   4, 5,   5, 6, 6,   6, 7,   7,   8, 8, 10,   9,  10];
timeSlots = [nan, 1, 1, nan, nan, nan, 1, nan, 2, 2, nan, 3, nan, nan, 3,  1, nan, nan];

V         = [  1, 1, 1,   1,   1,   1, 1,   1, 1, 1,   1, 1,   1,   1, 1,  1,   1,   1];
end