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
    
    %% PROTECTED PROPERTIES
    
    properties(GetAccess=protected, SetAccess=immutable)
        
        %The graph being partitioned.
        DataStructure        
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = Partitioner(dataStructure, varargin)
            %PARTITIONER Construct an object that executes the
            %analysis of a matrix according to the TASSL algorithm.
            
            obj@amsla.common.PartitionerInterface(varargin{:});
            
            obj.DataStructure = dataStructure;
            assert(isscalar(obj.MaxSubGraphSize) && obj.MaxSubGraphSize>0, ...
                "amsla:tassl:Partitioner", ...
                "Bad sub-graph size for the TASSL partitioner");
        end
        
        function partitioningResult = partition(obj)
            %PARTITION(A) Partition the graph according to the TASSL
            %algorithm.
            
            obj.updateProgressPlot();
            
            graph = amsla.tassl.internal.ComponentDecorator(obj.DataStructure);
            maxSubGraphSize = obj.MaxSubGraphSize;
            
            % Partition into components
            compPartitioner = amsla.tassl.internal.ComponentPartitioner(graph);
            obj.updateProgressPlot();
            
            compPartitioner.mergeComponents(maxSubGraphSize);
            obj.updateProgressPlot();
            
            % Partition into sub-graphs
            subGraphPartitioners = iGraphPartitioners(graph, maxSubGraphSize);
            cellfun(@partitionComponent, subGraphPartitioners);
            obj.updateProgressPlot();
            
            % Re-number sub-graphs
            numSubGraphs = cellfun(@numberOfSubGraphs, subGraphPartitioners, ...
                'UniformOutput', true);
            startingSubGraphs = iStartingSubGraphs(numSubGraphs);
            for k = 1:numel(subGraphPartitioners)
                subGraphPartitioners{k}.renumberSubGraphsStartingFrom(startingSubGraphs(k));
            end
            obj.updateProgressPlot();
            
            partitioningResult = amsla.common.PartitioningResult(true);
        end
        
    end
    
end

%% HELPER FUNCTIONS

function startingSubGraphs = iStartingSubGraphs(numSubGraphs)
startingSubGraphs = zeros(size(numSubGraphs));
startingSubGraphs(1) = 1;
for k = 2:numel(numSubGraphs)
    startingSubGraphs(k) = startingSubGraphs(k-1) + numSubGraphs(k-1);
end
end

function subGraphPartitioners = iGraphPartitioners(graph, maxSubGraphSize)
% Initialise sub-graphs
allComponents = graph.listOfComponents();
numComponents = numel(allComponents);
subGraphPartitioners = cell(numComponents, 1);
for k = 1:numComponents
    currComponent = allComponents(k);
    subGraphPartitioners{k} = ...
        amsla.tassl.internal.TasslSubGraphPartitioner( ...
        graph, maxSubGraphSize, currComponent);
end
end