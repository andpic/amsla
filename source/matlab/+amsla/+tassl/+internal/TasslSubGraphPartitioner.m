classdef TasslSubGraphPartitioner < handle
    %AMSLA.TASSL.INTERNAL.TASSLSUBGRAPHPARTITIONER Partition a DataStructure
    %into sub-graphs according to the algorithm in [Picciau2017].
    
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
    
    %% PRIVATE PROPERTIES
    
    properties(Access=private)
        
        % Implementation of the partitioning algorithm depending on the
        % number of nodes in a component.
        Impl
        
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = TasslSubGraphPartitioner(dataStructure, maxSize, componentId)
            %TASSLSUBGRAPHPARTITIONER(G) Construct a
            %TasslSubGraphPartitioner and partition the input DataStructure
            %object.
            
            validateattributes(dataStructure, {'amsla.tassl.internal.ComponentDecorator'}, ...
                {'scalar', 'nonempty'});
            
            [compIds, compSizes] = dataStructure.listOfComponents();
            currCompSize = compSizes(compIds == componentId);
            
            if currCompSize<=maxSize
                obj.Impl = amsla.tassl.internal.TasslSubGraphPartitionerSmallComponent( ...
                    dataStructure, maxSize, componentId);
            else
                obj.Impl = amsla.tassl.internal.TasslSubGraphPartitionerLargeComponent( ...
                    dataStructure, maxSize, componentId);
            end
        end
        
        function numSubGraphs = numberOfSubGraphs(obj)
            %NUMBEROFSUBGRAPHS Retrieve the number of sub-graphs the current
            %component was split into.
            
            numSubGraphs = obj.Impl.NumSubGraphs;
        end
        
        function executeAlgorithm(obj)
            %EXECUTEALGORITHM execute the partitioning of a large component.
            
            if isa(obj.Impl, "amsla.tassl.internal.TasslSubGraphPartitionerLargeComponent")
                obj.executeAlgorithm();
            end
        end
        
        function renumberSubGraphsStartingFrom(obj, startingFrom)
            %RENUMBERSUBGRAPHSSTARTINGFROM Renumber the sub-graphs to start
            %from a specific ID.
            
            obj.Impl.renumberSubGraphsStartingFrom(startingFrom);
        end
        
    end
    
end