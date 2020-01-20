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
                amsla.common.findSubGraphLevels(aDataStructure);
            
        end
        
        function result = solve(obj, rhs)
            %SOLVE Solve a triangular linear system of equations.
            
            numLevels = obj.numberOfLevels();
            for currentLevel = 1:numLevels
                subGraphIds = obj.subGraphsInLevel(currentLevel);
                arrayfun(@(id) obj.traverseSubGraph(id, rhs), subGraphIds);
            end
            
        end
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
                
        function rhsComponent = traverseSubGraph(obj, subGraphId, rhs)
            %TRAVERSESUBGRAPH traverse the sub-graph of the 
                        
            timeSlotIds = obj.timeSlotsInSubGraph(subGraphId);
            for currentTimeSlot = timeSlotIds
                if amsla.common.internal.isExternalTimeSlot(currentTimeSlot)
                    
                else
                    
                end
            end
            
        end                
        
        function weights = weightsOfEdges(obj, subGraphId, timeSlotId)
            edgeIds = obj.DataStructure.edgesInSubGraphAndTimeSlot(subGraphId, timeSlotId);
            weights = obj.DataStructure.weightOfEdge(edgeIds);
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
        
        function numTimeSlots = timeSlotsInSubGraph(obj, subGraphId)
           %TIMESLOTSINSUBGRAPH Time-slots in the given sub-graph.
           
           numTimeSlots = obj.DataStructure.timeSlotsInSubGraph(subGraphId);
        end
    end
end
