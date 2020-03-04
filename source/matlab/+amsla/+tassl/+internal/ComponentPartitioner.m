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
        
        %A Table mapping nodes to components.
        Component table
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = ComponentPartitioner(dataStructure)
            %COMPONENTPARTITIONER(G) Construct a ComponentPartitioner
            %object for the DataStructure object G.
            
            validateattributes(dataStructure, ...
                {'amsla.common.DataStructureInterface'}, ...
                {'nonempty', 'scalar'});
            
            obj.DataStructure = dataStructure;
            
            allNodes = dataStructure.listOfNodes;
            obj.Component = table( ...
                allNodes', ...
                amsla.common.nullId(size(allNodes))', ...
                'VariableNames', {'NodeId', 'ComponentId'});
        end
        
        function [componentId, numOfNodes] = listOfComponents(obj)
            %LISTOFCOMPONENTS(P) Get the IDs of components in the graph.
            %
            %   C = LISTOFCOMPONENTS(C) Get the IDs of the components
            %   only.
            %
            %   [C, NC] = LISTOFCOMPONENTS(C) Get the IDs and the number of
            %   nodes in each component.
            
            componentId = unique(obj.Component.ComponentId);
            numOfNodes = sum(obj.Component.ComponentId == componentId');
            componentId = iRowVector(componentId);
            numOfNodes = iRowVector(numOfNodes);
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
        
        function computeComponents(obj)
            %COMPUTECOMPONENTS(G) Compute the weakly-connected components in
            %the graph.
            
            allNodes = obj.rootNodes([]);
            allComponents = 1:numel(allNodes);
            
            currNodes = allNodes;
            currComponents = allComponents;
            while ~isempty(currNodes)
                obj.putNodeInComponent(currNodes, currComponents);
                currChildren = obj.DataStructure.childrenOfNode(currNodes);
                [currNodes, currComponents] = ...
                    obj.matchNodesAndComponents(currChildren, currComponents);
            end
            
            assert(~any(amsla.common.isNullId(obj.Component.ComponentId)), ...
                "amsla:ComponentPartitioner:IncompleteAssignment", ...
                "Not all the nodes in the graph were assigned to a component");
            
            obj.minimiseComponentRange();
        end
    end
    
    methods(Access=private)
        
        function minimiseComponentRange(obj)
            %MINIMISECOMPONENTRANGE(obj)
            
            allComponents = unique(obj.Component.ComponentId);
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
            
            obj.Component.ComponentId( ...
                ismember(obj.Component.ComponentId, oldComponentIds)) = newComponentId;
        end
        
        function putNodeInComponent(obj, currNodes, currComponents)
            %PUTNODEINCOMPONENT(P, NID, CID) Put the nodes with IDs NID in
            %the components of IDs CID.
            
            [uniqueNodes, sorter] = unique(currNodes);
            assert(numel(uniqueNodes)==numel(currNodes), ...
                "Ambiguous input.");
            
            uniqueComponents = currComponents(sorter);
            obj.Component.ComponentId(ismember(obj.Component.NodeId, uniqueNodes)) = ...
                uniqueComponents';
        end
        
        function nodeIds = rootNodes(obj, componentIds)
            %ROOTNODES(P, CID) Root nodes in a given component.
            %
            %   ROOTNODES(P, CID) Root Nodes in components with IDs CID.
            %
            %   ROOTNODES(P, []) Root nodes in the whole graph.
            
            if isempty(componentIds)
                nodeIds = obj.Component.NodeId( ...
                    obj.numberOfParents(obj.Component.NodeId) == 0);
            else
                [componentIds, ~, invSorter] = unique(componentIds);
                nodeIds = arrayfun(@(x) ...
                    obj.Component.NodeId( ...
                    obj.numberOfParents(obj.Component.NodeId) == 0 & ...
                    obj.Component.ComponentId == x), ...
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
dataOut = reshape(dataIn, 1, []);
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