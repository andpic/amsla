classdef TimeSlotDecorator < amsla.common.DataStructureDecorator
    %AMSLA.TASSL.INTERNAL.TIMESLOTDECORATOR A DataStructure decorator that
    %associates graph nodes to the maximum time-slot of an entering edge.
    %
    %   AMSLA.TASSL.INTERNAL.TIMESLOTDECORATOR decoration methods:
    %      timeSlotNodeReached      - Get the ID of the maximum time-slot
    %                                 of entering edge.
    %      setTimeSlotNodeReached   - Associate a node with a time-slot.
    
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
    
    properties(SetAccess=immutable)
        
        % Name of the node tag used by the decorator
        TagName
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = TimeSlotDecorator(aDataStructure)
            %TIMESLOTDECORATOR(DS) Decorate the DataStructure object DS to
            %associate nodes to time-slots.
            
            tagName = "TimeSlot";
            obj = obj@amsla.common.DataStructureDecorator(aDataStructure, tagName);
            obj.TagName = tagName;
        end
        
        function componentId = timeSlotNodeReached(obj, nodeId)
            %TIMESLOTNODEREACHED(D, NID) Get the time-slot ID associated
            %with the node.
            
            componentId = obj.tagOfNode(obj.TagName, nodeId);
        end
        
        function setTimeSlotNodeReached(obj, nodeId, timeSlotId)
            %SETCOMPONENTOFNODE(D, NID, TID) Associate node NID with the
            %time-slot TID.
            
            obj.setTagOfNode(obj.TagName, nodeId, timeSlotId);
        end
        
        function outIds = parentsOfNode(obj, nodeIds)
            outIds = parentsOfNode@amsla.common.DataStructureDecorator(obj, nodeIds);
            outIds = obj.selectNodesInSameSubGraph(outIds, nodeIds);
        end
        
        function outIds = childrenOfNode(obj, nodeIds)
            outIds = childrenOfNode@amsla.common.DataStructureDecorator(obj, nodeIds);
            outIds = obj.selectNodesInSameSubGraph(outIds, nodeIds);
        end
        
        function outIds = externalEdgesOfNode(obj, nodeIds)
            %EXTERNALEDGESOFNODE Given a node, return the IDs of the
            %external edges.
            %
            % External edges are entering edges that connect to nodes
            %that are not in the same sub-graph as the current node.
            
            outIds = obj.enteringEdgesOfNode(nodeIds);
            outIds = obj.selectExternalEdges(outIds, nodeIds);
        end
        
        function outIds = internalEdgesOfNode(obj, nodeIds)
            %INTERNALEDGESOFNODE Given a node, return the IDs of the
            %external edges.
            %
            %Internal edges are entering edges that connect to nodes
            %that are in the same sub-graph as the current node.
            
            outIds = obj.enteringEdgesOfNode(nodeIds);
            outIds = obj.selectInternalEdges(outIds, nodeIds);
        end
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
        function edgeIds = selectExternalEdges(obj, edgeIds, refNodeId)
            %Select the external edges with respect to the reference nodes
            
            edgeIds = amsla.common.internal.applyNaryFunction( ...
                @externalEdgeSelector, ...
                edgeIds, ...
                refNodeId);
            
            function edges = externalEdgeSelector(edges, refNode)
                if ~isempty(edges)
                    edges = edges(~obj.isInternalEdge(edges, refNode));
                end
            end
        end
        
        
        function edgeIds = selectInternalEdges(obj, edgeIds, refNodeId)
            %Select the internal edges with respect to the reference nodes
            
            edgeIds = amsla.common.internal.applyNaryFunction( ...
                @internalEdgeSelector, ...
                edgeIds, ...
                refNodeId);
            
            function edges = internalEdgeSelector(edges, refNode)
                if ~isempty(edges)
                    edges = edges(obj.isInternalEdge(edges, refNode));
                end
            end
        end
        
        function nodeIds = selectNodesInSameSubGraph(obj, nodeIds, refNodeId)
            %Select the nodes that are in the same sub-graph as those in
            %refNodeId
            
            nodeIds = amsla.common.internal.applyNaryFunction( ...
                @nodeSelector, ...
                nodeIds, ...
                refNodeId);
            
            function nodes = nodeSelector(nodes, refNode)
                if ~isempty(nodes)
                    nodes = nodes(obj.isInSameSubGraph(nodes, refNode));
                end
            end
        end
        
        function tf = isInternalEdge(obj, currEdgeIds, refNodeId)
            %Return true if the edge is internal
            
            assert(isscalar(refNodeId) && isnumeric(refNodeId), ...
                "Reference node should be a scalar");
            
            parentNodes = obj.enteringNodeOfEdge(currEdgeIds);
            tf = obj.isInSameSubGraph(parentNodes, refNodeId);
        end
        
        function tf = isInSameSubGraph(obj, nodeIds, refNodeId)
            %Returns true for the nodes that are in the same sub-graph as
            %refNodeId
            
            assert(isscalar(refNodeId) && isnumeric(refNodeId), ...
                "Reference node should be a scalar");
            
            assert(isscalar(refNodeId) && ~isempty(refNodeId));
            currSubGraph = obj.subGraphOfNode(refNodeId);
            inputSubGraphs = obj.subGraphOfNode(nodeIds);
            tf = inputSubGraphs==currSubGraph;
        end
    end
end