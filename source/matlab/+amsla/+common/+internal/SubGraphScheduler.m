classdef(Sealed) SubGraphScheduler < amsla.common.BreadthFirstSearch
    %AMSLA.TASSL.INTERNAL.SUBGRAPHSCHEDULER Partition a large graph component
    %into sub-graphs.
    
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
    
    %% PRIVATE PROPERTIES
    
    properties(Access=private)
        
        %ID of the sub-graph being processed
        SubGraphId
        
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = SubGraphScheduler(dataStructure, subGraphId)
            %SUBGRAPHSCHEDULER(G,SID) Construct an objects that schedules the
            %edges of nodes in sub-graph SID to time-slots.
            
            validateattributes(dataStructure, {'amsla.common.DataStructureInterface'}, ...
                {'scalar', 'nonempty'});
                                    
            obj = obj@amsla.common.BreadthFirstSearch( ...
                amsla.common.internal.TimeSlotDecorator(dataStructure));
            obj.SubGraphId = subGraphId;
        end
        
        function scheduleOperations(obj)
            %SCHEDULEOPERATIONS Assign edges to time-slots.
            
            obj.executeAlgorithm();
        end
    end
    
    %% PROTECTED METHODS
    
    methods(Access=protected)
        
        function [nodeIds, initialTimeSlots] = initialNodesAndTags(obj)
            %INITIALNODESANDTAGS Get the nodes and tags to initialise the
            %algorithm.
            
            nodeIds = iRow(obj.rootNodes());            
            initialTimeSlots = iRow(zeros(size(nodeIds)));
        end
        
        function nodeIds = selectNextNodes(obj, currentNodeIds)
            %SELECTNEXTNODES Select the nodes whose parents have all been
            %assigned to a time-slot.
            
            % Find children of current nodes
            nodeIds = iRow(obj.selectChildrenIfAllParentsAssigned(currentNodeIds, ...
                @timeSlotNodeReached));
        end
        
        function timeSlotId = computeTags(obj, currentNodeIds)
            %COMPUTETAGS Compute the max time-slot ID for eeach node.
            
            timeSlotId = iRow(obj.maxTagOfParents(currentNodeIds, @timeSlotNodeReached));
            timeSlotId = iNextTimeSlot(timeSlotId);
        end
        
        function assignTagsToNodes(obj, nodeIds, tags)
            %ASSIGNTAGSTONODES Assign all the entering edges and the
            %current nodes to a time-slot.
            
            assert(all(~amsla.common.isNullId(tags)), ...
                "All the time-slots should be valid IDs");
            assert(numel(tags)==numel(nodeIds), ...
                "There should be a tag to assign per node");
            
            obj.assignExternalEdges(nodeIds, iExternal(ones(size(nodeIds))));
            obj.assignInternalEdges(nodeIds, tags);
            
            % Nodes with loop edges are reached in the next time-slot
            whichHasLoops = obj.hasLoopEdges(nodeIds);
            tags(whichHasLoops) = iNextTimeSlot(tags(whichHasLoops));
            obj.assignLoopEdges(nodeIds, tags);
            obj.DataStructure.setTimeSlotNodeReached(nodeIds, tags);
        end
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
        
        function nodeIds = rootNodes(obj)
            %ROOTNODES Root nodes the current sub-graph.
            
            allNodes = obj.DataStructure.listOfNodes();
            allNodesInSubGraph = allNodes(obj.nodeIsInCurrentSubGraph(allNodes));
            
            isRoot = arrayfun(@iIsRoot, allNodesInSubGraph, 'UniformOutput', true);
            nodeIds = allNodesInSubGraph(isRoot);
            
            function tf = iIsRoot(currNode)
                % True if either the node doesn't have parents or if any parents
                % are not in the same sub-graphs as the node.
                
                currParents = obj.DataStructure.parentsOfNode(currNode);
                tf = isempty(currParents);
            end
        end
        
        function tf = nodeIsInCurrentSubGraph(obj, nodeIds)
            %NODEISINCURRENTSUBGRAPH True if the input nodes are in the
            %current sub-graph
            
            inputSubGraphId = obj.DataStructure.subGraphOfNode(nodeIds);
            tf = inputSubGraphId == obj.SubGraphId;
        end
        
        function assignInternalEdges(obj, nodeIds, timeSlotIds)
            %ASSIGNINTERNALEDGES Assign the internal edges to the node to a
            %given time-slot.
            
            obj.assignInputEdges(nodeIds, timeSlotIds, @internalEdgesOfNode);
        end
                
        function assignExternalEdges(obj, nodeIds, timeSlotIds)
            %ASSIGNEXTERNALEDGES Assign the external edges to the node to a
            %given time-slot.
            
            obj.assignInputEdges(nodeIds, timeSlotIds, @externalEdgesOfNode);
        end
        
        function assignLoopEdges(obj, nodeIds, timeSlotIds)
            %ASSIGNLOOPEDGES Assign the loop edges over the node to a
            %given time-slot.
            
            obj.assignInputEdges(nodeIds, timeSlotIds, @iLoopEdges);
        end
        
        function assignInputEdges(obj, nodeIds, timeSlotIds, edgeSelector)
            %ASSIGNINPUTEDGES Assign the entering or loop edges to a node
            
            assert(numel(nodeIds)==numel(timeSlotIds), ...
                "The number of nodes and time-slots should be the same");
            
            arrayfun(@assignEnteringEdges, nodeIds, timeSlotIds, "UniformOutput", true);
            
            function assignEnteringEdges(currNode, currTag)
                enteringEdges = edgeSelector(obj.DataStructure, currNode);
                if ~isempty(enteringEdges)
                    obj.DataStructure.setTimeSlotOfEdge(enteringEdges, currTag);
                end
            end
        end
        
        function tf = hasLoopEdges(obj, nodeIds)
            %HASLOOPEDGES True for the input nodes that have loop edges
            %that can be scheduled.
            
            tf = arrayfun(@(x) ~isempty(iLoopEdges(obj.DataStructure, x)), ...
                nodeIds, "UniformOutput", true);
        end
        
    end
end

%% HELPER FUNCTIONS

function tf = iRow(dataIn)
tf = amsla.common.rowVector(dataIn);
end

function timeSlots = iExternal(edgeIds)
timeSlots = amsla.common.internal.externalTimeSlot(edgeIds);
end

function timeSlotId = iNextTimeSlot(timeSlotId)
timeSlotId = timeSlotId + 1;
timeSlotId(timeSlotId==0) = 1;
end

function edgeId = iLoopEdges(dataStructure, nodeId)
assert(isscalar(nodeId) && ~isempty(nodeId));

loopEdges = dataStructure.loopEdgesOfNode(nodeId);
if dataStructure.weightOfEdge(loopEdges)~=1
    edgeId = loopEdges;
else
    edgeId = [];
end
end