classdef PartitionerGraphWrapper < ...
        amsla.common.internal.PartitionerGraphWrapperInterface
    %AMSLA.TASSL.INTERNAL.PARTITIONERGRAPHWRAPPER Wrapper to a graph to be
    %used for the analysis phase with the TASSL approach.
    %
    %   W = AMSLA.TASSL.INTERNAL.PARTITIONERGRAPHWRAPPER(G, MAXSIZE) Create a
    %   wrapper to a graph described by the EnhancedGraph object G, to be
    %   used to partition the graph into sub-graphs with maximum size
    %   MAXSIZE.
    %
    %   PartitionerGraphWrapper methods:
    %       setSortingCriterion                 - Set the criterion to
    %                                             sort the nodes in the
    %                                             graph.
    %       distributeRootsToSubGraphs          - Distribute the root nodes
    %                                             in the graph to sub-graph.
    %       assignNodeToSubGraph                - Assign one or more nodes
    %                                             to sub-graphs.
    %       subGraphOfNode                      - Get the sub-graph to which a
    %                                             node belongs.
    %       childrenOfNodeReadyForAssignment    - Get the nodes that are
    %                                             ready for being assigned.
    %       checkFullAssignment                 - Check that all nodes were
    %                                             assigned to sub-graphs.
    %       resetAllAssignments                 - Reset the status of the
    %                                             graph to its initial one.
    %
    %       plot                                - Plot the graph.
    
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
    
    properties(Access=private)
        
        %A ComponentSubGraphMap object that maps components to sub-graphs
        %in a TASSL-specific way.
        Map
        
        %A criterion to sort the nodes in the graph.
        NodeSortingCriterion
        
        %True if the components in the graph were correctly identified and
        %initialised.
        IsMapInitialised
    end
    
    properties(GetAccess=private,SetAccess=immutable)
        
        %Maximum number of nodes in a sub-graph.
        MaxSize
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = PartitionerGraphWrapper(aGraph, maxSize)
            %PARTITIONERGRAPHWRAPPER(G, MAXSIZE) Constructs a graph wrapper
            %to be used for the analysis phase with the TASSL approach.
            
            % Initialise the graph
            obj = obj@amsla.common.internal.PartitionerGraphWrapperInterface(aGraph);
            obj.Map = [];
            obj.NodeSortingCriterion = [];
            obj.IsMapInitialised = false;
            obj.MaxSize = maxSize;
        end
        
        
        function setSortingCriterion(obj, sortingCriterion)
            %SETSORTINGCRITERION(G, K) Set the sorting criterion K for the
            %nodes in the graph.
            
            sortingCriterion = string(sortingCriterion);
            
            if strcmp(sortingCriterion, "descend outdegree")
                sortingFunction = @(j) obj.Graph.sortNodesByOutdegree(j);
            elseif strcmp(sortingCriterion, "ascend outdegree")
                sortingFunction = @(j) iInvertArray(obj.Graph.sortNodesByOutdegree(j));
            elseif strcmp(sortingCriterion, "descend indegree")
                sortingFunction = @(j) obj.Graph.sortNodesByIndegree(j);
            elseif strcmp(sortingCriterion, "ascend indegree")
                sortingFunction = @(j) iInvertArray(obj.Graph.sortNodesByIndegree(j));
            elseif strcmp(sortingCriterion, "descend index")
                sortingFunction = @(j) sort(j, "descend");
            elseif strcmp(sortingCriterion, "ascend index")
                sortingFunction = @(j) sort(j, "ascend");
            else
                error("Invalid sorting criterion for the nodes in the graph.");
            end
            % Assign sorting criterion
            obj.NodeSortingCriterion = sortingFunction;
        end
        
        function [rootIds, subgAssignments] = distributeRootsToSubGraphs(obj, density)
            %DISTRIBUTEROOTSTOSUBGRAPHS(G,D) Distribute the root nodes
            %in the graph based on a density parameter D. The higher D, the
            %more the sub-graphs being assigned given the same number of
            %root nodes.
            %
            %   [R, S] = DISTRIBUTEROOTSTOSUBGRAPHS(G,D) Distribute the
            %   roots of nodes in G to sub-graphs. Get the root node IDs
            %   and the sub-graph IDs S.
            
            % Initialise the map if it hasn't been initialised yet.
            if ~obj.IsMapInitialised
                obj.initialiseMapWithComponents();
            end
            
            % Retrieve root and sub-graph IDs
            [rootIds, mergedComponentIds] = obj.rootsOfMergedComponents();
            subGraphIds = obj.Map.subGraphsOfMergedComponent(mergedComponentIds);
            
            % Check that we can associate roots to sub-graphs
            [rootIds, subGraphIds, density] = iCheckAssociationIsPossible(rootIds, subGraphIds, density);
            
            % Distribute the roots
            subgAssignments = cellfun(@iDistributeRootsToSubGraphsForOneComponent, rootIds, subGraphIds, ...
                "UniformOutput", false);
            subgAssignments = cell2mat(subgAssignments);
            rootIds = cell2mat(rootIds);
            
            % Helper function
            function subgAssignmentsOneComp = iDistributeRootsToSubGraphsForOneComponent(roots, subgs)
                % Select a subset of sub-graphs based on density
                numUsableSubgs = ceil(numel(subgs)*density);
                subgs = sort(subgs);
                subgs = subgs(1:numUsableSubgs);
                % Sort roots by the current criterion
                roots = obj.sortNodes(roots);
                
                % Assign sub-graphs to root nodes cyclically
                numRoots = numel(roots);
                numCompleteSubgAssignments = floor(numRoots/numUsableSubgs);
                numRemeainingSubAssignments = numRoots - numCompleteSubgAssignments*numUsableSubgs;
                subgAssignmentsOneComp = ...
                    [repmat(subgs, 1, numCompleteSubgAssignments), subgs(1:numRemeainingSubAssignments)];
            end
        end
        
        function assignNodeToSubGraph(obj, nodeIds, subGraphIds)
            %ASSIGNNODETOSUBGRAPH(G, NODEIDS, SUBGIDS) Assign one or more nodes
            %with ID NODEIDS to sub-graphs with IDs SUBGIDS.
            
            [nodeIds, subGraphIds] = iGetIndexArrayForm(nodeIds, subGraphIds);
            % Sort with the given criterion
            [nodeIds, sorting] = obj.sortNodes(nodeIds);
            subGraphIds = subGraphIds(sorting);
            % Initialise the map if it hasn't been initialised yet.
            if ~obj.IsMapInitialised
                obj.initialiseMapWithComponents();
            end
            % Check actual possible assignments
            subGraphIds = obj.Map.addElementToSubGraph(subGraphIds);
            % Assign sub-graphs
            obj.Graph.setSubGraphOfNode(nodeIds, subGraphIds);
        end
        
        function outIds = subGraphOfNode(obj, nodeIds)
            %SUBGRAPHOFNODE(G, NODEIDS) Get the sub-graph IDs to which one or
            %more nodes were assigned.
            
            outIds = obj.Graph.subGraphOfNode(nodeIds);
        end
        
        function [childrenIds, subGraphIds] = childrenOfNodeReadyForAssignment(obj, nodeIds)
            %CHILDRENOFNODEREADYFORASSIGNMENT(G, NODEIDS) Get the IDs of the
            %children of one or more nodes NODEIDS, such that all the parents of
            %these children were assigned to sub-graphs.
            %
            %   C = CHILDRENOFNODEREADYFORASSIGNMENT(G, NODEIDS) Get the IDs of
            %   the children IDs that are ready for assignment.
            %
            %   [C, S] = CHILDRENOFNODEREADYFORASSIGNMENT(G, NODEIDS) Get the IDs
            %   of the chidlren that are ready for assignment and the
            %   corresponding sub-graph IDs to assign them to.
            
            childrenIds = obj.childrenOfNode(nodeIds);
            % Sort children by the current sorting
            childrenIds = obj.sortNodes(childrenIds);
            [childrenIds, subGraphIds] = obj.nodesReadyForAssignment(childrenIds);
        end
        
        function resetAllAssignments(obj)
            %RESETALLASSIGNMENTS(G) Reset all node-to-sub-graph
            %assignments.
            
            resetAllAssignments@amsla.common.internal.PartitionerGraphWrapperInterface(obj);
            % Reset map if it is already initialised.
            if obj.IsMapInitialised
                obj.Map.resetSubGraphs();
            end
        end
        
    end
    
    %% PRIVATE METHODS
    
    methods (Access=private)
        
        function initialiseMapWithComponents(obj)
            %INITIALISECOMPONENTS(G) Find the weakly connected components in the graph.
            
            % Initialise the map of components to sub-graphs
            obj.Graph.computeComponents();
            [componentIds, componentSizes] = obj.Graph.listOfComponents();
            obj.Map = amsla.tassl.internal.ComponentSubGraphMap(componentIds, componentSizes, obj.MaxSize);
            obj.IsMapInitialised = true;
        end
        
        function [outRootIds, outMergedComponentIds] = rootsOfMergedComponents(obj)
            %ROOTSOFMERGEDCOMPONENTS(G) Retrieve the roots of every merged
            %component in the graph G and the component IDs.
            %
            %   R = ROOTSOFMERGEDCOMPONENTS(G) Get the list of root node
            %   IDs for all the components.
            %
            %   [R, C] = ROOTSOFMERGEDCOMPONENTS(G) Get both the list of
            %   root node IDs and the corresponding merged component IDs.
            
            % Initialise the map if it hasn't been initialised yet.
            if ~obj.IsMapInitialised
                obj.initialiseMapWithComponents();
            end
            
            % Map is not aware of component roots and Graph is not aware
            % of merged components
            componentIds = obj.Graph.listOfComponents();
            rootsOfComp = obj.Graph.rootsOfComponent(componentIds);
            mergedComponentIds = obj.Map.componentToMergedComponent(componentIds);
            outMergedComponentIds = unique(mergedComponentIds);
            
            % Output according to how many entries can be found
            if isscalar(outMergedComponentIds)
                if iscell(rootsOfComp)
                    outRootIds = cell2mat(rootsOfComp);
                else
                    outRootIds = rootsOfComp;
                end
            else
                outRootIds = arrayfun(@iGetRootsOfOneMergedComponent, outMergedComponentIds, ...
                    'UniformOutput', false);
            end
            
            % Helper function
            function someRoots = iGetRootsOfOneMergedComponent(aMergedCompId)
                someRoots = rootsOfComp(mergedComponentIds==aMergedCompId);
                if iscell(someRoots)
                    someRoots = cell2mat(someRoots);
                end
            end
        end
        
        function varargout = sortNodes(obj, inNodes)
            %Sort the input nodes according to the sorting criterion. Error
            %if the sorting criterion was not set
            assert(~isempty(obj.NodeSortingCriterion), "The sorting criterion was not set.");
            outNodes = obj.NodeSortingCriterion(inNodes);
            % Assign outputs
            if nargout>0
                varargout{1} = outNodes;
            end
            if nargout>1
                varargout{2} = iFindSorting(inNodes, outNodes);
            end
        end
        
    end
