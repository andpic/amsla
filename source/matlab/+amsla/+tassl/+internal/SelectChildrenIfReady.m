classdef(Abstract) SelectChildrenIfReady
    
    
    properties(Abstract)
        
        DataStructure
        
    end
    
    methods(Abstract, Access=protected)
        
        isReady = obj.computeBasedOnParents(obj, nodeIds, isReadyFcn);
        
    end
    
    methods(Access=protected)
        
        function nodeIds = selectChildrenIfReady(obj, currentNodeIds, isReadyFcn)
            %SELECTCHILDRENIFREADY Select the children of the input nodes if
            %they satisfy the given function.
            
            % Find children of current nodes
            nodeIds = obj.DataStructure.childrenOfNode(currentNodeIds);
            nodeIds = unique(iArray(nodeIds));
            
            % Find out which ones are ready
            isChildReady = obj.computeBasedOnParents(nodeIds, isReadyFcn);
            nodeIds = nodeIds(isChildReady);
        end
        
    end
end