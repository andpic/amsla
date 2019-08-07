classdef Analysis < handle
    %ANALYSIS Construct an object that carries out the analysis of a matrix
    %according to the level-set algorithm
    %
    %   Methods of Analysis:
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
    
    properties(Access=private)
        
        %GraphWrapper object that implements graph operations for the
        %level-set approach
        Graph
        
        %True if plots are enabled
        IsProducingPlot = false;
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = Analysis(varargin)
            %ANALYSIS Construct an object that executes the
            %analysis of a matrix according to the level-set algorithm.
            %
            % Use:
            %   A = ANALYSIS(I, J, V)
            %       Partition the sparse matrix defined by the arrays I, J,
            %       and V.
            %   A = ANALYSIS(__, 'Plot', true)
            %       Plot the progress of the partitioning algorithm.
            
            % Initialise the graph
            [I, J, V, obj.IsProducingPlot] = iParseConstructorArguments(varargin{:});
            obj.Graph = amsla.levelSet.internal.GraphWrapper(I, J, V);
        end
        
        function partition(obj)
            %PARTITION(A) Partition the graph according to the level-set
            %algorithm.
            
            if obj.IsProducingPlot
                progressPlotter = amsla.common.GraphPlotter;
                progressPlotter.plot(obj.Graph);
            end
            
            % Clear any previous tentative
            obj.Graph.resetAllAssignments();
            
            currentSubGraphId = 1;
            currentNodes = findRoots(obj.Graph);
            
            while ~isempty(currentNodes)
                % Assign nodes to sub-graphs
                obj.Graph.assignNodeToSubGraph(currentNodes, currentSubGraphId);
                if obj.IsProducingPlot
                    progressPlotter.plot(obj.Graph);
                end
                
                currentSubGraphId = currentSubGraphId+1;
                currentNodes = obj.Graph.childrenOfNodeReadyForAssignment(currentNodes);
            end
            
            assert(obj.Graph.checkFullAssignment(), "Partitioning was not succesful.");
        end
        
    end        
    
end


%% HELPER FUNCTIONS

function [I, J, V, isPlot] = iParseConstructorArguments(I, J, V, varargin)
parser = inputParser;
addRequired(parser,'I', @isnumeric);
addRequired(parser,'J', @isnumeric);
addRequired(parser,'V', @isnumeric);
addParameter(parser,'Plot', false, @islogical);

parse(parser, I, J, V, varargin{:});

I = parser.Results.I;
J = parser.Results.J;
V = parser.Results.V;
isPlot = parser.Results.Plot;
end
