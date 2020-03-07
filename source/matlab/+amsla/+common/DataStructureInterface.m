classdef(Abstract) DataStructureInterface < handle
    %AMSLA.COMMON.DATASTRUCTUREINTERFACE Interface for DataStructure
    %objects.
    %
    %   amsla.common.DataStructureInterface methods:
    %      listOfNodes           - Get the list of the IDs of all the nodes in
    %                              the graph.
    %      childrenOfNode        - Get the children of a node.
    %      exitingEdgesOfNode    - Get the edges coming out of  a node.
    %      parentsOfNode         - Get the parents of a node.
    %      enteringEdgesOfNode   - Get the edges entering a node.
    %      loopEdgesOfNode       - Get the edges entering and exiting the
    %                              same node.
    %      listOfSubGraphs       - Get the list of sub-graphs.
    %      rootsOfSubGraph       - Get the root nodes of a sub-graph.
    %      subGraphOfNode        - Get the sub-graph to which a node
    %                              belongs.
    %      setSubGraphOfNode     - Assign a node to a sub-graph.
    %      resetSubGraphs        - Reset all sub-graphs to a null value.
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
        
        % Graph operations
        
        outIds = listOfNodes(obj)
        
        outIds = childrenOfNode(obj, nodeIds)
        
        outIds = exitingEdgesOfNode(obj, nodeIds)
        
        outIds = parentsOfNode(obj, nodeIds)
        
        outIds = listOfEdges(obj)
        
        outIds = enteringEdgesOfNode(obj, nodeIds)
        
        outIds = loopEdgesOfNode(obj, nodeIds)
        
        % Sub-graph-level operations
        
        varargout = listOfSubGraphs(obj)
        
        outIds = rootsOfSubGraph(obj, subGraphId)
        
        outIds = subGraphOfNode(obj, nodeIds)
        
        outIds = setSubGraphOfNode(obj, nodeIds, subGraphIds)
        
        resetSubGraphs(obj)
        
        % Edge-level operations
        
        outIds = timeSlotOfEdge(obj, edgeIds)
        
        setTimeSlotOfEdge(obj, edgeIds, timeSlotIds)
        
        resetTimeSlots(obj)
        
    end
    
end