end

%% HELPER FUNCTIONS

function [nodeIds, subGraphIds] = iGetIndexArrayForm(nodeIds, subGraphIds)
if iscell(nodeIds)
    nodeIds = cell2mat(nodeIds);
end
if iscell(subGraphIds)
    subGraphIds = cell2mat(subGraphIds);
end
assert(numel(nodeIds)==numel(subGraphIds), "The number of node indexes doesn't match the number of sub-graphs.");
end

function [rootIds, subGraphIds, density] = iCheckAssociationIsPossible(rootIds, subGraphIds, density)
errorMessage = "Cannot associate roots of merged components to sub-graphs.";
if iscell(rootIds)
    assert(numel(rootIds)==numel(subGraphIds), errorMessage);
else
    assert(~iscell(subGraphIds), errorMessage);
    rootIds = { rootIds };
end
if ~iscell(subGraphIds)
    subGraphIds = { subGraphIds };
end

% Check the density parameter
assert(density<=1 && density>0, "The density parameter should be between 0 and 1");
end

function outArray = iInvertArray(inArray)
outArray = inArray(end:-1:1);
end

function sorting = iFindSorting(inNodes, outNodes)
assert(isrow(inNodes) && isrow(outNodes) && numel(inNodes)==numel(outNodes), "Input and output are not compatible. Cannot determine sorting.");

