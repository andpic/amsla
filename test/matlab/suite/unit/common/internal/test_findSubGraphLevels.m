classdef test_findSubGraphLevels < amsla.test.tools.AmslaTest
    %TEST_FINDSUBGRAPHLEVEL Tests for amsla.common.internal.findSubGraphLevels
    
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
    
    %% Output matches expected in simple graphs
    
    properties(TestParameter)
        PartitionedGraph = struct( ...
            'UsualSubGraphs', struct( ...
            'InputGraph',       { iSimpleLowerTriangular_UsualSubGraphs() }, ...
            'ExpectedOutput',   { iSimpleLowerTriangular_UsualSubGraphs_Expected() }), ...
            ...
            'LevelSet', struct( ...
            'InputGraph',       { iSimpleLowerTriangular_LevelSet() }, ...
            'ExpectedOutput',   { iSimpleLowerTriangular_LevelSet_Expected() }), ...
            ...
            'NonSequentialSubGraphIds', struct( ...
            'InputGraph',       { iSimpleLowerTriangular_NonSequentialSubGraphIds() }, ...
            'ExpectedOutput',   { iSimpleLowerTriangular_NonSequentialSubGraphIds_Expected() }), ...
            ...
            'FlowerLevelSet', struct( ...
            'InputGraph',       { iFlower_LevelSet() }, ...
            'ExpectedOutput',   { iFlower_LevelSet_Expected() }), ...
            ...
            'ChainLevelSet', struct( ...
            'InputGraph',       { iChain_LevelSet() }, ...
            'ExpectedOutput',   { iChain_LevelSet_Expected() }), ...
            ...
            'SingleNode', struct( ...
            'InputGraph',       { iSingleNode() }, ...
            'ExpectedOutput',   { iSingleNode_Expected() }));
    end
    
    methods(Test)
        function outputMatchesExpectedInSimplGraphs(testCase, PartitionedGraph)
            % Check that the output of the function matches the expected output
            % in simple sub-graphs that can be also partitioned by hand.
            
            actualOutput = amsla.common.internal.findSubGraphLevels(PartitionedGraph.InputGraph);
            expectedOutput = PartitionedGraph.ExpectedOutput;
            
            testCase.verifyTableProperties(actualOutput);
            testCase.verifyEqual(actualOutput, expectedOutput);
        end
    end
    
    %% Finding sub-graph levels in non-partitioned graph gives an error
    
    methods(Test)
        function nonPartitionedGraphThrowsError(testCase)
            % Check that calling the function on a non-partitione graph throws
            % an error.
            
            aGraph = amsla.test.tools.getSimpleLowerTriangularMatrix();
            testCase.verifyError(@() amsla.common.internal.findSubGraphLevels(aGraph), ...
                "amsla:findSubGraphLevels:NotPartitioned", ...
                "The function is expected to throw an error if the input graph is not partitioned.");
        end
    end
    
    %% Tool gives an error if sub-graphs have loops
    
    methods(Test)
        function nonDagPartitioningThrowsError(testCase)
            % Throw an error if the dependencies between sub-graphs are not
            % themselves a DAG.
            
            % Create a data structure with non-circular dependencies
            J = [1, 1, 2, 2];
            I = [1, 2, 2, 1];
            V = ones(size(J));
            aGraph = amsla.common.DataStructure(I, J, V);
            aGraph.setSubGraphOfNode( ...
                [1, 2], ...
                [1, 2]);
            
            testCase.verifyError(@() amsla.common.internal.findSubGraphLevels(aGraph), ...
                "amsla:findSubGraphLevels:NonDagDependencies", ...
                "The function is expected to throw an error if the input graph is not partitioned.");
        end
    end
    
    %% HELPER METHODS
    
    methods(Access=private)
        function verifyTableProperties(testCase, outputTable)
            % Verify that the output of findSubGraphLevels is a table and
            % that its format is correct.
            
            testCase.assertClass(outputTable, 'table');
            
            actualNames = string(outputTable.Properties.VariableNames);
            expectedNames = ["SubGraphId", "SubGraphLevel", "ToSubGraphId"];
            testCase.verifyEqual(actualNames, expectedNames, ...
                "The function output does not have the expected format.");
        end
    end
end

%% HELPER FUNCTIONS

function aGraph = iSimpleLowerTriangular_UsualSubGraphs()
aGraph = amsla.test.tools.getSimpleLowerTriangularMatrix();
aGraph.setSubGraphOfNode( ...
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], ...
    [1, 1, 1, 2, 2, 3, 3, 3, 4,  4,  4]);
