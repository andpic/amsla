classdef(Sealed) SubGraphPartitionerSmallComponent < ...
        amsla.tassl.internal.SubGraphPartitionerImplInterface
    %AMSLA.TASSL.INTERNAL.SUBGRAPHPARTITIONERSMALLCOMPONENT Implementation of 
    %TASSL's partitioning algorithm for small components.
    
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
    
    properties(SetAccess=immutable, GetAccess=protected)
        
        % The graph being processed
        DataStructure
        
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = SubGraphPartitionerSmallComponent(dataStructure, maxSize, componentId)
            %SUBGRAPHPARTITIOENRSMALLCOMPONENT(G) For a small component, assign
            %all the nodes to the same sub-graph.
            
            obj = obj@amsla.tassl.internal.SubGraphPartitionerImplInterface( ...
                dataStructure, maxSize, componentId);
            obj.DataStructure = dataStructure;
            
            % Assign all the nodes in the current component to the same
            % sub-graph.
            dataStructure.setSubGraphOfNode(obj.nodesInComponent(), 1);
        end
        
    end
end