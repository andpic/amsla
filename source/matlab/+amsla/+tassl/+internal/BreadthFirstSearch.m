classdef BreadthFirstSearch < handle
    %AMSLA.TASSL.INTERNAL.BREADTHFIRSTSEARCH Carry out a breadth-first
    %search to tag the nodes of a graph.
    %
    %   P = AMSLA.TASSL.INTERNAL.BREADTHFIRSTSEACH(G) Create a component
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
        
        % A map of nodes and tags
        NodeTagMap
        
        %Function to select nodes
        NodeSelectorFcn
        
        %Function that computes the
        NodeTagFcn
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = BreadthFirstSearch(dataStructure, ...
                nodeSelectorFcn, ...
                nodeTagFcn)
            %COMPONENTPARTITIONER(G) Construct a ComponentPartitioner
            %object for the DataStructure object G.
            
            validateattributes(dataStructure, ...
                {'amsla.common.DataStructureInterface'}, ...
                {'nonempty', 'scalar'});
            
            obj.DataStructure = dataStructure;
            obj.NodeSelectorFcn = nodeSelectorFcn;
            obj.NodeTagFcn = nodeTagFcn;
            
            allNodes = iRowVector(dataStructure.listOfNodes);
            obj.NodeTagMap = struct( ...
                allNodes, ...
                amsla.common.nullId(size(allNodes)), ...
                'VariableNames', {'NodeId', 'Tag'});
        end
        
        function [tag, numOfNodes] = listOfTags(obj)
            %LISTOFTAGS(P) Get a list of tags obtained in the breadth-first
            %search.
            %
            %   T = LISTOFTAGS(G) Get the tags only.
            %
            %   [T, N] = LISTOFTAGS(B) Get the tags and the number of
            %   nodes with the given tag.
            
            tag = unique(obj.NodeTagMap.Tag);
            numOfNodes = sum(obj.NodeTagMap.Tag == tag');
            tag = iRowVector(tag);
            numOfNodes = iRowVector(numOfNodes);
        end
        
        function tag = tagOfNode(obj, nodeIds)
            %TAGOFNODE(P, ID) Get the tag of one or more nodes.
            
            [nodeIds, ~, invSorter] = unique(nodeIds);
            tag = obj.NodeTagMap.Tag(ismember(obj.NodeTagMap.NodeId, nodeIds));
            tag = iRowVector(tag(invSorter));
        end
        
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
        
        function executeAlgorithm(obj, startingNodes, startingTags)
            %EXECUTEALGORITHM(B, NID) Execute the algorithm starting from
            %the nodes specified by NID.
            
            assert(numel(unique(startingNodes))==numel(startingNodes), ...
                "Ambiguous input.");
            
            currNodes = startingNodes;
            currComponents = startingTags;
            while ~isempty(currNodes)
                obj.attachTagToNode(currNodes, currComponents);
                currChildren = obj.DataStructure.childrenOfNode(currNodes);
                [currNodes, currComponents] = ...
                    obj.matchNodesAndComponents(currChildren, currComponents);
            end
            
            assert(~any(amsla.common.isNullId(obj.NodeTagMap.Tag)), ...
                "amsla:ComponentPartitioner:IncompleteAssignment", ...
                "Not all the nodes in the graph were assigned to a component");
            
            obj.minimiseComponentRange();
        end
        
        function minimiseComponentRange(obj)
            %MINIMISECOMPONENTRANGE(obj) Make sure the components are numbered from
            %1 to N.
            
            allComponents = unique(obj.NodeTagMap.Tag);
            numComp = numel(allComponents);
            newIds = 1:numComp;
            for k = 1:numComp
                obj.changeTag(allComponents(k), newIds(k));
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
                
                minTag = min(currComponents);
                otherComponents = currComponents(currComponents ~= minTag);
                
                obj.changeTag(otherComponents, minTag);
                outComponents(k) = minTag;
            end
            
            assert(~any(amsla.common.isNullId(outComponents)), ...
                "Not all components were assigned.");
        end
        
        function changeTag(obj, oldTags, newTag)
            %CHANGECOMPONENTID(P, OLDID, NEWID) Replace component IDs with
            %another one.
            
            assert(isscalar(newTag), ...
                "New component ID should be a scalar.");
            
            obj.NodeTagMap.Tag( ...
                ismember(obj.NodeTagMap.Tag, oldTags)) = newTag;
        end
        
        function putNodeInComponent(obj, currNodes, currComponents)
            %PUTNODEINCOMPONENT(P, NID, CID) Put the nodes with IDs NID in
            %the components of IDs CID.
            
            [uniqueNodes, sorter] = unique(currNodes);
            assert(numel(uniqueNodes)==numel(currNodes), ...
                "Ambiguous input.");
            
            uniqueComponents = currComponents(sorter);
            obj.NodeTagMap.Tag(ismember(obj.NodeTagMap.NodeId, uniqueNodes)) = ...
                uniqueComponents';
        end
        
        function nodeIds = rootNodes(obj, tags)
            %ROOTNODES(P, CID) Root nodes in a given component.
            %
            %   ROOTNODES(P, CID) Root Nodes in components with IDs CID.
            %
            %   ROOTNODES(P, []) Root nodes in the whole graph.
            
            if isempty(tags)
                nodeIds = obj.NodeTagMap.NodeId( ...
                    obj.numberOfParents(obj.NodeTagMap.NodeId) == 0);
            else
                [tags, ~, invSorter] = unique(tags);
                nodeIds = arrayfun(@(x) ...
                    obj.NodeTagMap.NodeId( ...
                    obj.numberOfParents(obj.NodeTagMap.NodeId) == 0 & ...
                    obj.NodeTagMap.Tag == x), ...
                    tags, ...
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
if isempty(dataIn)
    dataOut = [];
else
    dataOut = reshape(dataIn, 1, []);
end
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
dataOut = dataIn;
if iscell(dataOut)
    dataOut = iRowVector(cell2mat(dataOut));
end
end
