classdef ComponentPartitioner < amsla.tassl.internal.BreadthFirstSearch & ...
        amsla.tassl.internal.SelectChildrenIfReady
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
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = ComponentPartitioner(dataStructure)
            %COMPONENTPARTITIONER(G) Construct a ComponentPartitioner
            %object for the DataStructure object G.
            
            validateattributes(dataStructure, {'amsla.tassl.internal.ComponentDecorator'}, ...
                {'scalar', 'nonempty'});
            
            obj = obj@amsla.tassl.internal.BreadthFirstSearch(dataStructure);
            obj.executeAlgorithm();
            obj.minimiseComponentRange();
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
    
    %% PROTECTED METHODS
    
    methods(Access=protected)
        
        function [nodeIds, initialComponents] = initialNodesAndTags(obj)
            %INITIALNODESANDTAGS Get the nodes and tags to initialise the
            %algorithm.
            
            nodeIds = iArray(obj.rootNodes());
            initialComponents = iArray(1:numel(nodeIds));
        end
        
        function nodeIds = selectNextNodes(obj, currentNodeIds)
            %SELECTNEXTNODES Select the nodes whose parents have all been
            %assigned to a component.
            
            % Find children of current nodes
            nodeIds = obj.selectChildrenIfReady(currentNodeIds, @isNodeReady);
            
            function tf = isNodeReady(parentNodes)
                tf = ~any(iIsNullId(obj.DataStructure.componentOfNode(parentNodes)));
            end
        end
        
        function componentIds = computeTags(obj, currentNodeIds)
            %COMPUTETAGS Compute the component ID for each of the current
            %nodes to assign.
            
            componentIds = obj.computeBasedOnParents(currentNodeIds, @getSmallestCompId);
            
            function nextComponentId = getSmallestCompId(allParents)
                % Get the components of parent nodes
                compId = obj.DataStructure.componentOfNode(allParents);
                
                % Compute the min
                nextComponentId = min(compId);
                if numel(compId)>1
                    otherComponentIds = compId(compId~=nextComponentId);
                    obj.changeComponentId(otherComponentIds, nextComponentId);
                end
            end
        end
        
        function assignTagsToNodes(obj, nodeIds, tags)
            %ASSIGNTAGSTONODES Assign the tags to the given node IDs.
            
            obj.DataStructure.setComponentOfNode(nodeIds, tags);
        end
        
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
        
        function minimiseComponentRange(obj)
            %Make sure the components are numbered from 1 to N.
            
            allComponents = unique(obj.DataStructure.listOfComponents());
            numComp = numel(allComponents);
            newIds = 1:numComp;
            for k = 1:numComp
                obj.changeComponentId(allComponents(k), newIds(k));
            end
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
        
        function nodeIds = rootNodes(obj)
            %ROOTNODES(P) Root nodes in the whole graph.
            
            allNodes = obj.DataStructure.listOfNodes();
            nodeIds = allNodes(obj.numberOfParents(allNodes) == 0);
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