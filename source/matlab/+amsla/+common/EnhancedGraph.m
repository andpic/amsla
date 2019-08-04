classdef EnhancedGraph < handle
    %ENHANCEDGRAPH Implementation of a graph object to be used in
    %partitioning and scheduling algorithms. An EnhancedGraph is a graph
    %whose nodes can be associated with sub-graphs, and whose edges can
    %be associated with time-slots.
    %
    %	G = ENHANCEDGRAPH(I,J,V) Construct an EnhancedGraph object given the
    %   row indices (I), column indices (J), and values (V) of the edges in
    %   the graph.
    %
    %   G = ENHANCEDGRAPH(L) Construct an EnhancedGraph object given a sparse
    %   matrix L.
    %
    %   EnhancedGraph methods:
    %      listOfNodes           - Get the list of the IDs of all the nodes in
    %                              the graph.
    %      childrenOfNode        - Get the children of a node.
    %      exitingEdgesOfNode    - Get the edges coming out of  a node.
    %      parentsOfNode         - Get the parents of a node.
    %      sortNodesByIndegree   - Sort the input nodes by in-degree.
    %      sortNodesByOutdegree  - Sort the input nodes by out-degree.
    %      enteringEdgesOfNode   - Get the edges entering a node.
    %      loopEdgesOfNode       - Get the edges entering and exiting the
    %                              same node.
    %
    %      listOfComponents      - Get the list of weakly connected
    %                              components.
    %      rootsOfComponent      - Get the root nodes of a weakly connected
    %                              component.
    %      componentOfNode       - Get the component to which a node
    %                              belongs.
    %      computeComponents     - Compute the weakly connected components.
    %
    %      listOfSubGraphs       - Get the list of sub-graphs.
    %      rootsOfSubGraph       - Get the root nodes of a sub-graph.
    %      subGraphOfNode        - Get the sub-graph to which a node
    %                              belongs.
    %      setSubGraphOfNode     - Assign a node to a sub-graph.
    %      resetSubGraphs        - Reset all sub-graphs to a null value.
    %
    %      plot                  - Plot an EnhancedGraph.

    % Copyright 2018 Andrea Picciau
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

    %% PROPERTIES

    properties (Access=private)

        %Base graph object (digraph built-in).
        %
        % BaseGraph Has the following properties:
        %
        %   Nodes: table with the following columns
        %      Id            - Id of the node
        %      ParentsId     - Ids of the parents of the node
        %      ChildrenId    - Ids of the children of the node
        %      ComponentId   - Id of the component to which the node belongs
        %      SubGraphId    - Id of the sub-graph to which the node belongs
        %   Edges: table with the following columns
        %      Id            - Id of the edge
        %      EndNodes      - Input and output node
        %      TimeSlot      - Time slot to which the node belongs
        %      IsExternal    - True if the edge is an external edge
        BaseGraph

    end

    %% PUBLIC METHODS

    methods (Access=public)

        %% General

        function obj = EnhancedGraph(varargin)
            %ENHANCEDGRAPH Construct an EnhancedGraph object.

            % TODO: parse inputs

            if nargin==1 && issparse(varargin{1})
                % If the input is sparse, extract row indices, column
                % indices, and values
                [I,J,V] = find(varargin{1});
            elseif nargin==3 && all(cellfun(@isnumeric, varargin))
                I = varargin{1};
                J = varargin{2};
                V = varargin{3};
            else
                error("Bad inputs");
            end

            % Initialise internal data
            obj.BaseGraph = iInitialiseEnhancedGraph(I,J,V);
        end

        function h = plot(obj)
            %PLOT(G) Produce a plot of the graph.
            h = plot(obj.BaseGraph, ...
                'NodeCData', obj.getNodeColours(), ...
                'EdgeColor', [0.859, 0.859, 0.859]);
        end

        %% Graph operations

        function outIds = listOfNodes(obj)
            %LISTOFNODES(G) Get the IDs of all the nodes in the graph.
            outIds = unique(obj.BaseGraph.Nodes.Id)';
        end

        function outIds = childrenOfNode(obj, nodeIds)
            %CHILDRENOFNODE(G, NODEID) Get the IDs of the children of
            %one or more nodes in the graph.
            outIds = getNodesConnectedToNode(obj, nodeIds, "Children");
        end

        function outIds = exitingEdgesOfNode(obj, nodeIds)
            %EXITINGEDGESOFNODE(G, NODEID) Get the IDs of the edges exiting
            % one or more nodes in the graph.
            outIds = getEdgesConnectedToNode(obj, nodeIds, "Exiting");
        end

        function outIds = parentsOfNode(obj, nodeIds)
            %PARENTSOFNODE(G, NODEID) Get the IDs of the parents of one or
            % more nodes in the graph.
            outIds = getNodesConnectedToNode(obj, nodeIds, "Parents");
        end

        function outIds = enteringEdgesOfNode(obj, nodeIds)
            %ENTERINGEDGESOFNODE(G, NODE) Get the IDs of edges entering one or
            %more nodes in the graph.
            outIds = getEdgesConnectedToNode(obj, nodeIds, "Entering");
        end

        function outIds = loopEdgesOfNode(obj, nodeIds)
            %LOOPEDGESOFNODE(G, NODE) Get the IDs of edges looping over one
            %or more nodes in the graph.
            outIds = getEdgesConnectedToNode(obj, nodeIds, "Loop");
        end

        function [outIds, outDegree] = sortNodesByOutdegree(obj, nodeIds)
            %SORTNODESBYOUTDEGREE(G, NODEID) Sort the input nodes by
            %out-degree.
            %
            %   O = SORTNODESBYOUTDEGREE(G, NODEID) Get the sorted node IDs.
            %
            %   [O, D] = SORTNODESBYOUTDEGREE(G, NODEID) Get the sorted
            %   node IDs and the degree.

            % MATLAB's digraph interprets edge starts and ends in the
            % opposite way.
            outDegree = obj.BaseGraph.indegree(nodeIds);
            [outDegree, sorter] = sort(outDegree, 'descend');
            outIds = nodeIds(sorter);
        end

        function [outIds, inDegree] = sortNodesByIndegree(obj, nodeIds)
            %SORTNODESBYINDEGREE(G, NODEID) Sort the input nodes by
            %in-degree.
            %
            %   O = SORTNODESBYINDEGREE(G, NODEID) Get the sorted node IDs.
            %
            %   [O, D] = SORTNODESBYINDEGREE(G, NODEID) Get the sorted
            %   node IDs and the degree.

            % MATLAB's digraph interprets edge starts and ends in the
            % opposite way.
            inDegree = obj.BaseGraph.outdegree(nodeIds);
            [inDegree, sorter] = sort(inDegree, 'descend');
            outIds = nodeIds(sorter);
        end

        %% Component-level operations

        function varargout = listOfComponents(obj)
            %LISTOFCOMPONENTS(G) Get the IDs of components in the graph.
            %
            %   C = LISTOFCOMPONENTS(G) Get the IDs of the components
            %   only.
            %
            %   [C, NC] = LISTOFCOMPONENTS(G) Get the IDs and the number of
            %   nodes in each component.
            [varargout{1:nargout}] = obj.getListOfGraphSet("Component");
        end

        function outIds = rootsOfComponent(obj, componentIds)
            %ROOTSOFCOMPONENT(G, ID) Get the IDs of the nodes without a
            %parent in one or more components.
            outIds = obj.getRootsOfGraphSet(componentIds, 'Component');
        end

        function outIds = componentOfNode(obj, nodeIds)
            %COMPONENTOFNODE(G, ID) Get the component IDs of one or more nodes.
            outIds = accessGraphSetOfNode(obj, nodeIds, "Component", "Get", []);
        end

        function computeComponents(obj)
            %COMPUTECOMPONENTS(G) Compute the weakly-connected components in
            %the graph.
            whichComponent = conncomp(obj.BaseGraph, 'Type', 'weak');
            obj.BaseGraph.Nodes.ComponentId = whichComponent';
        end

        %% Sub-graph level operations

        function varargout = listOfSubGraphs(obj)
            %LISFOFSUBGRAPHS(G) Get the IDs of sub-graphs in the graph.
            %
            %   S = LISFOFSUBGRAPHS(G) Get only the IDs of the
            %   sub-graphs.
            %
            %   [S, NS] = LISFOFSUBGRAPHS(G) Get the IDs and the number of
            %   nodes in each sub-graph.
            [varargout{1:nargout}] = obj.getListOfGraphSet("Sub-graph");
        end

        function outIds = rootsOfSubGraph(obj, subGraphId)
            %ROOTSOFSUBGRAPH(G, ID) Get the IDs of the nodes without a
            %parent in one or more sub-graphs.
            outIds = obj.getRootsOfGraphSet(subGraphId, 'Sub-graph');
        end

        function outIds = subGraphOfNode(obj, nodeIds)
            %SUBGRAPHOFNODE(G, ID) Get the sub-graph IDs of one or more nodes.
            outIds = accessGraphSetOfNode(obj, nodeIds, "Sub-graph", "Get", []);
        end

        function outIds = setSubGraphOfNode(obj, nodeIds, subGraphIds)
            %SETSUBGRAPHOFNODE(G, ID) Set the component IDs of one or more nodes.
            outIds = accessGraphSetOfNode(obj, nodeIds, "Sub-graph", "Set", subGraphIds);
        end

        function resetSubGraphs(obj)
            %RESETSUBGRAPHS(G) Reset all sub-graph IDs. Revert the graph to
            %the original state.
            obj.BaseGraph.Nodes.SubGraphId = amsla.common.nullId(size(obj.BaseGraph.Nodes.SubGraphId));
        end
    end

    %% PRIVATE METHODS

    methods (Access=private)

        function outIds = getNodesConnectedToNode(obj, nodeIds, nodeProperty)
            % Get parents or children of one or more nodes
            [nodeIds, ~, sorter] = unique(nodeIds);
            selNodes = ismember(obj.BaseGraph.Nodes.Id, nodeIds);

            % Check which property to retrieve
            nodeProperty = string(nodeProperty);
            if strcmp(nodeProperty, "Parents")
                tableColumn = "ParentsId";
                cachingFunction = @iCacheParentsOfOneNode;
            elseif strcmp(nodeProperty, "Children")
                tableColumn = "ChildrenId";
                cachingFunction = @iCacheChildrenOfOneNode;
            else
                error("Invalid node property");
            end

            % Cache the children indices that have never been cached
            cacheContent = obj.BaseGraph.Nodes.(tableColumn)(selNodes)';
            if iscell(cacheContent)
                hasNeverBeenCached = cellfun(@(x) any(amsla.common.isNullId(x)), cacheContent, 'UniformOutput', true);
            else
                hasNeverBeenCached = any(amsla.common.isNullId(cacheContent));
            end
            if any(hasNeverBeenCached)
                nodesToCache = nodeIds(hasNeverBeenCached);
                arrayfun(cachingFunction, nodesToCache);
            end

            % Return cached indices
            if isscalar(nodeIds)
                outIds = obj.BaseGraph.Nodes.(tableColumn){selNodes};
            else
                % Returns a row of cells
                outIds = obj.BaseGraph.Nodes.(tableColumn)(selNodes)';
                % Sort according to original order
                outIds = outIds(sorter);
            end

            % Helper functions
            function iCacheParentsOfOneNode(nodeId)
                selEnding = obj.BaseGraph.Edges.EndNodes(:, 1) == nodeId;
                parentsIds = obj.BaseGraph.Edges.EndNodes(selEnding, 2);
                parentsIds = parentsIds(parentsIds~=nodeId);
                obj.BaseGraph.Nodes.ParentsId{nodeId} = parentsIds';
            end

            function iCacheChildrenOfOneNode(nodeId)
                selStarting = obj.BaseGraph.Edges.EndNodes(:, 2) == nodeId;
                childrenIds = obj.BaseGraph.Edges.EndNodes(selStarting, 1);
                childrenIds = childrenIds(childrenIds~=nodeId);
                obj.BaseGraph.Nodes.ChildrenId{nodeId} = childrenIds';
            end
        end

        function outIds = getEdgesConnectedToNode(obj, nodeIds, edgeProperty)
            % Get the edges entering one or more nodes

            % Check which property to retrieve
            edgeProperty = string(edgeProperty);
            if strcmp(edgeProperty, "Entering")
                finderFunction = @iFindEnteringEdgesOfOneNode;
                uniformOutput = false;
            elseif strcmp(edgeProperty, "Exiting")
                finderFunction = @iFindExitingEdgesOfOneNode;
                uniformOutput = false;
            elseif strcmp(edgeProperty, "Loop")
                finderFunction = @iFindLoopEdgesOfOneNode;
                uniformOutput = true;
            else
                error("Invalid edge property");
            end

            if isscalar(nodeIds)
                outIds = finderFunction(nodeIds);
            else
                outIds = arrayfun(finderFunction, nodeIds, 'UniformOutput', uniformOutput);
            end

            % Helper functions
            function edgesId = iFindEnteringEdgesOfOneNode(nodeId)
                edgesId = find(obj.BaseGraph.Edges.EndNodes(:, 1)==nodeId & ...
                    obj.BaseGraph.Edges.EndNodes(:, 2)~=nodeId)';
            end

            function edgesId = iFindExitingEdgesOfOneNode(nodeId)
                edgesId = find(obj.BaseGraph.Edges.EndNodes(:, 2)==nodeId & ...
                    obj.BaseGraph.Edges.EndNodes(:, 1)~=nodeId)';
            end

            function edgesId = iFindLoopEdgesOfOneNode(nodeId)
                edgesId = find(obj.BaseGraph.Edges.EndNodes(:, 1)==nodeId & ...
                    obj.BaseGraph.Edges.EndNodes(:, 2)==nodeId)';
            end
        end

        function varargout = getListOfGraphSet(obj, graphSetType)
            % Get a list of component or sub-graph IDs

            tableColumn = iGetTableColumnByGraphSetType(graphSetType);

            outIds = [];
            if ~any(amsla.common.isNullId(obj.BaseGraph.Nodes.(tableColumn)))
                outIds = unique(obj.BaseGraph.Nodes.(tableColumn))';
            end
            varargout{1} = outIds;

            % Compute the number of vertices in the graphset
            if nargout==2
                numelGraphSet = arrayfun(@iGetNodesInOneGraphSet, outIds, 'UniformOutput', true);
                varargout{2} = numelGraphSet;
            end

            % Helper function
            function numelOneGraphSet = iGetNodesInOneGraphSet(graphSetId)
                numelOneGraphSet = sum(obj.BaseGraph.Nodes.(tableColumn)==graphSetId);
            end
        end

        function outIds = getRootsOfGraphSet(obj, graphSetId, graphSetType)
            % Get the nodes without a parent in a component or sub-graph

            tableColumn = iGetTableColumnByGraphSetType(graphSetType);

            candidateNodeId = arrayfun(@iFindNodesInOneGraphSet, graphSetId, 'UniformOutput', false);

            outIds = cellfun(@iFindNodesWithNoParents, candidateNodeId, 'UniformOutput', false);
            if isscalar(graphSetId)
                outIds = outIds{1};
            end

            % Helper functions
            function graphSetNodes = iFindNodesInOneGraphSet(grapSetId)
                selComponent = obj.BaseGraph.Nodes.(tableColumn) == grapSetId;
                graphSetNodes = obj.BaseGraph.Nodes.Id(selComponent);
            end

            function nodesWithNoParents = iFindNodesWithNoParents(nodesInComponent)
                if isscalar(nodesInComponent)
                    hasNoParents = isempty(obj.parentsOfNode(nodesInComponent));
                else
                    hasNoParents = cellfun(@isempty, obj.parentsOfNode(nodesInComponent), 'UniformOutput', true);
                end
                nodesWithNoParents = nodesInComponent(hasNoParents)';
            end
        end

        function outIds = accessGraphSetOfNode(obj, nodeIds, graphSetType, accessType, graphSetId)
            % Get or set the component or sub-graph ID of a node.

            % Managing the scalar case of graphSetId
            if isscalar(graphSetId)
                graphSetId = graphSetId*ones(size(nodeIds));
            elseif isempty(graphSetId)
                graphSetId = amsla.common.nullId(size(nodeIds));
            end

            % Check assumption on graphSetId
            validateattributes(graphSetId, {'numeric'}, {'vector'});

            tableColumn = iGetTableColumnByGraphSetType(graphSetType);

            accessType = string(accessType);
            if strcmp(accessType, "Set")
                % Check ambiguity of inputs
                iCheckAssignmentAmbiguity(nodeIds, graphSetId);
                accessor = @iSetGraphSetIdOfOneNode;
            elseif strcmp(accessType, "Get")
                accessor = @iGetGraphSetIdOfOneNode;
            else
                error("Invalid access mode to graph set.");
            end

            outIds = arrayfun(accessor, nodeIds, graphSetId, 'UniformOutput', true);

            % Helper functions
            function graphSetId = iGetGraphSetIdOfOneNode(nodeId, ~)
                graphSetId = obj.BaseGraph.Nodes.(tableColumn)(obj.BaseGraph.Nodes.Id==nodeId);
            end

            function newGraphSetId = iSetGraphSetIdOfOneNode(nodeId, newGraphSetId)
                obj.BaseGraph.Nodes.(tableColumn)(obj.BaseGraph.Nodes.Id==nodeId) = newGraphSetId;
            end
        end

        function outColours = getNodeColours(obj)
            % Get the colours to be used in the graph plot
            if any(~amsla.common.isNullId(obj.BaseGraph.Nodes.SubGraphId))
                outColours = obj.BaseGraph.Nodes.SubGraphId;
            elseif any(~amsla.common.isNullId(obj.BaseGraph.Nodes.ComponentId))
                outColours = obj.BaseGraph.Nodes.ComponentId;
            else
                outColours = "blue";
            end
        end

    end

