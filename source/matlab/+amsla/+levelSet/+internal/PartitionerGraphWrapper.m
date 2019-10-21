classdef PartitionerGraphWrapper < amsla.common.internal.PartitionerGraphWrapperInterface
    %AMSLA.LEVELSET.INTERNAL.PARTITIONERGRAPHWRAPPER Wrapper to a graph to
    %be used for the analysis phase with the level-set approach.
    %
    %   G = AMSLA.LEVELSET.INTERNAL.PARTITIONERGRAPHWRAPPER(G) Create a wrapper
    %   to a graph describer by the EnhancedGraph object G.
    %
    %   PartitionerGraphWrapper methods:
    %       findRoots                           - Find the root nodes of
    %                                             the graph.
    %       assignNodeToSubGraph                - Assign one or more nodes
    %                                             to sub-graphs.
    %       subGraphOfNode                      - Get the sub-graph to which a node
    %                                             belongs.
    %       childrenOfNodeReadyForAssignment    - Get the nodes that are
    %                                             ready for being assigned.
    %       checkFullAssignment                 - Check that all nodes were
    %                                             assigned to sub-graphs.
    %       resetAllAssignments                 - Reset the status of the
    %                                             graph to its initial one.
    %
    %       plot                                - Plot the graph.
    
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
    
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function [rootIds] = findRoots(obj)
            %FINDROOTS(G) Find the root nodes of the graph.
            %
            % Use:
            %   [R] = FINDROOTS(G)
            %       Find the root nodes in the graph G. Returns the root node
            %       IDs.
            
            % Retrieve list of all node IDs
            allIds = obj.Graph.listOfNodes();
            
            % Only select nodes that do not have parents
            numIndices = numel(allIds);
            isWithoutParents = false([numIndices, 1]);
            
            for k = 1:numIndices
                currIndex = allIds(k);
                isWithoutParents(k) = isempty(obj.Graph.parentsOfNode(currIndex));
            end
            rootIds = allIds(isWithoutParents);
        end
        
        function [childrenIds] = childrenOfNodeReadyForAssignment(obj, nodeIds)
            %CHILDRENOFNODEREADYFORASSIGNMENT(G, I) Get the IDs of the
            %children of one or more nodes I, such that all the parents of
            %these children were assigned to sub-graphs.
            %
            % Use:
            %   C = CHILDRENOFNODEREADYFORASSIGNMENT(G, I)
            %       Get the IDs of the children IDs that are ready for
            %       assignment.
            
            childrenIds = obj.childrenOfNode(nodeIds);
            childrenIds = obj.nodesReadyForAssignment(childrenIds);
        end
        
    end
end