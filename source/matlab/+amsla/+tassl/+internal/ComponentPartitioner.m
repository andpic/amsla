classdef ComponentPartitioner < handle
    %AMSLA.TASSL.INTERNAL.COMPONENTPARTITIONER Partitions a DataStructure
    %into its weakly connected components.
    %
    %   P = AMSLA.TASSL.INTERNAL.COMPONENTPARTITIONER(G) Create a component
    %   partitioner for the DataStructure object G.
    %
    %   ComponentPartitioner methods:
    
    % Copyright 2018-2020 Andrea Picciau
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
        %The object being partitioned.
        DataStructure        
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = ComponentPartitioner(dataStructure)
            %COMPONENTPARTITIONER(G) Construct a ComponentPartitioner
            %object for the DataStructure object G.
            
            validateattributes(dataStructure, ...
                {'amsla.tassl.internal.ComponentDecorator'}, ...
                {'nonempty', 'scalar'});
            
            obj.DataStructure = dataStructure;
            
            obj.computeComponents();
        end
        
        function outIds = rootsOfComponent(obj, componentIds)
            %ROOTSOFCOMPONENT(P, ID) Get the IDs of the nodes without a
            %parent in one or more components.
            
            outIds = iRowVector(obj.rootNodes(componentIds));
        end
        
        function outIds = componentOfNode(obj, nodeIds)
            %COMPONENTOFNODE(P, ID) Get the component IDs of one or more nodes.
            
            [nodeIds, ~, invSorter] = unique(nodeIds);
            outIds = obj.Component.ComponentId(ismember(obj.Component.NodeId, nodeIds));
            outIds = iRowVector(outIds(invSorter));
        end
        
        function mergeComponents(obj, minSize)
            %MERGECOMPONENTS(OBJ, MAXSIZE) Merge graph components with a
            %size less than MAXSIZE.
            
            [componentIds, componentSizes] = obj.listOfComponents();
            
            [oldComponentIds, newComponentIds] = ...
                iMergeSmallComponents(componentIds, componentSizes, minSize);
            obj.changeComponentId(oldComponentIds, newComponentIds);
            
            obj.minimiseComponentRange();
        end
        
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
        
        function computeComponents(obj)
            %COMPUTECOMPONENTS(G) Compute the weakly-connected components in
            %the graph.
            
            allNodes = obj.rootNodes([]);
            allComponents = 1:numel(allNodes);
            
            currNodes = allNodes;
            currComponents = allComponents;
            while ~isempty(currNodes)
                obj.DataStructure.setComponentOfNode(currNodes, currComponents);
                currChildren = obj.DataStructure.childrenOfNode(currNodes);
                [currNodes, currComponents] = ...
                    obj.matchNodesAndComponents(currChildren, currComponents);
            end
            
            assert(~any(amsla.common.isNullId(obj.DataStructure.listOfComponents())), ...
                "amsla:ComponentPartitioner:IncompleteAssignment", ...
                "Not all the nodes in the graph were assigned to a component");
            
            obj.minimiseComponentRange();
        end
        
        function minimiseComponentRange(obj)
            %MINIMISECOMPONENTRANGE(obj) Make sure the components are numbered from
            %1 to N.
            
            allComponents = unique(obj.DataStructure.listOfComponents());
            numComp = numel(allComponents);
            newIds = 1:numComp;
            for k = 1:numComp
                obj.changeComponentId(allComponents(k), newIds(k));
            end
        end
        
        function [outNodes, outComponents] = ...
                matchNodesAndComponents(obj, inNodes, inComponents)
            %MATCHNODESANDCOMPONENTS(G, NID, CID) Given sets of input nodes
            %to assign to components, make sure there is no ambiguity.
            
            [inNodes, inComponents] = iMatchSize(inNodes, inComponents);
            [uniqueNodes, possibleComponents] = ...
                iCategoriseAssociationsByNode(inNodes, inComponents);
            
            outNodes = uniqueNodes;
            outComponents = amsla.common.nullId(size(outNodes));
            
            for k = 1:numel(uniqueNodes)
                currComponents = possibleComponents{k};
                
                minComponentId = min(currComponents);
                otherComponents = currComponents(currComponents ~= minComponentId);
                
                obj.changeComponentId(otherComponents, minComponentId);
                outComponents(k) = minComponentId;
            end
            
            assert(~any(amsla.common.isNullId(outComponents)), ...
                "Not all components were assigned.");
        end
        
        function changeComponentId(obj, oldComponentIds, newComponentId)
            %CHANGECOMPONENTID(P, OLDID, NEWID) Replace component IDs with
            %another one.
            
            assert(isscalar(newComponentId), ...
                "New component ID should be a scalar.");
            
            listOfNodes = obj.DataStructure.listOfNodes();
            listOfComponents = obj.DataStructure.componentOfNode(listOfNodes);
            selOldComponent = ismember(listOfComponents, oldComponentIds);
            
            obj.DataStructure.setComponentOfNode( ...
                listOfNodes(selOldComponent), newComponentId);
        end
        
        function nodeIds = rootNodes(obj, componentIds)
            %ROOTNODES(P, CID) Root nodes in a given component.
            %
            %   ROOTNODES(P, CID) Root Nodes in components with IDs CID.
            %
            %   ROOTNODES(P, []) Root nodes in the whole graph.
            
            allNodes = obj.DataStructure.listOfNodes();
            if isempty(componentIds)
                nodeIds = allNodes(obj.numberOfParents(allNodes) == 0);
            else
                allComponents = obj.DataStructure.componentOfNode(allNodes);
                [componentIds, ~, invSorter] = unique(componentIds);
                nodeIds = arrayfun(@(x) ...
                    allNodes(obj.numberOfParents(allNodes) == 0 & allComponents == x), ...
                    componentIds, ...
                    'UniformOutput', false);
                nodeIds = nodeIds(invSorter);
            end
        end
        
        function num = numberOfParents(obj, nodeIds)
            %NUMBEROFPARENTS(P, NID) Number of parents of the given nodes,
            %given their IDs.
            
            parentsOfNodes = obj.DataStructure.parentsOfNode(nodeIds);
            if iscell(parentsOfNodes)
                num = cellfun(@numel, parentsOfNodes, 'UniformOutput', true);
            else
                num = numel(parentsOfNodes);
            end
        end
        
    end
