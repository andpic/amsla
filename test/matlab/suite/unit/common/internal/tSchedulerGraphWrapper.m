classdef tSchedulerGraphWrapper < amsla.test.tools.AmslaTest
    %TSCHEDULERGRAPHWRAPPER Tests for
    %amsla.common.internal.SchedulerGraphWrapper.
    
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
    
    %% The roots by sub-graph or in the whole graph are identified correctly
    
    properties(TestParameter)
        GraphRootsPair = struct( ...
            'SimpleLowerTriangularNoSubGraphs', struct( ...
            'InputGraph',   	{ iSimpleLowerTriangularNoSubGraphs() }, ...
            'AllRoots',      	{ iSimpleLowerTriangularAllRoots() }, ...
            'RootsBySubGraph',	{ {} }), ...
            ...
            'SimpleLowerTriangularWithSubGraphs', struct( ...
            'InputGraph',   	{ iSimpleLowerTriangularGraphWithSubGraphs() }, ...
            'AllRoots',      	{ iSimpleLowerTriangularAllRoots() }, ...
            'RootsBySubGraph',	{ iSimpleLowerTriangularRootsBySubGraph() }) ...
            );
    end
    
    methods(Test)
        function rootsInTheWholeGraphAreIdentifiedCorrectly(testCase, GraphRootsPair)
            % Check that the method "getRootsOfGraph" identifies the roots
            % in a graph correctly, independently of the sub-graphs having
            % been defined or not.
            
            currGraph = GraphRootsPair.InputGraph;
            expectedRoots = GraphRootsPair.AllRoots;
            
            testCase.verifyRootsIdentifiedCorrectly(currGraph, expectedRoots, ...
                'graph');
        end
        
        function rootsBySubGraphAreIdentifiedCorrectly(testCase, GraphRootsPair)
            % Check that the method "getRootsBySubGraph" identifies the roots
            % in a graph correctly, independently of the sub-graphs having
            % been defined or not.
            
            currGraph = GraphRootsPair.InputGraph;
            expectedRoots = GraphRootsPair.RootsBySubGraph;
            
            testCase.verifyRootsIdentifiedCorrectly(currGraph, expectedRoots, ...
                'sub-graph');
        end
    end
    
    methods(Access=private)
        function verifyRootsIdentifiedCorrectly(testCase, currGraph, expectedRoots, rootType)
            % Verify that the roots in the graph (either in the whole graph
            % of by sub-graph) are identified correctly by the
            % corresponding methods of SchedulerGraphWrapper.
            
            wrapperToTest = amsla.common.internal.SchedulerGraphWrapper(currGraph);
            
            if strcmp(rootType, "graph")
                methodCall = @() wrapperToTest.getRootsOfGraph();
            elseif strcmp(rootType, "sub-graph")
                methodCall = @() wrapperToTest.getRootsBySubGraph();
            else
                error("amsla:test:badRootType", ...
                    "Invalid type of root node.");
            end
            
            actualRoots = testCase.verifyWarningFree(methodCall, ...
                "An error or warning was thrown while identifying the roots by " + ...
                rootType);
            testCase.verifyEqual(actualRoots, expectedRoots, ...
                "The expected and actual roots do not match");
        end
    end
    
    %% edgeIds = getEnteringEdges(obj, nodeIds)
    %% assignEdgesToTimeSlot(obj, edgeIds, timeSlotIds)
    %% nodeIds = getReadyChildrenOfNode(obj, parentNodeIds)
    %% nodeIds = getChildrenOfOnlyNodesInSet(obj, parentNodeIds)
end

%% HELPER FUNCTIONS

function aGraph = iSimpleLowerTriangularNoSubGraphs()
aGraph = amsla.test.tools.getSimpleLowerTriangularMatrix();
end

function aGraph = iSimpleLowerTriangularGraphWithSubGraphs()
aGraph = amsla.test.tools.getSimpleLowerTriangularMatrix();
aGraph.setSubGraphOfNode( ...
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], ...
    [1, 1, 1, 2, 2, 3, 3, 3, 4, 4]);
end

function roots = iSimpleLowerTriangularAllRoots()
roots = [1, 4, 9];
end

function roots = iSimpleLowerTriangularRootsBySubGraph()
roots = {1, 4, 6, 9};
end