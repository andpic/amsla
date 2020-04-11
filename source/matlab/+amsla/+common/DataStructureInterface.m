classdef(Abstract) DataStructureInterface < handle
    %AMSLA.COMMON.DATASTRUCTUREINTERFACE Interface for DataStructure
    %objects.
    %
    %   amsla.common.DataStructureInterface methods:
    %      listOfNodes           - All the node IDs in the graph.
    %      parentsOfNode         - The parents of a given node.
    %      childrenOfNode        - The children of a given node.
    %   
    %      listOfEdges           - All the edges ID in the graph.
    %      exitingEdgesOfNode    - Get the edges coming out of  a node.          
    %      enteringEdgesOfNode   - Get the edges entering a node.
    %      enteringNodeOfEdge    - Get the node that enters a 
    %      loopEdgesOfNode       - The looping edges for the given node.
    %      weightOfEdge          - The weight of a given edge.
    %
    %      listOfSubGraphs       - Get the list of sub-graphs.
    %      subGraphOfNode        - Get the sub-graph to which a node belongs.
    %      setSubGraphOfNode     - Assign a node to a sub-graph.
    %
    %      listOfTimeSlots       - Get the list of time-slots
    %      timeSlotOfEdge        - Get the time-slot to which an edge belongs.
    %      setTimeSlotOfEdge     - Assign an edge to a time-slot.
    %
    %      plot                  - Plot the object.
    
    % Copyright 2019-2020 Andrea Picciau
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
    
    
    %% ABSTRACT PUBLIC METHODS
    
    methods (Abstract, Access=public)
        
        % General
        
        h = plot(obj, varargin)
        
        % Node-level operations
        
        outIds = listOfNodes(obj)
        
        outIds = childrenOfNode(obj, nodeIds)
                
        outIds = parentsOfNode(obj, nodeIds)
        
        % Edge-level operations
        
        outIds = listOfEdges(obj)
        
        outIds = exitingEdgesOfNode(obj, nodeIds)
                                
        outIds = enteringEdgesOfNode(obj, nodeIds)
        
        outIds = enteringNodeOfEdge(obj, edgeIds)
        
        outIds = exitingNodeOfEdge(obj, edgeIds)
        
        outIds = loopEdgesOfNode(obj, nodeIds)
        
        weight = weightOfEdge(obj, edgeId)
        
        % Sub-graph-level operations
        
        outIds = listOfSubGraphs(obj)
        
        outIds = subGraphOfNode(obj, nodeIds)
        
        outIds = setSubGraphOfNode(obj, nodeIds, subGraphIds)
        
        % Edge-level operations
        
        outIds = listOfTimeSlots(obj)
        
        outIds = timeSlotOfEdge(obj, edgeIds)
        
        setTimeSlotOfEdge(obj, edgeIds, timeSlotIds)        
        
    end
    
end