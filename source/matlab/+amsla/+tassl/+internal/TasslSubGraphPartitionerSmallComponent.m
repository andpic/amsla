classdef(Sealed) TasslSubGraphPartitionerSmallComponent < ...
        amsla.tassl.internal.TasslSubGraphPartitionerImplInterface
    %AMSLA.TASSL.INTERNAL.TASSLSUBGRAPHPARTITIONERSMALLCOMPONENT
    %Implementation of TASSL's partitioning algorithm for small components.
    
    %% PROTECTED PROPERTIES
    
    properties(SetAccess=immutable, GetAccess=protected)
        
        % The graph being processed
        DataStructure
        
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = TasslSubGraphPartitionerSmallComponent(dataStructure, maxSize, componentId)
            %TASSLSUBGRAPHPARTITIOENRSMALLCOMPONENT(G) For a small
            %component, assign all the nodes to the same sub-graph.
            
            obj = obj@amsla.tassl.internal.TasslSubGraphPartitionerImplInterface( ...
                dataStructure, maxSize, componentId);
            obj.DataStructure = dataStructure;
            
            % Assign all the nodes in the current component to the same
            % sub-graph.
            dataStructure.setSubGraphOfNode(obj.nodesInComponent(), 1);
        end
        
    end
end