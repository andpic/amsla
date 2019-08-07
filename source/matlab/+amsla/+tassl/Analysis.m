classdef Analysis < handle
    %ANALYSIS Construct an object that carries out the analysis of a matrix
    %according to the TASSL algorithm
    %
    %   Methods of Analysis:
    %       partition        - Partitions the matrix according to the TASSL
    %                          algorithm.
    
    % Copyright 2018 Andrea Picciau
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
        
        %GraphWrapper object that implements graph operations for the TASSL
        %approach
        Graph
        
        %True if plots are enabled
        IsProducingPlot = false;
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = Analysis(varargin)
            %ANALYSIS Construct an object that executes the
            %analysis of a matrix according to the TASSL algorithm.
            %
            % Use:
            %   A = ANALYSIS(I, J, V)
            %       Partition the sparse matrix defined by the arrays I, J,
            %       and V.
            %   A = ANALYSIS(__, S)
            %       Set the maximum number of vertices in a sub-graph to S.
            %   A = ANALYSIS(__, 'Plot', true)
            %       Plot the progress of the partitioning algorithm.
            
            % Initialise the graph
            [I, J, V, maxSubGraph, obj.IsProducingPlot] = iParseConstructorArguments(varargin{:});
            obj.Graph = amsla.tassl.internal.GraphWrapper(I, J, V, maxSubGraph);
        end
        
        function partition(obj)
            %PARTITION(A) Partition the graph according to the TASSL
            %algorithm.
            
            tentativeNumber = 1;
            isSuccesful = false;
            
            while ~isSuccesful
                [criterion, density] = iSetNewTentative(tentativeNumber);
                fprintf("%d === Criterion: %s, Density %.3f\n", tentativeNumber, criterion, density);
                isSuccesful = obj.tentativePartitioning(criterion, density);
                tentativeNumber = tentativeNumber + 1;
            end
        end
        
    end
    
    %% PRIVATE METHODS
    
    methods (Access=private)
        
        function isSuccessful = tentativePartitioning(obj, criterion, density)
            % Try partitioning the graph given a node sorting criterion and
            % an initial sub-graph density.
            
            if obj.IsProducingPlot
                progressPlotter = amsla.common.GraphPlotter;
                progressPlotter.plot(obj.Graph);
            end
            
            % Clear any previous tentative
            obj.Graph.resetAllAssignments();
            
            % Set sorting criterion
            obj.Graph.setSortingCriterion(criterion);
            
            % Initialise tentative with root nodes
            [nodeIds, subGraphIds] = obj.Graph.distributeRootsToSubGraphs(density);
            
            % Loop until all nodes have been checked
            isSuccessful = true;
            while ~isempty(nodeIds)
                try
                    % Assign nodes to sub-graphs
                    obj.Graph.assignNodeToSubGraph(nodeIds, subGraphIds);
                    if obj.IsProducingPlot
                        progressPlotter.plot(obj.Graph);
                    end
                    
                    % Get new nodes for assignment
                    [nodeIds, subGraphIds] = obj.Graph.childrenOfNodeReadyForAssignment(nodeIds);
                catch matlabException
                    if iCheckExceptionForNextTentative(matlabException)
                        % If an error is thrown to execute a new tentative,
                        % exit now.
                        isSuccessful = false;
                        obj.Graph.resetAllAssignments();
                        break;
                    else
                        rethrow(matlabException);
                    end
                end
            end
            
            % If it got to the end of the loop, check that the assignment is
            % complete or that the assignment makes sense.
            assert( ...
                (isSuccessful && obj.Graph.checkFullAssignment()) || ...
                (~isSuccessful && ~obj.Graph.checkFullAssignment()), ...
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

function [I, J, V, maxSubGraph, isPlot] = iParseConstructorArguments(I, J, V, varargin)
parser = inputParser;
addRequired(parser,'I', @isnumeric);
addRequired(parser,'J', @isnumeric);
addRequired(parser,'V', @isnumeric);
addOptional(parser,'maxSubGraph', 10, @isnumeric);
addParameter(parser,'Plot', false, @islogical);

parse(parser, I, J, V, varargin{:});

I = parser.Results.I;
J = parser.Results.J;
V = parser.Results.V;
maxSubGraph = parser.Results.maxSubGraph;
isPlot = parser.Results.Plot;
end
