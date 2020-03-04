classdef Partitioner < amsla.common.PartitionerInterface
    %AMSLA.TASSL.PARTITIONER Construct an object that carries out the
    %partitioning of a graph using the TASSL algorithm.
    %
    %   P = AMSLA.TASSL.PARTITIONER(G, MAXSIZE) Create a partitioner for the
    %   graph G and request that the maximum size of sub-graphs is MAXSIZE.
    %
    %   Methods of Partitioner:
    %       partition        - Partitions the matrix according to the TASSL
    %                          algorithm.
    
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
    
    properties(Access=private)
        
        %Object that implements graph operations for the TASSL approach
        GraphWrapper
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = Partitioner(varargin)
            %PARTITIONER Construct an object that executes the
            %analysis of a matrix according to the TASSL algorithm.
            
            obj@amsla.common.PartitionerInterface(varargin{:});
            
            maxSubGraphSize = obj.getMaxSubGraphSize();
            assert(isscalar(maxSubGraphSize) && maxSubGraphSize>0, ...
                "amsla:tassl:Partitioner", ...
                "Bad sub-graph size for the TASSL partitioner");
            
            obj.GraphWrapper = amsla.tassl.internal.PartitionerGraphWrapper( ...
                obj.getGraphToPartition(), ...
                maxSubGraphSize);
        end
        
        function partitioningResult = partition(obj)
            %PARTITION(A) Partition the graph according to the TASSL
            %algorithm.
            
            tentativeNumber = 0;
            isSuccesful = false;
            
            while ~isSuccesful && tentativeNumber<=50
                tentativeNumber = tentativeNumber + 1;
                [criterion, density] = iSetNewTentative(tentativeNumber);
                isSuccesful = obj.tentativePartitioning(criterion, density);
            end
            
            % Writing out the result
            partitioningResult = amsla.tassl.PartitioningResult(...
                isSuccesful, tentativeNumber, criterion, density);
            if ~isSuccesful
                error("amsla:couldNotPartition", ...
                    "Could not partition the given matrix.");
            end
        end
        
    end
    
    %% PRIVATE METHODS
    
    methods (Access=private)
        
        function isSuccessful = tentativePartitioning(obj, criterion, density)
            % Try partitioning the graph given a node sorting criterion and
            % an initial sub-graph density.
            
            obj.updateProgressPlot();
            
            % Clear any previous tentative
            obj.GraphWrapper.resetAllAssignments();
            
            % Set sorting criterion
            obj.GraphWrapper.setSortingCriterion(criterion);
            
            % Initialise tentative with root nodes
            [nodeIds, subGraphIds] = obj.GraphWrapper.distributeRootsToSubGraphs(density);
            
            % Loop until all nodes have been checked
            isSuccessful = true;
            while ~isempty(nodeIds)
                try
                    % Assign nodes to sub-graphs
                    obj.GraphWrapper.assignNodeToSubGraph(nodeIds, subGraphIds);
                    obj.updateProgressPlot();
                    
                    % Get new nodes for assignment
                    [nodeIds, subGraphIds] = obj.GraphWrapper.childrenOfNodeReadyForAssignment(nodeIds);
                catch matlabException
                    if iCheckExceptionForNextTentative(matlabException)
                        % If an error is thrown to execute a new tentative,
                        % exit now.
                        isSuccessful = false;
                        obj.GraphWrapper.resetAllAssignments();
                        break;
                    else
                        rethrow(matlabException);
                    end
                end
            end
            
            % If it got to the end of the loop, check that the assignment is
            % complete or that the assignment makes sense.
            assert( ...
                (isSuccessful && obj.GraphWrapper.checkFullAssignment()) || ...
                (~isSuccessful && ~obj.GraphWrapper.checkFullAssignment()), ...
                "Inconsistent result of the tentative to partition the graph.");
        end
        
    end
    
end


%% HELPER FUNCTIONS

function [criterion, density] = iSetNewTentative(tentativeNumber)
% List of available sorting criterion and density
sortingCriterionList = [ ...
    "descend outdegree", ...
    "ascend outdegree", ...
    "descend indegree", ...
    "ascend indegree", ...
    "descend index" ...
    ];
numSortingCriteria = numel(sortingCriterionList);
densityList = 2.^(-(0:1:8));
numDensity = numel(densityList);

assert(tentativeNumber<=numSortingCriteria*numDensity, "Cannot partition the graph. No more sorting criteria or densities to try.");

% Pick density and sorting criterion
density = densityList(mod(tentativeNumber-1, numDensity)+1);
criterion = sortingCriterionList(floor((tentativeNumber-1)/numDensity)+1);

end

function nextTentative = iCheckExceptionForNextTentative(matlabException)
nextTentative = strcmp(matlabException.identifier, "amsla:badSubGraph");
end
