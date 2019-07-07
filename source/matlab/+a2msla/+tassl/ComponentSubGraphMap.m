classdef ComponentSubGraphMap < handle
    %COMPONENTSUBGRAPHMAP Maps components to sub-graphs and vice-versa.
    %
    %   M = COMPONENTSUBGRAPHMAP(CID, CSZ, MSZ) Create a map of graph
    %   components to sub-graphs given the IDs (CID), the sizes (CSZ) of
    %   the components, and the maximum size of a sub-graph (MSZ).
    %
    %   ComponentSubGraphMap methods:
    %       listOfMergedComponents      - Returns the list of merged
    %                                     components.
    %       componentToMergedComponent  - Return the merged component IDs
    %                                     corresponding to one or more of
    %                                     components.
    %       mergedComponentToComponent  - Return the component IDs
    %                                     corresponding to one or more of
    %                                     merged components.
    %
    %       listOfSubGraphs             - Returns the list of sub-graphs.
    %       subGraphsOfMergedComponent  - Returns the sub-graphs in the
    %                                     given merged component.
    %       sizeOfSubGraph              - Returns the size of sub-graphs.
    %       addElementToSubGraph        - Record that an element was added to a
    %                                     sub-graph.
    %       resetSubGraphs              - Record that all elements were
    %                                     removed from all sub-graphs.

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

    %% PROPERTIES

    properties (Access=private)

        %Table object used to represent data.
        %
        % SubGraphTable has the following columns:
        %   Id                  - ID of the sub-graph.
        %   MergedComponentId   - ID of the merged component to which the
        %                         sub-graph belongs.
        %   Size                - Size of the sub-graph.
        SubGraphTable

        %Table that shows the correspondence between merged components and
        %original graph components.
        %
        % ComponentToMergedComponents has the following columns:
        %   ComponentId         - ID of the original component
        %   ComponentSize       - Size of the original component
        %   MergedComponentId   - ID of the merged component
        ComponentToMergedComponents;

    end

    properties (GetAccess=private, SetAccess=immutable)

        %Maximum size a sub-graph is allowed to be.
        MaxSubGraphSize;

    end

    %% PUBLIC METHODS

    methods (Access=public)

        %% General

        function obj = ComponentSubGraphMap(componentIds, componentSizes, maxSize)
            %TASSLSUBGRAPHMAP Constructs a map of components to sub-graphs
            %and vice-versa.

            obj.MaxSubGraphSize = maxSize;

            % Merge small components
            obj.ComponentToMergedComponents = iMergeSmallComponents(componentIds, componentSizes, maxSize);
            uniqueMergedComponentIds = unique(obj.ComponentToMergedComponents.MergedComponentId);
            mergedComponentSizes = iSumSameId( ...
                obj.ComponentToMergedComponents.ComponentSize, ...
                obj.ComponentToMergedComponents.MergedComponentId, ...
                uniqueMergedComponentIds);

            % Determine how many sub-graphs the map is composed of
            obj.SubGraphTable = ...
                iCreateSubGraphTable(uniqueMergedComponentIds, mergedComponentSizes, maxSize);
        end

        %% Components

        function outIds = listOfMergedComponents(obj)
            %LISTOFMERGEDCOMPONENTS(M) Returns the list of the IDs of merged
            %components in the map.
            outIds = reshape(unique(obj.SubGraphTable.MergedComponentId), 1, []);
        end

        function outIds = componentToMergedComponent(obj, componentIds)
            %COMPONENTTOMERGEDCOMPONENT(M, C) Given one or more component IDs,
            %returns the IDs of the corresponding merged components

            % Find unique inputs
            [sortedInputIds, ~, invSorter] = unique(componentIds);
            % Retrieve corresponding values in the table
            outIds =  obj.ComponentToMergedComponents.MergedComponentId'*...
                (obj.ComponentToMergedComponents.ComponentId==sortedInputIds);
            % Return un-sorted outputs
            outIds = outIds(invSorter);
        end

        function outIds = mergedComponentToComponent(obj, componentIds)
            %MERGEDCOMPONENTTOCOMPONENT(M, C) Given one or more merged component IDs,
            %returns the IDs of the corresponding components

            % Find unique inputs
            [sortedInputIds, ~, invSorter] = unique(componentIds);
            % Retrieve corresponding values in the table
            if isscalar(sortedInputIds)
                outIds = iFindComponentsOfOneMergedComponent(sortedInputIds);
            else
                outIds = arrayfun(@iFindComponentsOfOneMergedComponent, sortedInputIds, 'UniformOutput', false);
            end

            % Return un-sorted outputs
            outIds = outIds(invSorter);

            % Helper function
            function outIds = iFindComponentsOfOneMergedComponent(mergedComponentId)
                outIds = obj.ComponentToMergedComponents.ComponentId(obj.ComponentToMergedComponents.MergedComponentId==mergedComponentId)';
            end
        end

        function outIds = subGraphsOfMergedComponent(obj, componentIds)
            %SUBGRAPHSOFMERGEDCOMPONENT(M, C) Given one or more merged
            %component IDs, returns the IDs of the correspondinb sub-graphs.

            if isscalar(componentIds)
                outIds = iGetSubGraphsOfOneMergedComponent(componentIds);
            else
                outIds = arrayfun(@iGetSubGraphsOfOneMergedComponent, componentIds, 'UniformOutput', false);
            end

            % Helper function
            function subGraphIds = iGetSubGraphsOfOneMergedComponent(componentId)
                subGraphIds = obj.SubGraphTable.Id(obj.SubGraphTable.MergedComponentId==componentId)';
            end
        end

        %% Sub-graphs

        function outIds = listOfSubGraphs(obj)
            %LISTOFSUBGRAPHS(M) Returns the list of the IDs of sub-graphs
            %in the map.
            outIds = reshape(unique(obj.SubGraphTable.Id), 1, []);
        end

        function outSize = sizeOfSubGraph(obj, subGraphId)
            %SIZEOFSUBGRAPH(M, S) Returns the size of one or more sub-graphs
            %in the map.
            outSize = obj.SubGraphTable.Size'*(obj.SubGraphTable.Id==subGraphId);
        end

        function actualSubGraphIds = addElementToSubGraph(obj, subGraphIds)
            %ADDELEMENTTOSUBGRAPH(M, S) Record the fact that one or more
            %elements were added to one or more sub-graphs.

            % Sort sub-graph IDs
            [subGraphIds, sorter] = sort(subGraphIds);
            unSorter = iInvertSorting(sorter);
            actualSubGraphIds = a2msla.common.nullId(size(subGraphIds));
            actualK = 1;

            % Find unique sub-graph IDs
            [uniqueSubGraphIds, uniqueSorter] = unique(subGraphIds);
            numRepeats = sum(subGraphIds==subGraphIds');
            numRepeats = numRepeats(uniqueSorter);

            for k=1:length(uniqueSubGraphIds)
                % Fill the requested sub-graph
                currSubGraphId = uniqueSubGraphIds(k);
                numRepeatsLeft = numRepeats(k);

                % Use all remaining elements to add in other sub-graphs
                while numRepeatsLeft>0
                    currSubGraphId = obj.nextNonFullSubGraph(currSubGraphId);
                    [numRepeatsToFill, numRepeatsLeft] = iFillSubGraph(currSubGraphId, numRepeatsLeft);
                    actualSubGraphIds(actualK:actualK+numRepeatsToFill-1) = currSubGraphId;
                    actualK = actualK+numRepeatsToFill;
                end
            end

            % Return output in the same order as the input
            actualSubGraphIds = actualSubGraphIds(unSorter);

            % Helper function
            function [numToFill, numLeft] = iFillSubGraph(subGraphId, numTotal)
                subGraphSel = obj.SubGraphTable.Id==subGraphId;
                subGraphSize = obj.SubGraphTable.Size(subGraphSel);

                % Add whatever's left to fill the sub-graph
                numToFill = min(numTotal, obj.MaxSubGraphSize-subGraphSize);
                numLeft = max(numTotal-(obj.MaxSubGraphSize-subGraphSize),0);

                % Fill the current sub-graph if possible
                obj.SubGraphTable.Size(subGraphSel) = subGraphSize+numToFill;
            end
        end

        function resetSubGraphs(obj)
            %RESETSUBGRAPHS(M) Record the fact that all elements were removed
            %from all sub-graphs.
            obj.SubGraphTable.Size = zeros(size(obj.SubGraphTable.Size));
        end

    end

    %% PRIVATE METHODS

    methods (Access=private)

        function outIds = nextNonFullSubGraph(obj, subGraphId)
            % Given one sub-graph IDs, returns the ID of the first
            % non-full sub-graph in the same merged component.
            %
            %	Example:
            %       % Create a simple map with a single component and a
            %       % maximum sub-graph size of 10.
            %       componentIds = 1;
            %       componentSzs = 30;
            %       maxSz = 10;
            %       compMap = ComponentSubGraphMap(componentIds, componentSzs, maxSz);
            %       % The map has 3 sub-graphs
            %       subGList = listOfSubGraphs()
            %       % At this stage, all sub-graphs are empty
            %       nextSubG = nextNonFullSubGraph(compMap, 2)
            %       % Fill the second sub-graph
            %       addElementToSubGraph(compMap, 2*ones(maxSz, 1));
            %       % The next non-full sub-graph is 3
            %       nextSubG = nextNonFullSubGraph(compMap, 2)

            % Input must be scalar
            assert(isscalar(subGraphId), "Can't check for more than one non-full sub-graph ID at the time.");

            candidateIds = obj.SubGraphTable.Id( ...
                ... % Candidate IDs must be in the same merged component
                obj.SubGraphTable.MergedComponentId==obj.SubGraphTable.MergedComponentId(obj.SubGraphTable.Id==subGraphId) & ...
                ... % Candidate IDs must not be full
                obj.SubGraphTable.Size<obj.MaxSubGraphSize & ...
                ... % Candidate IDs must have a higher ID than that of the input
                obj.SubGraphTable.Id>=subGraphId);

            % Check that this is still a good sub-graph
            assert(~isempty(candidateIds), "a2msla:badSubGraph", ...
                "All the sub-graphs in merged component are full.");

            % Return the smallest ID
            outIds = min(candidateIds);
        end
    end
end

%% HELPER FUNCTIONS

function componentTable = iMergeSmallComponents(componentIds, componentSizes, maxSize)
% Merges components that are smaller than maxSize into new components

% Create a table with component IDs, their size, and the merged component ids
componentTable = iCreateMergedComponentTable(componentIds, componentSizes);

% Select the small components
smallComponentTable = componentTable(componentTable.ComponentSize<maxSize, :);
smallComponentTable = sortrows(smallComponentTable, [-2, 1]);

% Loop through all components
for k = 1:height(smallComponentTable)
    % Skip is component has already been assigned
    if ~a2msla.common.isNullId(smallComponentTable.MergedComponentId(k))
        continue;
    end

    currMergedComponent = smallComponentTable.ComponentId(k);
    smallComponentTable.MergedComponentId(k) = currMergedComponent;
    currMergedComponentSize = smallComponentTable.ComponentSize(k);

    for j = height(smallComponentTable):-1:(k+1)
        % Check if the component can be merged
        if  a2msla.common.isNullId(smallComponentTable.MergedComponentId(j)) && ...
                currMergedComponentSize(k)+smallComponentTable.ComponentSize(j) <= maxSize
            smallComponentTable.MergedComponentId(j) = currMergedComponent;
            currMergedComponentSize = currMergedComponentSize(k)+smallComponentTable.ComponentSize(j);
        end
    end
end

% Merge with large component table
largeComponentTable = componentTable(componentTable.ComponentSize>=maxSize, :);
largeComponentTable.MergedComponentId = largeComponentTable.ComponentId;
componentTable = sortrows([largeComponentTable; smallComponentTable], [3 1]);

% Check output
assert(~any(a2msla.common.isNullId(componentTable.MergedComponentId)), ...
    "One or more components were not merged");
end

function subGraphTable = iCreateSubGraphTable(componentIds, componentSizes, subGraphSize)
% Creates a table that maps sub-graphs to (merged) components given the
% maximum sub-graph size

howManySplit = ceil(componentSizes./subGraphSize);
subGraphIds = (1:sum(howManySplit))';
subGraphComponentIds = zeros(size(subGraphIds));

% Match every sub-graph to its component
lastEnd = 0;
for k = 1:numel(componentIds)
    subGraphComponentIds(lastEnd+1:lastEnd+howManySplit(k)) = componentIds(k);
    lastEnd = lastEnd+howManySplit(k);
end
subGraphSizes = zeros(size(subGraphIds));

% Create table
subGraphTable = table(subGraphIds, subGraphComponentIds, subGraphSizes);
subGraphTable.Properties.VariableNames = ["Id", "MergedComponentId", "Size"];
end

function componentTable = iCreateMergedComponentTable(componentIds, componentSizes)
% Creates a table that maps components to merged components

numComponents = length(componentIds);
componentIds = reshape(componentIds, [numComponents, 1]);
componentSizes = reshape(componentSizes, [numComponents, 1]);
mergedComponentIds = a2msla.common.nullId([numComponents, 1]);
componentTable = table(componentIds, componentSizes, mergedComponentIds);
componentTable.Properties.VariableNames = ["ComponentId", "ComponentSize", "MergedComponentId"];
end

function unSorter = iInvertSorting(sorter)
% Inverts a sorting permutation
unSorter(sorter) = 1:length(sorter);
end

function sumById = iSumSameId(arrayToSum, arrayId, uniqueId)
% Sum the elements in arrayToSum if their ID is the same

arrayToSum = reshape(arrayToSum, 1, []);
arrayId = reshape(arrayId, 1, []);
uniqueId = reshape(uniqueId, 1, []);
sumById = arrayToSum*(arrayId'==uniqueId);
end
