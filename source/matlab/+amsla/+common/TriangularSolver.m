classdef TriangularSolver
    %AMSLA.COMMON.TRIANGULARSOLVER A triangular solver for the AMSLA
    %framework.
    %
    %   S = AMSLA.COMMON.TRIANGULARSOLVER(M) Create triangular solver for the
    %   sparse matrix M.
    
    % Copyright 2020 Andrea Picciau
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
        
        % Correspondence between sub-graphs and sub-graph levels for the
        % given matrix.
        SubGraphLevelsTable
        
        % Data structure of the matrix being used to solve the system.
        DataStructure
        
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = TriangularSolver(aDataStructure)
            %TRIANGULARSOLVER Construct a triangular solver object.
            
            validateattributes(aDataStructure, ...
                {'amsla.common.DataStructure'}, ...
                {'scalar', 'nonempty'});
            obj.SubGraphLevelsTable =  ...
                amsla.common.internal.findSubGraphLevels(aDataStructure);
            obj.DataStructure = aDataStructure;
        end
        
        function result = solve(obj, rhs)
            %SOLVE Solve a triangular linear system of equations.
            
            result = rhs;
            
            numLevels = obj.numberOfLevels();
            for currentLevel = 1:numLevels
                subGraphIds = obj.subGraphsInLevel(currentLevel);
                allResults = arrayfun(@(id) obj.traverseSubGraph(id, result), ...
                    subGraphIds, ...
                    'UniformOutput', false);
                result = iUpdateVectorElements(result, allResults);
            end
            
        end
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
        
        function result = traverseSubGraph(obj, subGraphId, rhs)
            % Traverse a given sub-graph time-slot by time-slot.
            
            % Find the time-slots for the current sub-graph.
            timeSlotIds = obj.timeSlotsInSubGraph(subGraphId);
            
            % Initialise result with the right-hand side.
            result = rhs;
            
            numTimeSlots = numel(timeSlotIds);
            for k = 1:numTimeSlots
                currentTimeSlot = timeSlotIds(k);
                
                % Get the data of edges
                [enteringNodes, exitingNodes, weights] = ...
                    obj.dataOfEdges(subGraphId, currentTimeSlot);
                uniqueEnteringNodes = unique(enteringNodes);
                
                allResults = arrayfun(@(x) nIterateOverEnteringNodes(x, result), ...
                    uniqueEnteringNodes, ...
                    'UniformOutput', false);
                result = iUpdateVectorElements(result, allResults);
            end
            
            function result = nIterateOverEnteringNodes(currNode, result)
                % Iterate over the entering edges of a node (equivalent
                % to the elements in a given row in the matrix).
                relevantEdges = find(enteringNodes==currNode);
                
                currRow = currNode;
                relevantColumns = exitingNodes(relevantEdges);
                relevantWeights = weights(relevantEdges);
                
                result(currRow) = result(currRow)-sum(...
                    relevantWeights.*result(relevantColumns), ...
                    'all');
            end
        end
        
        function [enteringNodes, exitingNodes, weights] = dataOfEdges(obj, subGraphId, timeSlotId)
            %DATAOFEDGES Retrieve the data of the edges in the given sub-graph
            %and time-slot.
            
            edgeIds = obj.DataStructure.edgesInSubGraphAndTimeSlot(subGraphId, timeSlotId);
            weights = obj.DataStructure.weightOfEdge(edgeIds);
            exitingNodes = obj.DataStructure.enteringNodeOfEdge(edgeIds);
            enteringNodes = obj.DataStructure.exitingNodeOfEdge(edgeIds);
        end
        
        function subGraphIds = subGraphsInLevel(obj, levelId)
            %SUBGRAPHSINLEVEL Retrieve the IDs of the sub-graphs in a given
            %sub-graph level.
            
            isLevel = obj.SubGraphLevelsTable.SubGraphLevel==levelId;
            subGraphIds = obj.SubGraphLevelsTable.SubGraphId(isLevel);
        end
        
        function numLevels = numberOfLevels(obj)
            %NUMBEROFLEVELS Number of sub-graph levels.
            
            numLevels = numel(unique(obj.SubGraphLevelsTable.SubGraphLevel));
        end
        
        function timeSlotIDs = timeSlotsInSubGraph(obj, subGraphId)
            %TIMESLOTSINSUBGRAPH Time-slots in the given sub-graph.
            
            timeSlotIDs = obj.DataStructure.timeSlotsInSubGraph(subGraphId);
        end
    end
end

%% HELPER FUNCTIONS

function outData = iUpdateVectorElements(initialValue, currentResults)
% Updates a vector (initialValue) given multiple results (currentResults).

validateattributes(initialValue, {'numeric'}, {'nonempty', 'vector'});
validateattributes(currentResults, {'cell'}, {'nonempty'});

currentResults = cell2mat(reshape(currentResults, 1, []));
currentResultsSize = size(currentResults);
initialValueSize = size(initialValue);

if any(currentResultsSize==1)
    outData = currentResults;
else
    whichChanged = currentResults~=initialValue;
    [rowIndices, colIndices] = find(whichChanged);
    elementIndices = sub2ind(size(currentResults), rowIndices, colIndices);
    
    outData = initialValue;
    
    % Corner case: nothing to change, return initialValue.
    if isempty(elementIndices)
        return;
    end
    
    if initialValueSize(2)~=1
        % initialValue is a row vector: index by column.
        outData(colIndices) = currentResults(elementIndices);
    else
        % initialValue is not a row vector: index by row.
        outData(rowIndices) = currentResults(elementIndices);
    end
end
end