classdef(Abstract) BreadthFirstSearch < handle
    %AMSLA.TASSL.INTERNAL.BREADTHFIRSTSEARCH Carry out a breadth-first
    %search to tag the nodes of a graph.
    %
    %   P = AMSLA.TASSL.INTERNAL.BREADTHFIRSTSEACH(G) Create a component
    %   partitioner for the DataStructure object G.
    
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
    
    %% PROTECTED PROPERTIES
    
    properties(GetAccess=protected,SetAccess=immutable)
        
        %The object being processed.
        DataStructure
        
    end
    
    %% ABSTRACT METHODS
    
    methods(Abstract, Access=protected)
        
        [nodeIds, tags] = initialNodesAndTags(obj);
        
        nodeIds = selectNextNodes(obj, currentNodeIds);
        
        tags = computeTags(obj, nodeIds);
        
        assignTagsToNodes(obj, nodeIds, tags);
        
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = BreadthFirstSearch(dataStructure)
            %BREADTHFIRSTSEACH(G) Construct a BreadthFirstSearch
            %object for the DataStructure object G.
            
            validateattributes(dataStructure, ...
                {'amsla.common.DataStructureInterface'}, ...
                {'nonempty', 'scalar'});
            
            obj.DataStructure = dataStructure;
        end
    end
    
    %% PROTECTED METHODS
    
    methods(Access=protected)
        
        function success = executeAlgorithm(obj)
            %EXECUTEALGORITHM(B) Execute the algorithm.
            
            success = true;
            
            [currNodeIds, currTags] = obj.initialNodesAndTags();
            currNodeIds = iArray(currNodeIds);
            currTags = iArray(currTags);
            
            assert(numel(unique(currNodeIds))==numel(currNodeIds), ...
                "Ambiguous input.");
            
            while ~isempty(currNodeIds)
                % Assign the current tags to the current nodes
                obj.assignTagsToNodes(currNodeIds, currTags);
                
                % Get the children of the current nodes and select a
                % sub-set of them according to the node selector function.
                currNodeIds = iArray(obj.selectNextNodes(currNodeIds));
                if isempty(currNodeIds)
                    break;
                end
                
                % Compute the tag to assign to the children node according
                % to the given function
                currTags = obj.computeTags(currNodeIds);
                if any(amsla.common.isNullId(currTags))
                    success = false;
                    break;
                end
            end
        end
        
        function compOut = computeBasedOnParents(obj, nodeIds, processPerNodeFcn)
            %Given a set of node IDs, get their parents and apply
            %processPerNodeFcn on them to get compOut.
            
            validateattributes(processPerNodeFcn, {'function_handle'}, ...
                {'scalar', 'nonempty'});
            
            parentsOfChildren = obj.DataStructure.parentsOfNode(nodeIds);
            if iscell(parentsOfChildren)
                compOut = cellfun(processPerNodeFcn, parentsOfChildren, ...
                    'UniformOutput', true);
            else
                compOut = processPerNodeFcn(parentsOfChildren);
            end
        end
        
        function nodeIds = selectChildrenIfReady(obj, currentNodeIds, isReadyFcn)
            %SELECTCHILDRENIFREADY Select the children of the input nodes if
            %they satisfy the given function.
            
            % Find children of current nodes
            dataStructure = obj.DataStructure;
            nodeIds = dataStructure.childrenOfNode(currentNodeIds);
            nodeIds = unique(amsla.common.numericArray(nodeIds));
            
            % Find out which ones are ready
            isChildReady = obj.computeBasedOnParents(nodeIds, isReadyFcn);
            nodeIds = nodeIds(isChildReady);
        end
        
        function nodeIds = selectChildrenIfAllParentsAssigned(obj, currentNodeIds, tagAccessor)
            %SELECTCHILDRENIFALLPARENTSASSIGNED Select the children of the
            %input nodes if all of their parents have been assigned a tag.
            
            % Find children of current nodes
            nodeIds = obj.selectChildrenIfReady(currentNodeIds, @isNodeReady);
            
            function tf = isNodeReady(parentNodes)
                tf = ~any(iIsNullId(tagAccessor(obj.DataStructure, parentNodes)));
            end
        end
        
        function tagId = maxTagOfParents(obj, currentNodeIds, tagAccessor)
            %MAXSUBGRAPHOFPARENTS Get the highest tag assigned to the
            %parent nodes of each input node.
            
            tagId = obj.computeBasedOnParents(currentNodeIds, @getLargestTagId);
            
            function nextTagId = getLargestTagId(allParents)
                % Get the components of parent nodes
                nextTagId = tagAccessor(obj.DataStructure, allParents);
                
                % Compute the max
                nextTagId = max(nextTagId);
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
