classdef SchedulerGraphWrapper
    
    properties(Access=private)
        Graph
    end
    
    methods(Access=public)
        
        function obj = SchedulerGraphWrapper(aGraph)
            obj.Graph = aGraph;
        end
        
        function rootIds = getRootsBySubGraph(obj)
            % Retrieve root and sub-graph IDs
            
            subGraphIds = obj.Graph.listOfSubGraphs();
            rootIds = obj.Graph.rootsOfSubGraph(subGraphIds);
            
        end
        
        function edgeIds = getEnteringEdges(obj, nodeIds)
            edgeIds = obj.Graph.enteringEdgesOfNode(nodeIds);
        end
        
        function assignEdgesToTimeSlot(obj, edgeIds, timeSlotIds)
            obj.Graph.assignEdgesToTimeSlot(edgeIds, timeSlotIds);
        end
        
        
        function nodeIds = getReadyChildrenOfNode(obj, parentNodeIds)
            allChildrenIds = obj.Graph.childrenOfNode(parentNodeIds);
            
            if iscell(allChildrenIds)
                allChildrenIds = cell2mat(allChildrenIds);
            end
            
            readyNodes = arrayfun(@isNodeReady, allChildrenIds, ...
                "UniformOutput", true);
            nodeIds = allChildrenIds(readyNodes);            
            
            function tf = isNodeReady(nodeIds)
               enteringEdgeIds =  obj.getEnteringEdges(nodeIds);
               timeSlotIds = obj.getTimeSlotOfEdge(enteringEdgeIds);
               tf = ~any(iIsNull(timeSlotIds));
            end
        end
        
    end
    
    methods(Access=private)
        
        function timeSlotIds = getTimeSlotOfEdge(obj, edgeIds)
           timeSlotIds = obj.Graph.timeSlotOfEdge(edgeIds); 
        end
        
    end
    
end

%% HELPER FUNCTIONS

function tf = iIsNull(id)
tf = amsla.common.isNullId(id);
end