classdef SchedulerGraphWrapper
    %AMSLA.COMMON.INTERNAL.SCHEDULERGRAPHWRAPPER Wraps a graph object to
    %carry out the scheduling of numerical operations.
    %
    %   W = AMSLA.COMMON.INTERNAL.SCHEDULERGRAPHWRAPPER(G) Create a wrapper
    %   for the graph G.
    %
    %   Methods of SchedulerGraphWrapper:
    %       scheduleOperations - Schedule the numerical operations in the
    %                            sparse matrix.
    
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
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = SchedulerGraphWrapper(aGraph)
            %SCHEDULERGRAPHWRAPPER Create a SchedulerGraphWrapper object.
            
            validateattributes(aGraph, ...
                {'amsla.common.DataStructureInterface'}, ...
                {'scalar', 'nonempty'});
            obj.Graph = aGraph;
        end
        
        function outIds = getRootsOfGraph(obj)
            %GETROOTSOFGRAPH Get the IDs of the nodes without a parent in 
            %the whole graph.
            
            allNodeIds = listOfNodes(obj.Graph);
            outIds = parentsOfNode(obj.Graph, allNodeIds);
            whichEmpty = arrayfun(@isempty, outIds, 'UniformOutput', true);
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
            %given nodes
            
            edgeIds = obj.Graph.enteringEdgesOfNode(nodeIds);
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
        
        
        function nodeIds = getReadyChildrenOfNode(obj, parentNodeIds)
            %GETREADYCHILDRENOFNODE Given a node, retrieve the list those of
            %its children whose entering edges have all been assigned.
            
            allChildrenIds = obj.Graph.childrenOfNode(parentNodeIds);
            if iscell(allChildrenIds)
                allChildrenIds = cell2mat(allChildrenIds);
            end
            
            readyNodes = arrayfun(@isNodeReady, allChildrenIds, ...
                "UniformOutput", true);
            nodeIds = allChildrenIds(readyNodes);
            
            function tf = isNodeReady(nodeIds)
                enteringEdgeIds =  obj.getEnteringEdges(nodeIds);
                timeSlotIds = obj.getTimeSlotOfEdge(enteringEdgeIds);
                tf = ~any(iIsNull(timeSlotIds));
            end
        end
        
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
        
        function timeSlotIds = getTimeSlotOfEdge(obj, edgeIds)
            %GETTIMESLOTOFEDGE Retrieve the time slot ID(s) with which the
            %input edges have been assigned.
            
            timeSlotIds = obj.Graph.timeSlotOfEdge(edgeIds);
        end
        
    end
    
end

%% HELPER FUNCTIONS

function tf = iIsNull(id)
tf = amsla.common.isNullId(id);
end