end

%% HELPER FUNCTIONS

function outGraph = iInitialiseEnhancedGraph(I, J, V)
% Initialises the digraph object and the overall object
outGraph = digraph(I, J, V);

% Set nodes
numNodes = numnodes(outGraph);
outGraph.Nodes.Id = (1:numNodes)';
outGraph.Nodes.ParentsId = num2cell(amsla.common.nullId(numNodes, 1));
outGraph.Nodes.ChildrenId = num2cell(amsla.common.nullId(numNodes, 1));
outGraph.Nodes.ComponentId = amsla.common.nullId(numNodes, 1);
outGraph.Nodes.SubGraphId = amsla.common.nullId(numNodes, 1);

% Set edges
numEdges = numedges(outGraph);
outGraph.Edges.Id = (1:numEdges)';
outGraph.Edges.TimeSlot = amsla.common.nullId(numEdges, 1);
outGraph.Edges.IsExternal = amsla.common.nullId(numEdges, 1);
end

function tableColumn = iGetTableColumnByGraphSetType(graphSetType)
graphSetType = string(graphSetType);
if strcmp(graphSetType, "Component")
    tableColumn = "ComponentId";
elseif strcmp(graphSetType, "Sub-graph")
    tableColumn = "SubGraphId";
else
    error("Invalid type of graph set.");
end
end

function iCheckAssignmentAmbiguity(ids, assignTo)
% Check that there is no ambiguity between elements (graph nodes or edges)
% with indices IDS and the sets to which they're being assigned (assignTo).
%
%   Example:
%       % Try assigning the same element with index 1 to two separate
%       % sets with indices 1 and 2
%       checkAssignmentAmbiguity([1, 1], [1, 2]);

% Turn arrays into columns
ids = reshape(ids,[length(ids), 1]);
assignTo = reshape(assignTo,[length(assignTo), 1]);

% Check unique couples of indices and what they're been assigned to
uniqueCouples = unique([ids, assignTo], "rows");
% Check unique indices
uniqueIds = unique(ids);

% If the number of unique indices and unique couples differ, it means an
% index is being assigned to more than one different set
assert(size(uniqueCouples, 1)==size(uniqueIds,1), ...
    "Ambiguous assignment");
end
