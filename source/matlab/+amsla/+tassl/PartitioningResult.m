classdef PartitioningResult < amsla.common.PartitioningResult
    %AMSLA.TASSL.PARTITIONINGRESULT Record the results of the partitioning
    %of a graph with the TASSL algorithm.
    %
    %   Properties of PARTITIONINGRESULT:
    %       WasPartitioned          - True if the graph was correctly
    %                                 partitioned.
    %       NumberOfTentatives      - Number of partitioning tentatives.
    %       FinalCriterion          - Partitioning criterion used.
    %       RootNodeDensity         - Root nodes per obtained sub-graphs.
    
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
    
    properties(GetAccess=public,SetAccess=immutable)        
        
        % Number of partitioning tentatives.
        NumberOfTentatives
        
        % Partitioning criterion used.
        FinalCriterion
        
        % Root nodes per obtained sub-graphs.
        RootNodeDensity
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = PartitioningResult(wasPartitioned, numberOfTentatives, finalCriterion, rootNodeDensity)
            %PARTITIONINGRESULT Construct an object that records the result
            %of the partitioning using TASSL's algorithm.
            %
            %   PARTITIONINGRESULT(W,N,F,R) Record that the graph was
            %   partitioned:
            %   - successfully/non-succesfully (W),
            %   - after N tentatives,
            %   - using the criterion F,
            %   - with R root nodes per obtained sub-graph.
            
            obj = obj@amsla.common.PartitioningResult(wasPartitioned);
            obj.NumberOfTentatives = numberOfTentatives;
            obj.FinalCriterion = finalCriterion;
            obj.RootNodeDensity = rootNodeDensity;
        end
        
    end
    
end