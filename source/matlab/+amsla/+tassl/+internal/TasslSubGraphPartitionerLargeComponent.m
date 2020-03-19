classdef(Sealed) TasslSubGraphPartitionerLargeComponent < ...
        amsla.tassl.internal.TasslSubGraphPartitionerImplInterface & ...
        amsla.tassl.internal.BreadthFirstSearch & ...
        amsla.tassl.internal.SelectChildrenIfReady
    %AMSLA.TASSL.INTERNAL.TASSLSUBGRAPHPARTITIONERLARGECOMPONENT Partition
    %a large graph component into sub-graphs.
    
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
        
        function obj = TasslSubGraphPartitionerLargeComponent(dataStructure, maxSize, componentId)
            %TASSLSUBGRAPHPARTITIONERLARGECOMPONENT(G) Construct a
            %TasslSubGraphPartitioner and partition the input DataStructure
            %object.
            
            validateattributes(dataStructure, {'amsla.tassl.internal.ComponentDecorator'}, ...
                {'scalar', 'nonempty'});
            
            obj = obj@amsla.tassl.internal.BreadthFirstSearch(dataStructure);
            obj@amsla.tassl.internal.TasslSubGraphPartitionerImplInterface(maxSize, componentId);            
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
            %assigned to a sub-graph.
            
            % Find children of current nodes
            nodeIds = obj.selectChildrenIfReady(currentNodeIds, @isNodeReady);
            
            function tf = isNodeReady(parentNodes)
                tf = ~any(iIsNullId(obj.DataStructure.subGraphOfNode(parentNodes)));
            end
        end
        
        function componentIds = computeTags(obj, currentNodeIds)
            %COMPUTETAGS Compute the sub-graph ID for each of the current
            %nodes to assign.
            
            componentIds = obj.computeBasedOnParents(currentNodeIds, @getSmallestCompId);
            
            function nextComponentId = getSmallestCompId(allParents)
                % Get the components of parent nodes
                compId = obj.DataStructure.componentOfNode(allParents);
                
                % Compute the min
                nextComponentId = min(compId);
            end
        end
        
        function assignTagsToNodes(obj, nodeIds, tags)
            %ASSIGNTAGSTONODES Assign the sub-graph to the given node IDs.
            
            obj.DataStructure.setComponentOfNode(nodeIds, tags);
        end
        
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
        
        function nodeIds = rootNodes(obj, componentIds)
            %ROOTNODES(P, CID) Root nodes in a given component.
            
            allNodes = obj.DataStructure.listOfNodes();
            allComponents = obj.DataStructure.componentOfNode(allNodes);
            [componentIds, ~, invSorter] = unique(componentIds);
            nodeIds = arrayfun(@(x) ...
                allNodes(obj.numberOfParents(allNodes) == 0 & allComponents == x), ...
                componentIds, ...
                'UniformOutput', false);
            nodeIds = nodeIds(invSorter);
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

function tf = iIsNullId(dataIn)
tf = amsla.common.isNullId(dataIn);
end