end

%% HELPER FUNCTIONS

function dataOut = iRowVector(dataIn)
dataOut = amsla.common.rowVector(dataIn);
end

function [outNodes, outComponents] = iMatchSize(inNodes, inComponents)
% Make sure there is one component per node

if iscell(inNodes)
    numCells = numel(inNodes);
    assert(numCells == numel(inComponents), ...
        "Input sizes mismatch");
    
    outComponents = cell(1, numCells);
    for k = 1:numCells
        outComponents{k} = repmat(inComponents(k), 1, numel(inNodes{k}));
    end
else
    outComponents = repmat(inComponents, 1, numel(inNodes));
end

outNodes = iArray(inNodes);
outComponents = iArray(outComponents);
end

function [uniqueNodes, possibleComponents] = ...
    iCategoriseAssociationsByNode(inNodes, inComponents)
% Given couples of nodes and components (with possible duplicates), organise them
% by node

assert(numel(inNodes)==numel(inComponents), ...
    "Inputs mismatch");

[uniqueNodes, ~] = unique(inNodes);
numUnique = numel(uniqueNodes);
possibleComponents = cell(1, numUnique);
for k = 1:numUnique
    currNode = uniqueNodes(k);
    currComponents = inComponents(inNodes==currNode);
    possibleComponents{k} = [possibleComponents{k}, currComponents];
end
end

function dataOut = iArray(dataIn)
dataOut = amsla.common.numericArray(dataIn);
end

function [oldComponentIds, newComponentIds] = iMergeSmallComponents(componentIds, componentSizes, maxSize)
% Merges components that are smaller than maxSize into new components

% Sort components by size
[componentSizes, sorter] = sort(componentSizes, 'descend');
componentIds = componentIds(sorter);
maxComponentId = max(componentIds);

% Select the small components
selSmallComponents = componentSizes<maxSize;
smallComponents = componentIds(selSmallComponents);
smallComponentsSizes = componentSizes(selSmallComponents);
numSmallComponents = numel(smallComponents);

newSmallComponentIds = amsla.common.nullId(size(smallComponents));
currNewSmallComponentId = maxComponentId;

% Loop through all components starting from the largest ones
for k = 1:numSmallComponents
    % Skip is component has already been assigned
    if ~iIsNullId(newSmallComponentIds(k))
        continue;
    end
    
    currNewSmallComponentId = currNewSmallComponentId+1;
    newSmallComponentIds(k) = currNewSmallComponentId;
    currNewComponentSize = smallComponentsSizes(k);
    
    for j = (k+1):numSmallComponents
        % Check if the component can be merged
        if  iIsNullId(newSmallComponentIds(j)) && currNewComponentSize+smallComponentSize(j) <= maxSize
            newSmallComponentIds(j) = currNewSmallComponentId;
            currNewComponentSize = currNewComponentSize + smallComponentSize(j);
        end
    end
end

% Merge with large component table
oldComponentIds = componentIds;
newComponentIds = oldComponentIds;
newComponentIds(selSmallComponents) = newSmallComponentIds;

% Check output
assert(~any(iIsNullId(newSmallComponentIds)), ...
    "One or more components were not merged");
end

function tf = iIsNullId(dataIn)
tf = amsla.common.isNullId(dataIn);
end