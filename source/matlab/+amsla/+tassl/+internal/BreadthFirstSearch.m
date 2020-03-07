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
        
        function executeAlgorithm(obj)
            %EXECUTEALGORITHM(B) Execute the algorithm.
            
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
                
                % Compute the tag to assign to the children node according
                % to the given function
                currTags = obj.computeTags(currNodeIds);
            end
            
            assert(~any(amsla.common.isNullId(obj.NodeTagMap.Tag)), ...
                "amsla:BreadthFirstSearch:IncompleteAssignment", ...
                "Not all the nodes in the graph were assigned to a component");
        end
        
    end
end

%% HELPER FUNCTIONS

function dataOut = iArray(dataIn)
dataOut = amsla.common.numericArray(dataIn);
end