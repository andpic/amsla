classdef(Abstract) TasslSubGraphPartitionerImplInterface
    %AMSLA.TASSL.INTERNAL.TASSSUBGRAPHPARTITIONERIMPLINTERFACE Common
    %interface for all implementations of TASSL component processing.
    
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
    
    %% PUBLIC PROPERTIES
    
    properties(SetAccess=immutable, GetAccess=public)
        
        %Maximum size of a sub-graph.
        MaxSize
        
        %ID of the component currently being processed.
        ComponentId
        
        %Number of sub-graphs to partition the current component into.
        NumSubGraphs
        
    end
    
    %% ABSTRACT PROPERTIES
    
    properties(Access=protected, Abstract)
        
        %The data structure representing the graph being partitioned.
        DataStructure
        
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = TasslSubGraphPartitionerImplInterface(dataStructure, maxSize, componentId)
            %TASSLSUBGRAPHPARTITIONERIMPLINTERFACE(G) Interface for TASSL's
            %partitioning for any component.
            
            validateattributes(dataStructure, {'amsla.tassl.internal.ComponentDecorator'}, ...
                {'scalar', 'nonempty'});
            
            obj.MaxSize = maxSize;
            obj.ComponentId = componentId;
            
            numNodes = numel(iNodesInComponent(dataStructure, componentId));
            obj.NumSubGraphs = ceil(numNodes/maxSize);
        end
        
    end
    
    %% PROTECTED METHODS
    
    methods(Access=protected)
        
        function outIds = nodesInComponent(obj)
            %NODESINCOMPONENT(OBJ) Get the IDs of all the nodes in the
            %current component.
            
            outIds = iNodesInComponent(obj.DataStructure, obj.ComponentId);
        end
        
    end
    
end

%% HELPER FUNCTIONS

function outIds = iNodesInComponent(dataStructure, componentId)
%NODESINCOMPONENT(OBJ) Get the IDs of all the nodes in the
%current component.

allNodes = dataStructure.listOfNodes();
outIds = allNodes(dataStructure.componentOfNode(allNodes)==componentId);
end