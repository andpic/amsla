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
        
        %Graph  Graph object representing a sparse matrix.
        Graph
        
        %UsesSubGraphs True if the graph is partitioned, meaning scheduling has
        %to take sub-graphs into consideration.
        UsesSubGraphs
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = Scheduler(aGraph)
            %SCHEDULER Create a scheduler object.
            
            validateattributes(aGraph, ...
                {'amsla.common.DataStructureInterface'}, ...
                {'scalar', 'nonempty'});
            obj.Graph = amsla.common.internal.SchedulerGraphWrapper(aGraph);
            obj.UsesSubGraphs = false;
        end
        
        function scheduleOperations(obj)
            %SCHEDULEOPERATIONS(A) Distribute the numerical operations over
            %time-slots
            
            % External edges
            currentNodes = getRootsBySubGraph(obj.Graph);
            if ~isempty(currentNodes)
                initialTimeSlot = -1;
                currentTimeSlot = 1;
                obj.UsesSubGraphs = true;
            else
                initialTimeSlot = 1;
                currentTimeSlot = 2;
                currentNodes = getRootsOfGraph(obj.Graph);
            end
            
            currentNodes = obj.Graph.getChildrenOfOnlyNodesInSet(currentNodes);
            currentNodes = obj.assignEnteringEdgesToTimeSlot(currentNodes, initialTimeSlot);
            
            % Internal edges
            while ~iAllEmpty(currentNodes)
                currentNodes = obj.assignEnteringEdgesToTimeSlot(currentNodes, currentTimeSlot);
                currentTimeSlot = currentTimeSlot + 1;
            end
        end
        
    end
    
    %% PRIVATE METHODS
    
    methods (Access=private)
        
        function currentNodes = assignEnteringEdgesToTimeSlot(obj, currentNodes, currentTimeSlot)
            % Assign the entering edges of 'currentNodes' to the time slot
            % 'currentTimeSlot'
                        
            currentEnteringEdges = obj.Graph.getEnteringEdges(currentNodes);
            
            if ~iAllEmpty(currentEnteringEdges)
                currentEnteringEdges = iCreateArray(currentEnteringEdges);
                obj.Graph.assignEdgesToTimeSlot(currentEnteringEdges, currentTimeSlot);
            end
            currentNodes = obj.getReadyChildrenOfNode(currentNodes);
        end
        
        function nodeIds = getReadyChildrenOfNode(obj, nodeIds)
            % Get the children of the nodes in nodeIds that are ready for
            % processing.
            
           if obj.UsesSubGraphs
               nodeIds = obj.Graph.getReadyChildrenOfNodeBySubGraph(nodeIds);
           else
               nodeIds = obj.Graph.getReadyChildrenOfNode(nodeIds);
           end               
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