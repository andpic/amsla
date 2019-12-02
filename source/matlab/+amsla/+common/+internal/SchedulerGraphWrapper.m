classdef SchedulerGraphWrapper < handle
    %AMSLA.COMMON.INTERNAL.SCHEDULERGRAPHWRAPPER Wraps a graph object to
    %carry out the scheduling of numerical operations.
    %
    %   W = AMSLA.COMMON.INTERNAL.SCHEDULERGRAPHWRAPPER(G) Create a wrapper
    %   for the graph G.
    %
    %   Methods of SchedulerGraphWrapper:
    %       getRootsOfGraph         - Get the roots in the graph object.
    %       getRootsBySubGraph      - Get the roots by sub-graph.
    %       getEnteringEdges        - Get the entering edges of a node.
    %       getLoopingEdges         - Get the edges looping over a node.
    %       assignEdgesToTimeSlot   - Assign edges to time slot.
    %       markNodeAsProcessed     - Mark given nodes as processed.
    %       getReadyChildrenOfNode           - Get the children of a node whose
    %                                          entering edges have been assigned.
    %       getReadyChildrenOfNodeBySubGraph - Get the children of a node in the
    %                                          same sub-graph, if all the entering
    %                                          entering edges have been assigned.
    
    % Copyright 2018-2019 Andrea Picciau
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
    
    %% PROPERTIES
    
    properties(Access=private)
        
        %The graph associated with a sparse matrix.
        Graph
        
        %True if the node was processed
        ProcessedNodeMap
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = SchedulerGraphWrapper(aGraph)
            %SCHEDULERGRAPHWRAPPER Create a SchedulerGraphWrapper object.
            
            validateattributes(aGraph, ...
                {'amsla.common.DataStructureInterface'}, ...
                {'scalar', 'nonempty'});
            obj.Graph = aGraph;
            listOfNodes = aGraph.listOfNodes();
            obj.ProcessedNodeMap = table( ...
                reshape(listOfNodes, [numel(listOfNodes), 1]), ...
                false([numel(listOfNodes), 1]), ...
                'VariableNames', {'NodeId', 'IsProcessed'});
        end
        
        function outIds = getRootsOfGraph(obj)
            %GETROOTSOFGRAPH Get the IDs of the nodes without a parent in
            %the whole graph.
            
            allNodeIds = listOfNodes(obj.Graph);
            outIds = parentsOfNode(obj.Graph, allNodeIds);
            if iscell(outIds)
                whichEmpty = cellfun(@isempty, outIds, 'UniformOutput', true);
            else
                whichEmpty = arrayfun(@isempty, outIds, 'UniformOutput', true);
            end
            outIds = allNodeIds(whichEmpty);
        end
        
        function rootIds = getRootsBySubGraph(obj)
            %GETROOTSBYSUBGRAPH	Retrieve the root nodes in the graph,
            %organised by sub-graph.
            %
            % Use:
            %   R = GETROOTSBYSUBGRAPH(W)
            %       Retrieve the IDs of the nodes in the graph that do not
            %       have parents in the same sub-graph, organised by
            %       sub-graph.
            
            subGraphIds = obj.Graph.listOfSubGraphs();
            rootIds = obj.Graph.rootsOfSubGraph(subGraphIds);
        end
        
        function edgeIds = getEnteringEdges(obj, nodeIds)
            %GETENTERINGEDGES Retrieve the IDs of the edges entering the
            %given nodes.
            
            edgeIds = obj.Graph.enteringEdgesOfNode(nodeIds);
        end
        
        function edgeIds = getLoopingEdges(obj, nodeIds)
            %GETLOOPING Retrieve the IDs of the edges looping over a
            %node. Only the edges with a wegiht that is not 1 are
            %considered.
            
            edgeIds = obj.Graph.loopEdgesOfNode(nodeIds);
            edgeIds = edgeIds(obj.Graph.weightOfEdge(edgeIds)~=1);
        end
        
        function assignEdgesToTimeSlot(obj, edgeIds, timeSlotIds)
            %ASSIGNEDGESTOTIMESLOT Assign the given edges to the given time
            %slots.
            %
            % Use:
            %   ASSIGNEDGESTOTIMESLOT(W, EDGEID, TSLOTID)
            %       Assign the edges with IDs EDGEID to the time-slots with
            %       edged TSLOTID.
            
            obj.Graph.setTimeSlotOfEdge(edgeIds, timeSlotIds);
        end
        
        function markNodeAsProcessed(obj, nodeIds)
            %MARKNODEASPROCESSED Mark the node as processed and enable its
            %children to be processed.
            
            obj.ProcessedNodeMap.IsProcessed( ...
                ismember(obj.ProcessedNodeMap.NodeId, nodeIds)) = true;
        end
        
        function nodeIds = getReadyChildrenOfNode(obj, parentNodeIds)
            %GETREADYCHILDRENOFNODE Given a node, retrieve the list those of
            %its children whose entering edges have all been assigned.
            
            nodeIds = obj.getReadyChildrenBySelector(parentNodeIds, ...
                @(x) obj.getChildrenOfNode(x));
        end
        
        function nodeIds = getReadyChildrenOfNodeBySubGraph(obj, parentNodeIds)
            %GETREADYCHILDRENOFNODEBYSUBGRAPH Given a node, retrieve the list
            %of its children in the same sub-graph whose entering edges have
            %all been assigned.
            
            nodeIds = obj.getReadyChildrenBySelector(parentNodeIds, ...
                @(x) obj.getChildrenOfNodeBySubGraph(x));
        end
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
        
        function timeSlotIds = getTimeSlotOfEdge(obj, edgeIds)
            %GETTIMESLOTOFEDGE Retrieve the time slot ID(s) with which the
            %input edges have been assigned.
            
            timeSlotIds = obj.Graph.timeSlotOfEdge(edgeIds);
        end
        
        function nodeIds = getReadyChildrenBySelector(obj, parentNodeIds, childSelector)
            %GETREADYCHILDRENBYSELECTOR Get the children that are ready
            %using a specific criterion for selection. Common logic for the
            %"getReadyChildrenOfNode***" methods.
            
            childrenNodes = childSelector(parentNodeIds);
            if iscell(childrenNodes)
                childrenNodes = cell2mat(childrenNodes);
            end
            isNodeReady = arrayfun(@(x) obj.isNodeReady(x), childrenNodes, ...
                'UniformOutput', true);
            nodeIds = childrenNodes(isNodeReady);
        end
        
        function nodeIds = getChildrenOfNode(obj, parentNodeIds)
            %GETCHILDRENOFNODE Get the IDs of the children of a given
            %nodes.
            
            nodeIds = obj.Graph.childrenOfNode(parentNodeIds);
        end
        
        function nodeIds = getChildrenOfNodeBySubGraph(obj, parentNodeIds)
            %GETCHILDRENOFNODEBYSUBGRAPH Get the IDs of the children of given
            %nodes that are in the same sub-graph.
            
            subGraphIds = obj.Graph.subGraphOfNode(parentNodeIds);
            if any(amsla.common.isNullId(subGraphIds))
                error("amsla:SchedulerGraphWrapper:badSubGraphs", ...
                    "Not all nodes were assigned to sub-graphs. " + ...
                    "It's meaningless to look for the children of nodes by sub-graph.");
            end
            
            nodeIds = obj.Graph.childrenOfNode(parentNodeIds);
            if iscell(nodeIds)
                % Turn subGraphIds into a cell array with every cell
                % containing one repetition of the subGraphId per child.
                numChildren = cellfun(@numel, nodeIds, 'UniformOutput', true);
                subGraphIds = arrayfun(@(x, y) repmat(x, [1, y]), ...
                    subGraphIds, numChildren, ...
                    'UniformOutput', false);
                
                nodeIds = cell2mat(nodeIds);
                subGraphIds = cell2mat(subGraphIds);
            end
            
            if ~isempty(nodeIds)
                nodeSubGraphIds = obj.Graph.subGraphOfNode(nodeIds);
                nodeIds = nodeIds(nodeSubGraphIds == subGraphIds);
            end
        end
        
        function tf = isNodeReady(obj, nodeIds)
            %ISNODEREADY Given a ScheduleGraphWrapper method that selects
            %the edges, tells whether a node is ready or not for
            %processing.
            
            parentNodes = obj.Graph.parentsOfNode(nodeIds);
            tf = all(obj.isNodeProcessed(parentNodes));
        end
        
        function tf = isNodeProcessed(obj, nodeIds)
            %ISNODEPROCESSED Check whether a node has been processed or not.
            
            tf = obj.ProcessedNodeMap.IsProcessed( ...
                ismember(obj.ProcessedNodeMap.NodeId, nodeIds));
        end
    end
end