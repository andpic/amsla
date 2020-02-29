classdef Scheduler < handle
    %AMSLA.COMMON.SCHEDULER An object that carries out the scheduling of the
    %numerical operations in a matrix.
    %
    %   S = AMSLA.COMMON.SCHEDULER(G) Create a scheduler object to operate
    %   on the sparse matrix represented by the graph G.
    %
    %   Methods of Scheduler:
    %       scheduleOperations - Schedule the numerical operations in the
    %                            sparse matrix.
    
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
        
        %Graph  Graph object representing a sparse matrix.
        Graph
        
        %IsGraphPartitioned True if the graph is partitioned, meaning
        %scheduling has to take sub-graphs into consideration.
        IsGraphPartitioned
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = Scheduler(aGraph)
            %SCHEDULER Create a scheduler object.
            
            validateattributes(aGraph, ...
                {'amsla.common.DataStructureInterface'}, ...
                {'scalar', 'nonempty'});
            obj.Graph = amsla.common.internal.SchedulerGraphWrapper(aGraph);
            obj.IsGraphPartitioned = false;
        end
        
        function scheduleOperations(obj)
            %SCHEDULEOPERATIONS(A) Distribute the numerical operations over
            %time-slots
            
            currentNodes = obj.getRoots();
            
            % ExternalEdges
            obj.assignExternalEdges();
            
            % Internal edges
            currentTimeSlot = 1;
            while ~iAllEmpty(currentNodes)
                [currentNodes, currentTimeSlot] = ...
                    obj.assignInternalEdgesToTimeSlot(currentNodes, currentTimeSlot);
            end
            
            assert(obj.Graph.areAllEdgesAssigned(), ...
                "amsla:Scheduler:incompleteAssignment", ...
                "Not al edges were assigned to time-slots")
        end
        
    end
    
    %% PRIVATE METHODS
    
    methods (Access=private)
        
        function [currentNodes, currentTimeSlot] = assignInternalEdgesToTimeSlot(obj, currentNodes, currentTimeSlot)
            % Assign the internal entering edges of 'currentNodes' to the
            % time slot 'currentTimeSlot'
            
            currentEnteringEdges = obj.Graph.getEnteringInternalEdges(currentNodes);
            currentTimeSlot = obj.assignEdgesToTimeSlot(currentEnteringEdges, currentTimeSlot);
            
            loopingEdges = obj.Graph.getLoopingEdges(currentNodes);
            currentTimeSlot = obj.assignEdgesToTimeSlot(loopingEdges, currentTimeSlot);
            
            obj.Graph.markNodeAsProcessed(currentNodes);
            currentNodes = obj.getReadyChildrenOfNode(currentNodes);
        end
        
        function nodeIds = getReadyChildrenOfNode(obj, nodeIds)
            % Get the children of the nodes in nodeIds that are ready for
            % processing.
            
            if obj.IsGraphPartitioned
                nodeIds = obj.Graph.getReadyChildrenOfNodeBySubGraph(nodeIds);
            else
                nodeIds = obj.Graph.getReadyChildrenOfNode(nodeIds);
            end
        end
        
        function newTimeSlot = assignEdgesToTimeSlot(obj, edgesId, timeSlotId)
            % Assign the given edges to a time slot
            
            if ~iAllEmpty(edgesId)
                edgesId = iCreateArray(edgesId);
                obj.Graph.assignEdgesToTimeSlot(edgesId, timeSlotId);
                newTimeSlot = timeSlotId + 1;
            else
                newTimeSlot = timeSlotId;
            end
        end
        
        function nodeIds = getRoots(obj)
            % Get all the roots in the graph, by sub-graph if the graph is
            % partitioned.
            
            currentNodes = getRootsBySubGraph(obj.Graph);
            if ~isempty(currentNodes)
                obj.IsGraphPartitioned = true;
                nodeIds = iCreateArray(currentNodes);
            else
                nodeIds = getRootsOfGraph(obj.Graph);
            end
            
        end
        
        function assignExternalEdges(obj)
            % Assign all the external edges in the graph.
            
            if ~obj.IsGraphPartitioned
                return;
            end
            
            externalEdgeIds = getAllExternalEdges(obj.Graph);
            obj.Graph.assignEdgesToTimeSlot(externalEdgeIds, ...
                amsla.common.internal.externalTimeSlot(1));
        end
        
    end
end

%% HELPER FUNCTIONS

function tf = iAllEmpty(array)
% Check that all cells of an array of cells are empty.
if iscell(array)
    tf = all(cellfun(@isempty, array, "UniformOutput", true));
else
    tf = all(isempty(array));
end
end

function array = iCreateArray(cells)
% Convert a cell array to an array
if iscell(cells)
    array = cell2mat(cells);
else
    array = cells;
end
end