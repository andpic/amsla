classdef PartitioningResult
    %AMSLA.COMMON.PARTITIONINGRESULT Record the results of the partitioning
    %of a graph with the level-set algorithm.
    %
    %   Properties of PARTITIONINGRESULT:
    %       WasPartitioned          - True if the graph was correctly
    %                                 partitioned.
    
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
        
        % True if the graph was correctly partitioned.
        WasPartitioned
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = PartitioningResult(wasPartitioned)
            %PARTITIONINGRESULT Construct an object that records the result
            %of the partitioning using one of the implemented algorithms.
            %
            %   PARTITIONINGRESULT(W) Record that the graph was
            %   partitioned:
            %   - successfully/non-succesfully (W).
            
            obj.WasPartitioned = wasPartitioned;
        end
        
    end
    
end