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
        
        %Graph object representing a sparse matrix.
        DataStructure
        
        %Schedulers for sub-graphs
        SubGraphSchedulers
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = Scheduler(aGraph)
            %SCHEDULER Create a scheduler object.
            
            validateattributes(aGraph, ...
                {'amsla.common.DataStructureInterface'}, ...
                {'scalar', 'nonempty'});
            
            obj.DataStructure = aGraph;
        end
        
        function scheduleOperations(obj)
            %SCHEDULEOPERATIONS(A) Distribute the numerical operations over
            %time-slots
            
            allSubGraphs = obj.DataStructure.listOfSubGraphs();
            assert(~isempty(allSubGraphs) && ~any(iIsNullId(allSubGraphs)), ...
                "Cannot carry out the scheduling on the graph");
            
            numSubGraphs = numel(allSubGraphs);
            obj.SubGraphSchedulers = cell(1, numSubGraphs);
            for k = 1:numSubGraphs
                currSubGraph = allSubGraphs(k);
                obj.SubGraphSchedulers{k} = ...
                    amsla.common.internal.SubGraphScheduler(obj.DataStructure, currSubGraph);
            end
            
            cellfun(@scheduleOperations, obj.SubGraphSchedulers);
            
            assert(iAllEdgesAreAssigned(obj.DataStructure), ...
                "amsla:Scheduler:incompleteAssignment", ...
                "Not al edges were assigned to time-slots")
        end
    end
end

%% HELPER FUNCTIONS

function tf = iAllEdgesAreAssigned(dataStructure)

allEdges = dataStructure.listOfEdges();
% Corner case
if isempty(allEdges)
    tf = true;
    return;
end

enteringNodes = dataStructure.enteringNodeOfEdge(allEdges)';
exitingNodes = dataStructure.exitingNodeOfEdge(allEdges)';
weights = dataStructure.weightOfEdge(allEdges);
timeSlots = dataStructure.timeSlotOfEdge(allEdges);
timeSlots(enteringNodes==exitingNodes & weights==1) = [];

tf = ~any(amsla.common.isNullId(timeSlots));
end

function tf = iIsNullId(anId)
tf = amsla.common.isNullId(anId);
end