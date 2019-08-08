classdef GraphWrapper < handle
    %AMSLA.COMMON.GRAPHWRAPPER Wrapper to a graph to be used for the analysis phase.
    %
    %   G = AMSLA.COMMON.GRAPHWRAPPER(I, J, V) Create a wrapper to a graph
    %   describer by the triplet I (row indexes), J (column indexes), and J
    %   (edge values).
    %
    %   GraphWrapper methods:
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
    
    properties(Access=protected)
        
        %An EnhancedGraph object used to represent the graph
        Graph
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public, Abstract)
        
        [childrenIds, subGraphIds] = childrenOfNodeReadyForAssignment(obj, nodeIds);
        
    end
    
    methods(Access=public)
        
        function obj = GraphWrapper(I, J, V)
            %GRAPHWRAPPER(I, J, V) Constructs a graph wrapper to be used for
            %the analysis phase.
            
            % Initialise the graph
            obj.Graph = amsla.common.EnhancedGraph(I, J, V);
        end
        
        function h = plot(obj, varargin)
            %PLOT(G) Produce a plot of the graph.
            h = obj.Graph.plot(varargin{:});
        end
        
        function assignNodeToSubGraph(obj, nodeIds, subGraphIds)
            %ASSIGNNODETOSUBGRAPH(G, I, S) Assign one or more nodes with ID
            %I to sub-graphs with IDs S.
            
            % Assign sub-graphs
            [nodeIds, subGraphIds] = iGetIndexArrayForm(nodeIds, subGraphIds);
            obj.Graph.setSubGraphOfNode(nodeIds, subGraphIds);
        end
        
        function outIds = subGraphOfNode(obj, nodeIds)
            %SUBGRAPHOFNODE(G, I) Get the sub-graph IDs to which one or
            %more nodes were assigned.
            outIds = obj.Graph.subGraphOfNode(nodeIds);
        end
        
        function isFullyAssigned = checkFullAssignment(obj)
            %CHECKFULLASSIGNMENT(G) Check that all the nodes in the graph
            %were assigned to sub-graphs.
            isFullyAssigned = ~any(amsla.common.isNullId( ...
                obj.Graph.subGraphOfNode(obj.Graph.listOfNodes())));
        end
        
        function resetAllAssignments(obj)
            %RESETALLASSIGNMENTS(G) Reset all node-to-sub-graph
            %assignments.
            obj.Graph.resetSubGraphs();
        end        
        
    end
    
    %% PROTECTED METHODS
    
    methods(Access=protected)
        function [childrenIds] = childrenOfNode(obj, nodeIds)
            %CHILDRENOFNODE(W, N) Get the children of the nodes in N and
            %make sure they're a list of unique values.
            
            childrenIds = obj.Graph.childrenOfNode(nodeIds);
            if iscell(childrenIds)
                childrenIds = cell2mat(childrenIds);
            end
            childrenIds = unique(childrenIds);
        end
        
        
        function [nodeIds, subGraphIds] = nodesReadyForAssignment(obj, nodeIds)
            %NODESREADYFORASSIGNMENT(W, N) Get those nodes among N that are
            %ready to be assigned to a sub-graph because:
            % - they have not beeen already assigned to a sub-graph.
            % - all their parents have been assigned to a sub-graph.
            
            % No nodes must have been assigned to a sub-graph already
            assert(all(amsla.common.isNullId(obj.Graph.subGraphOfNode(nodeIds))), ...
                "One or more nodes were assigned to a sub-graph before their parents.");
            
            % Retrieve candidate sub-graph IDs
            parentIds = obj.Graph.parentsOfNode(nodeIds);
            if iscell(parentIds)
                subGraphIds = cellfun(@iGetSubGraphCandidateGivenParentIds, parentIds, ...
                    'UniformOutput', true);
            else
                subGraphIds = iGetSubGraphCandidateGivenParentIds(parentIds);
            end
            
            % Filter out nodes that are not ready
            filterSel = amsla.common.isNullId(subGraphIds);
            subGraphIds(filterSel) = [];
            nodeIds(filterSel) = [];
            
            % Helper function
            function subGraphCandidateId = iGetSubGraphCandidateGivenParentIds(parentIds)
                parentSubGraphs = obj.Graph.subGraphOfNode(parentIds);
                if ~any(amsla.common.isNullId(parentSubGraphs))
                    subGraphCandidateId = max(parentSubGraphs);
                else
                    subGraphCandidateId = amsla.common.nullId();
                end
            end
        end
        
    end
    
end

%% HELPER FUNCTIONS

function [nodeIds, subGraphIds] = iGetIndexArrayForm(nodeIds, subGraphIds)
if iscell(nodeIds)
    nodeIds = cell2mat(nodeIds);
end
if iscell(subGraphIds)
    subGraphIds = cell2mat(subGraphIds);
end
% assert(numel(nodeIds)==numel(subGraphIds), "The number of node indexes doesn't match the number of sub-graphs.");
end