% Construct a permutation matrix
permMatrix = inNodes==outNodes';

% Find duplicate columns
duplicateCols = sum(permMatrix)>1;
if any(duplicateCols)
    permMatrix = iRemoveDuplicatesFromPermutationMatrix(permMatrix, duplicateCols);
end

% Assign sorting
sorting = permMatrix*(1:size(permMatrix,2))';
sorting = sorting';
end

function outPermMatrix = iRemoveDuplicatesFromPermutationMatrix(permMatrix, duplicateCols)
duplicateMat = permMatrix(:, duplicateCols);

% Ensure that there is only one entry per row
[numRowsInDuplicateCols, numDuplicateCols] = size(duplicateMat);
fixedRow = amsla.common.nullId(numRowsInDuplicateCols, 1);
for k = 1:numRowsInDuplicateCols
    % If entries in this row have duplicates, fix it and write the column
    % where the element was left
    columnsWithElementsInCurrentRow = find(duplicateMat(k, :));
    
    % Skip empty rows
    if isempty(columnsWithElementsInCurrentRow)
        continue;
    end
    
    % Remove duplicates from the current row
    colToAssign = iGetMinimumUnassignedCol(columnsWithElementsInCurrentRow, fixedRow);
    duplicateMat(k, :) = zeros(1, numDuplicateCols);
    duplicateMat(k, colToAssign) = 1;
    fixedRow(k) = colToAssign;
end

% Reassign duplicate matrix
outPermMatrix = permMatrix;
outPermMatrix(:, duplicateCols) = duplicateMat;

% Check that there are no duplicates anymore
assert(~any(sum(outPermMatrix)>1), "Could not fix duplicates in permutation matrix.");
end

function minCol = iGetMinimumUnassignedCol(columnsWithElements, isFixedRow)
assignmentMatrix = isFixedRow==columnsWithElements;
minCol = find(sum(assignmentMatrix)==0, 1);
end