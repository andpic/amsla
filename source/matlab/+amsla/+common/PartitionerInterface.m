classdef(Abstract) PartitionerInterface < handle
    %AMSLA.COMMON.PARTITIONERINTERFACE Interface for an object that carries out the
    %partitioning of a graph.
    %
    %   Methods of PartitionerInterface:
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
    
    %% PROPERTIES
    
    properties(Access=private)
        
        %Handle to the graph being partitioned
        Graph
        
        %Maximum allowed number of vertices in a sub-graph
        MaxSubGraphSize
        
        %Progress plot manager.
        ProgressPlotter
        
        %True if a plot of the partitioning algorithm is to be generated
        IsPlottingProgress
        
    end
    
    %% PUBLIC METHODS
    
    methods(Abstract)
        
        % Partition the graph
        partitioningResult = partition(obj)
        
    end
    
    %% PROTECTED METHODS
    
    methods(Access=public)
        
        function obj = PartitionerInterface(varargin)
            %PARTITIONERINTERFACE Class constructor.
            
            [obj.Graph, obj.MaxSubGraphSize, obj.IsPlottingProgress] = ...
                iParseConstructorArguments(varargin{:});
            if obj.IsPlottingProgress
                obj.ProgressPlotter = amsla.common.internal.GraphPlotter();
            end
        end
        
        function aGraph = getGraphToPartition(obj)
            %GETGRAPHTOPARTITION Get a handle to the graph that is to be
            %partitioned.
            
            aGraph = obj.Graph;
        end
        
        function maxSize = getMaxSubGraphSize(obj)
            %GETMAXSUBGRAPHSIZE Get the requested maximum sub-graph.
            
            maxSize = obj.MaxSubGraphSize;
        end
        
        function updateProgressPlot(obj)
            %UPDATEPROGRESSPLOT Plot or update the plot of the partitioned
            %graph.
            
            if obj.IsPlottingProgress
                obj.ProgressPlotter.plot(obj.Graph);
            end
        end
        
    end
end

%% HELPER FUNCTIONS

function [aGraph, maxSubGraph, isPlottingProgress] = iParseConstructorArguments(varargin)
parser = inputParser;
addRequired(parser,'Graph', @(x) isa(x, "amsla.common.DataStructureInterface") && isscalar(x));
addOptional(parser,'MaxSubGraph', 10, @isnumeric);
addParameter(parser,'PlotProgress', false, @islogical);

parse(parser, varargin{:});

aGraph = parser.Results.Graph;
maxSubGraph = parser.Results.MaxSubGraph;
isPlottingProgress = parser.Results.PlotProgress;
end