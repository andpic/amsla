function [subGraphLevelTable] = findSubGraphLevels(aGraph)
%AMSLA.COMMON.FINDSUBGRAPHLEVELS Given a graph partitioned into sub-graphs,
%divides the sub-graphs into sub-graph levels.
%
%   SGLT = AMSLA.COMMON.FINDSUBGRAPHLEVELS(G) Organises the sub-graphs in
%   graph G into sub-graph levels, and returns a table.

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

validateattributes(aGraph, {'amsla.common.DataStructure'}, {'nonempty', 'scalar'});

% Extract data about sub-graphs
subGraphLevelTable = iExtractDataBySubGraph(aGraph);

% Find the sub-graphs in the first sub-graph level
isInFirstLevel = arrayfun(@iIsInFirstLevel, subGraphLevelTable.SubGraphId, ...
    'UniformOutput', true);
subGraphLevelTable.SubGraphLevel(isInFirstLevel) = 1;

    function tf = iIsInFirstLevel(subGraphId)
        % Returns true if the sub-graphID is in the first level
        
        tf = ~any(cellfun( ...
            @(x) ismember(subGraphId, x), subGraphLevelTable.ToSubGraphId, ...
            'UniformOutput', true));
    end

% Initialise the algorithm with the sub-graphs that are below the ones in
% the first level.
currentSubGraphs = unique(iMergeSets( ...
    subGraphLevelTable.ToSubGraphId(isInFirstLevel)));
currentSubGraphLevel = 2;

% Loop until there are not sub-graphs to assign to sub-graph levels.
while ~isempty(currentSubGraphs)
    selRows = ismember(subGraphLevelTable.SubGraphId, currentSubGraphs);
    
    % Exclude sub-graphs that are already assigned to a higher sub-graph
    % level.
    currentAssignment = subGraphLevelTable.SubGraphLevel(selRows);
    currentSubGraphsToExclude = currentAssignment>=currentSubGraphLevel;
    currentSubGraphs(currentSubGraphsToExclude) = [];
    
    selRows = ismember(subGraphLevelTable.SubGraphId, currentSubGraphs);
    
    % Assign remaining sub-graphs to the current level
    subGraphLevelTable.SubGraphLevel(selRows) = currentSubGraphLevel;
    
    % Find sub-graphs downstream
    currentSubGraphs = unique(iMergeSets( ...
        subGraphLevelTable.ToSubGraphId(selRows)));
    currentSubGraphLevel = currentSubGraphLevel+1;
end

assert(~any(amsla.common.isNullId(subGraphLevelTable.SubGraphLevel)), ...
    "Identification of sub-graph levels failed.");
end

%% HELPER FUNCTION

function subGraphLevelTable = iExtractDataBySubGraph(aGraph)
% Create a table that organises the data about external edges by sub-graph.
% The output table has the following columns:
% - SubGraphId      ID of the sub-graph.
% - SubGraphLevel   ID of the sub-graph level of the current sub-graph.
% - ToSubGraphId    IDs of the sub-graphs to which the current sub-graph is
%                   connected by a downstream external edge.

% Sub-graphs of input nodes
fromNodes = aGraph.listOfNodes();
fromSubGraph = aGraph.subGraphOfNode(fromNodes);

% Sub-graphs of output nodes
toNodes = aGraph.childrenOfNode(fromNodes);
if ~isscalar(toNodes)
    toSubGraph = cellfun(@iFindDownstreamSubGraphs, toNodes, 'UniformOutput', false);
else
    toSubGraph = iFindDownstreamSubGraphs(toNodes);
end

% Create a table with non-unique rows
tempTable = table(fromSubGraph', toSubGraph', ...
    'VariableNames', {'FromSubGraphId', 'ToSubGraphId'});
allSubGraphs = aGraph.listOfSubGraphs();

% Merge non-unique rows
allMergedSets = ...
    arrayfun(@iFindAndMergeSets, allSubGraphs, 'UniformOutput', false);

% Create output table
subGraphLevel = amsla.common.nullId(size(allSubGraphs));
subGraphLevelTable = table(allSubGraphs', subGraphLevel', allMergedSets', ...
    'VariableNames', {'SubGraphId', 'SubGraphLevel', 'ToSubGraphId'});
subGraphLevelTable = sortrows(subGraphLevelTable, 1);

    function downstreamGraph = iFindDownstreamSubGraphs(subGraphIds)
        % Find the downstream sub-graph IDs for a given sub-graph ID
        
        if isempty(subGraphIds)
            downstreamGraph = [];
        else
            downstreamGraph = aGraph.subGraphOfNode(subGraphIds);
        end
    end

    function mergedSet = iFindAndMergeSets(subGraphId)
        % Merge all rows in tempTable that refer to subGraphId, and remove
        % data about internal edges in the graph.
        
        selRows = tempTable.FromSubGraphId==subGraphId;
        setsToMerge = tempTable.ToSubGraphId(selRows);
        mergedSet = unique(iMergeSets(setsToMerge));
        
        % Remove data about internal edges in the graph.
        mergedSet(mergedSet==subGraphId) = [];
    end
end

function mergedSet = iMergeSets(allSets)
mergedSet = [allSets{:}];
end