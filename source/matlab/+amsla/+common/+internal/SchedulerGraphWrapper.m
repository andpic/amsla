classdef SchedulerGraphWrapper < handle
    %AMSLA.COMMON.INTERNAL.SCHEDULERGRAPHWRAPPER Wraps a graph object to
    %carry out the scheduling of numerical operations.
    %
    %   W = AMSLA.COMMON.INTERNAL.SCHEDULERGRAPHWRAPPER(G) Create a wrapper
    %   for the graph G.
    %
    %   Methods of SchedulerGraphWrapper:
    %       areAllEdgesAssigned         - Get a list of nodes in the graph.
    %       getRootsOfGraph             - Get the roots in the graph object.
    %       getRootsBySubGraph          - Get the roots by sub-graph.
    %       getEnteringInternalEdges    - Get the internal entering edges of
    %                                     a node.
    %       getAllExternalEdges         - Get all the external edges in the
    %                                     sub-graph.
    %       getLoopingEdges             - Get the edges looping over a node.
    %       assignEdgesToTimeSlot       - Assign edges to time slot.
    %       markNodeAsProcessed         - Mark given nodes as processed.
    %       getReadyChildrenOfNode           - Get the children of a node whose
    %                                          entering edges have been assigned.
    %       getReadyChildrenOfNodeBySubGraph - Get the children of a node in the
    %                                          same sub-graph, if all the entering
    %                                          entering edges have been assigned.
    
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
        
        function edgeIds = getEnteringInternalEdges(obj, nodeIds)
            %GETENTERINGINTERNALEDGES Retrieve the IDs of the internal and
            %non-looping edges entering the given nodes.
            
            edgeIds = obj.Graph.enteringEdgesOfNode(nodeIds);
            if iscell(edgeIds)
                edgeIds = cell2mat(edgeIds);
            end
            isInternal = ~obj.isExternalEdge(edgeIds);
            edgeIds = edgeIds(isInternal);
        end
        
        function edgeIds = getAllExternalEdges(obj)
            %GETALLEXTERNALEDGES Get the IDs of all the external edges in
            %the graph.
            
            allEdgeIds = obj.Graph.listOfEdges();
            isExternalEdge = obj.isExternalEdge(allEdgeIds);
            
            edgeIds = allEdgeIds(isExternalEdge);
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
                @(x) obj.getChildrenOfNode(x), ...
                @(x) obj.isNodeReady(x));
        end
        
        function nodeIds = getReadyChildrenOfNodeBySubGraph(obj, parentNodeIds)
            %GETREADYCHILDRENOFNODEBYSUBGRAPH Given a node, retrieve the list
            %of its children in the same sub-graph whose entering edges have
            %all been assigned.
            
            nodeIds = obj.getReadyChildrenBySelector(parentNodeIds, ...
                @(x) obj.getChildrenOfNodeBySubGraph(x), ...
                @(x) obj.isNodeInSubGraphReady(x));
        end
        
        function tf = areAllEdgesAssigned(obj)
            %ALLEDGESAREASSIGNED Returns true if all the edges in the
            %sub-graphs were assigned to time-slots.
            
            allEdges = obj.Graph.listOfEdges();
            % Corner case
            if isempty(allEdges)
                tf = true;
                return;
            end
            
            enteringNodes = obj.Graph.enteringNodeOfEdge(allEdges)';
            exitingNodes = obj.Graph.exitingNodeOfEdge(allEdges)';
            weights = obj.Graph.weightOfEdge(allEdges);
            timeSlots = obj.Graph.timeSlotOfEdge(allEdges);
            timeSlots(enteringNodes==exitingNodes & weights==1) = [];
            
            tf = ~any(amsla.common.isNullId(timeSlots));
        end
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
        
        function timeSlotIds = getTimeSlotOfEdge(obj, edgeIds)
            %GETTIMESLOTOFEDGE Retrieve the time slot ID(s) with which the
            %input edges have been assigned.
            
            timeSlotIds = obj.Graph.timeSlotOfEdge(edgeIds);
        end
        
        function tf = isExternalEdge(obj, edgeIds)
            %ISEXTERNALEDGE True if the edge ID refers to an external edge.
            
            if isempty(edgeIds)
                tf = [];
                return;
            end
            
            [entering, exiting] = nodesOfEdge(obj, edgeIds);
            
            enteringNodeSubGraphs = obj.Graph.subGraphOfNode(entering);
            exitingNodeSubGraphs = obj.Graph.subGraphOfNode(exiting);
            
            tf = enteringNodeSubGraphs~=exitingNodeSubGraphs & ...
                ~amsla.common.isNullId(enteringNodeSubGraphs) & ...
                ~amsla.common.isNullId(exitingNodeSubGraphs);
        end
        
        function tf = isLoopingEdge(obj, edgeIds)
            %ISLOOPINGEDGE True if the edge ID refers to a looping edge.
            
            if isempty(edgeIds)
                tf = [];
                return;
            end
            
            [entering, exiting] = nodesOfEdge(obj, edgeIds);
            tf = entering==exiting;
        end
        
        function nodeIds = getReadyChildrenBySelector(obj, parentNodeIds, ...
                childSelector, readinessEvaluator) %#ok<INUSL>
            %GETREADYCHILDRENBYSELECTOR Get the children that are ready
            %using a specific criterion for selection. Common logic for the
            %"getReadyChildrenOfNode***" methods.
            
            childrenNodes = childSelector(parentNodeIds);
            if iscell(childrenNodes)
                childrenNodes = cell2mat(childrenNodes);
            end
            isNodeReady = arrayfun(readinessEvaluator, childrenNodes, ...
                'UniformOutput', true);
            nodeIds = unique(childrenNodes(isNodeReady));
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
            %ISNODEREADY Tells whether a node is ready or not for processing
            % ignoring the graph's partitioning.
            
            parentNodes = obj.Graph.parentsOfNode(nodeIds);
            
            tf = all(obj.isNodeProcessed(parentNodes));
        end
        
        function tf = isNodeInSubGraphReady(obj, nodeIds)
            %ISNODEINSUBGRAPHREADY Tells whether a node is ready or not for
            %processing, considering the graph's partition.
            
            parentNodes = obj.Graph.parentsOfNode(nodeIds);
            subGraph = obj.Graph.subGraphOfNode(nodeIds);
            parentSubGraphs = obj.Graph.subGraphOfNode(parentNodes);
            
            parentsInSameSubGraph = parentNodes(parentSubGraphs==subGraph);
            tf = all(obj.isNodeProcessed(parentsInSameSubGraph));
        end
        
        function tf = isNodeProcessed(obj, nodeIds)
            %ISNODEPROCESSED Check whether a node has been processed or not.
            
            tf = obj.ProcessedNodeMap.IsProcessed( ...
                ismember(obj.ProcessedNodeMap.NodeId, nodeIds));
        end
        
        
        function [enteringNodes, exitingNodes] = nodesOfEdge(obj, edgeIds)
            %NODESOFEDGE Get the entering and existing nodes of an edge.
            
            enteringNodes = obj.Graph.enteringNodeOfEdge(edgeIds);
            exitingNodes = obj.Graph.exitingNodeOfEdge(edgeIds);
        end
    end
end
