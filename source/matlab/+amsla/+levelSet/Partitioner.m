classdef Partitioner < amsla.common.PartitionerInterface
    %AMSLA.LEVELSET.PARTITIONER Construct an object that carries out the
    %partitioning of a matrix according to the level-set algorithm
    %
    %   A = PARTITIONER(G, []) Partition the sparse matrix defined by the
    %   EnhancedGraph object G.
    %
    %   A = PARTITIONER(__, 'Plot', true) Plot the progress of the
    %   partitioning algorithm.
    %
    %   Methods of Partitioner:
    %       partition        - Partitions the matrix according to the
    %                          level-set algorithm.
    
    % Copyright 2019 Andrea Picciau
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
        
        %An bject that implements graph operations for the level-set approach
        GraphWrapper
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = Partitioner(varargin)
            %PARTITIONER Construct an object that executes the
            %analysis of a matrix according to the level-set algorithm.
            
            obj@amsla.common.PartitionerInterface(varargin{:});
            
            if ~isempty(obj.getMaxSubGraphSize())
                warning("amsla:levelSet:sizeIgnored", ...
                    "The level-set algorithm does not enforce a maximum sub-graph size. Input will be ignored.");
            end
            
            % Initialise the graph wrapper
            obj.GraphWrapper = ...
                amsla.levelSet.internal.PartitionerGraphWrapper(obj.getGraphToPartition());
        end
        
        function partitioningResult = partition(obj)
            %PARTITION(A) Partition the graph according to the level-set
            %algorithm.
            
            obj.updateProgressPlot();
            
            % Clear any previous tentative
            obj.GraphWrapper.resetAllAssignments();
            
            currentSubGraphId = 1;
            currentNodes = findRoots(obj.GraphWrapper);
            
            while ~isempty(currentNodes)
                % Assign nodes to sub-graphs
                obj.GraphWrapper.assignNodeToSubGraph(currentNodes, currentSubGraphId);
                obj.updateProgressPlot();
                
                currentSubGraphId = currentSubGraphId+1;
                currentNodes = obj.GraphWrapper.childrenOfNodeReadyForAssignment(currentNodes);
            end
            
            partitioningResult = ...
                amsla.common.PartitioningResult(obj.GraphWrapper.checkFullAssignment());
        end
        
    end
    
end