end

function expectedTable = iSimpleLowerTriangular_UsualSubGraphs_Expected()
subGraphId      =  [1, 2, 3, 4];
toSubGraphId    =  {3, 3, iEmpty(), iEmpty()};
subGraphLevel   =  [1, 1, 2, 1];
expectedTable = iOutputTable(subGraphId, toSubGraphId, subGraphLevel);
end


function aGraph = iSimpleLowerTriangular_LevelSet()
aGraph = amsla.test.tools.getSimpleLowerTriangularMatrix();
aGraph.setSubGraphOfNode( ...
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], ...
    [1, 2, 2, 1, 2, 3, 4, 4, 1,  2,  3]);
end

function expectedTable = iSimpleLowerTriangular_LevelSet_Expected()
subGraphId      =  [1, 2, 3, 4];
toSubGraphId    =  {2, 3, 4, iEmpty(0, 1)};
subGraphLevel   =  [1, 2, 3, 4];
expectedTable = iOutputTable(subGraphId, toSubGraphId, subGraphLevel);
end

function aGraph = iSimpleLowerTriangular_NonSequentialSubGraphIds()
aGraph = amsla.test.tools.getSimpleLowerTriangularMatrix();
aGraph.setSubGraphOfNode( ...
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], ...
    [1, 1, 1, 3, 3, 2, 2, 2, 4,  4,  4]);
end

function expectedTable = iSimpleLowerTriangular_NonSequentialSubGraphIds_Expected()
subGraphId      =  [1, 2, 3, 4];
toSubGraphId    =  {2, iEmpty(), 2, iEmpty()};
subGraphLevel   =  [1, 2, 1, 1];
expectedTable = iOutputTable(subGraphId, toSubGraphId, subGraphLevel);
end

function aGraph = iFlower_LevelSet()
J = [1, 2, 3, 4, 5];
I = 6*ones([1, numel(J)]);
V = ones([1, numel(J)]);
aGraph = amsla.common.DataStructure(I, J, V);
aGraph.setSubGraphOfNode( ...
    [1, 2, 3, 4, 5, 6], ...
    [1, 1, 1, 1, 1, 2]);
end

function expectedTable = iFlower_LevelSet_Expected()
subGraphId      =  [1, 2];
toSubGraphId    =  {2, iEmpty(0, 1)};
subGraphLevel   =  [1, 2];
expectedTable = iOutputTable(subGraphId, toSubGraphId, subGraphLevel);
end

function aGraph = iChain_LevelSet()
numNodes = 6;
J = 1:(numNodes-1);
I = [J(2:end), numNodes];
V = ones([1, numel(J)]);
aGraph = amsla.common.DataStructure(I, J, V);
aGraph.setSubGraphOfNode( ...
    1:numNodes, ...
    1:numNodes);
end

function expectedTable = iChain_LevelSet_Expected()
numNodes = 6;
subGraphId      =  1:numNodes;
toSubGraphId    =  [num2cell(2:numNodes), {iEmpty(0, 1)}];
subGraphLevel   =  1:numNodes;
expectedTable = iOutputTable(subGraphId, toSubGraphId, subGraphLevel);
end

function aGraph = iSingleNode()
J = 1;
I = 1;
V = 1;
aGraph = amsla.common.DataStructure(I, J, V);
aGraph.setSubGraphOfNode( ...
    1, ...
    1);
end

function expectedTable = iSingleNode_Expected()
subGraphId      =  1;
toSubGraphId    =  {iEmpty(0, 1)};
subGraphLevel   =  1;
expectedTable = iOutputTable(subGraphId, toSubGraphId, subGraphLevel);
end

function tableWithFormat = iOutputTable(subGraphId, toSubGraphId, subGraphLevel)
% Create a table with the format expected for the output of the function
% findSubGraphLevels.

subGraphId = reshape(subGraphId, numel(subGraphId), []);
toSubGraphId = reshape(toSubGraphId, numel(toSubGraphId), []);
subGraphLevel = reshape(subGraphLevel, numel(subGraphLevel), []);
tableWithFormat = table(subGraphId, subGraphLevel, toSubGraphId, ...
    'VariableNames', {'SubGraphId', 'SubGraphLevel', 'ToSubGraphId'});
end

function val = iEmpty(varargin)
if nargin == 0
    zeroArgs = {1, 0};
else
    zeroArgs = varargin;
end
val = zeros(zeroArgs{:});
end