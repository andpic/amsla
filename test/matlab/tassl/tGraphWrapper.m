classdef tGraphWrapper < hA2mslaTest
    %TGRAPHRAPPER Tests for the class a2msla.tassl.GraphWrapper
    
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
    
    %% TEST PARAMETERS
    
    properties (TestParameter)
        
        SortingCriterion = { ...
            "ascend outdegree", ...
            "descend outdegree", ...
            "ascend indegree", ...
            "descend indegree", ...
            };
        
    end
    
    %% TEST METHODS
    
    methods (Test)
        
        function checkSetSortingCriterion(testCase, SortingCriterion)
            % Check that setting a valid sorting criterion doesn't throw an
            % error
            aGraph = iGetASimpleMatrix();
            testCase.verifyWarningFree(@() aGraph.setSortingCriterion(SortingCriterion));
        end
        
        function checkInvalidSetSortingCriterion(testCase)
            % Check that setting an invalid sorting criterion throws an
            % error
            
            aGraph = iGetASimpleMatrix();
            % Check that an error is thrown
            import matlab.unittest.constraints.Throws;
            testCase.verifyThrowsError( ...
                @() aGraph.setSortingCriterion("indegree"));
        end
        
        function checkDistributeRootsToSubGraphs(testCase)
            % Check that roots are distributed to sub-graphs as expected
            % for axample matrix
            aGraph = iGetASimpleMatrix();
            
            expectedRoots = [1, 4, 9];
            expectedSubGraphs = [1, 2, 4];
            
            aGraph.setSortingCriterion("descend outdegree");
            [actualRoots, actualSubGraphs] = aGraph.distributeRootsToSubGraphs(1);
            
            testCase.verifyEqual(actualRoots, expectedRoots);
            testCase.verifyEqual(actualSubGraphs, expectedSubGraphs);
        end
        
        function checkSubGraphOfNode(testCase)
            % Check that the method subGraphOfNode returns what is expected
            % in case of nothing being assigned
            aGraph = iGetASimpleMatrix();
            
            aGraph.setSortingCriterion("descend outdegree");
            
            nodeIds              = [1, 2, 3, 4, 9, 10];
            actualSubGraphIds = aGraph.subGraphOfNode(nodeIds);
            expectedSubGraphIds = a2msla.common.nullId(size(actualSubGraphIds));
            
            testCase.verifyEqual(actualSubGraphIds, expectedSubGraphIds);
        end
        
        function checkAssignNodeToSubGraph(testCase)
            % Check that the assignment of nodes to sub-graphs happens
            % correctly
            aGraph = iGetASimpleMatrix();
            
            aGraph.setSortingCriterion("descend outdegree");
            
            nodeIds              = [1, 2, 3, 4, 9, 10];
            requestedSubGraphIds = [1, 1, 1, 1, 1, 1];
            expectedSubGraphIds  = [1, 2, 1, 1, 2, 2];
            aGraph.assignNodeToSubGraph(nodeIds, requestedSubGraphIds);
            actualSubGraphIds = aGraph.subGraphOfNode(nodeIds);
            
            testCase.verifyEqual(actualSubGraphIds, expectedSubGraphIds);
        end
        
        function checkChildrenOfNodeReadyForAssignment(testCase)
            % Check that the children of nodes that are ready for
            % assignment are those expected
            aGraph = iGetASimpleMatrix();
            
            aGraph.setSortingCriterion("descend outdegree");
            
            % First iteration
            firstParentNodeIds = [1, 4];
            firstRequestedSubGraphIds = ones(size(firstParentNodeIds));
            aGraph.assignNodeToSubGraph(firstParentNodeIds, firstRequestedSubGraphIds);
            firstExpectedNodeIds = [3, 5, 2];
            firstActualNodeIds = aGraph.childrenOfNodeReadyForAssignment(firstParentNodeIds);
            testCase.verifyEqual(firstActualNodeIds, firstExpectedNodeIds);
            
            % Second iteration
            secondParentNodeIds = [3, 5];
            secondRequestedSubGraphIds = ones(size(secondParentNodeIds));
            aGraph.assignNodeToSubGraph(secondParentNodeIds, secondRequestedSubGraphIds);
            secondExpectedNodeIds = 6;
            secondActualNodeIds = aGraph.childrenOfNodeReadyForAssignment(secondParentNodeIds);
            testCase.verifyEqual(secondActualNodeIds, secondExpectedNodeIds);
        end
        
        function checkCheckFullAssignment(testCase)
            % Check that if all nodes were assigned, the check returns true
            aGraph = iGetASimpleMatrix();
            
            aGraph.setSortingCriterion("descend outdegree");
            
            nodeIds = 1:10;
            requestedSubGraphIds = [ones(1, 8), 4, 4];
            aGraph.assignNodeToSubGraph(nodeIds, requestedSubGraphIds);
            
            checkResult = aGraph.checkFullAssignment();
            
            testCase.verifyTrue(checkResult);
        end
        
        function checkCheckFullAssignmentFalse(testCase)
            % Check that if not all nodes were assigned, the check returns
            % false
            aGraph = iGetASimpleMatrix();
            
            aGraph.setSortingCriterion("descend outdegree");
            
            nodeIds = 1:8;
            requestedSubGraphIds = ones(size(nodeIds));
            aGraph.assignNodeToSubGraph(nodeIds, requestedSubGraphIds);
            
            checkResult = aGraph.checkFullAssignment();
            
            testCase.verifyFalse(checkResult);
        end
        
        function checkResetAllAssignments(testCase)
            % Check that if all nodes were assigned, the check returns true
            aGraph = iGetASimpleMatrix();
            
            aGraph.setSortingCriterion("descend outdegree");
            
            nodeIds = 1:10;
            requestedSubGraphIds = [ones(1, 8), 4, 4];
            aGraph.assignNodeToSubGraph(nodeIds, requestedSubGraphIds);
            
            % Check that all nodes were assigned at this stage
            testCase.assertTrue(aGraph.checkFullAssignment());
            
            aGraph.resetAllAssignments();
            
            % Check that all the nodes are assigned to no sub-graphs at
            % this stage
            isCleared = a2msla.common.isNullId(aGraph.subGraphOfNode(1:10));
            
            import matlab.unittest.constraints.EveryElementOf;
            import matlab.unittest.constraints.IsTrue;
            testCase.assumeThat(EveryElementOf(isCleared), IsTrue());
        end
        
    end
end



function [aGraph, I, J, V] = iGetASimpleMatrix()
J = [1, 1, 1, 2, 3, 4, 4, 5, 5,  3,  6,  6,  7,  8,  6,  9,  9, 10];
I = [1, 2, 3, 2, 3, 4, 5, 5, 6,  6,  6,  7,  7,  8,  8, 10,  9, 10];
numberOfElements = numel(J);
V = ones(1, numberOfElements);
aGraph = a2msla.tassl.GraphWrapper(I, J, V, 3);
end