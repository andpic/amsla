classdef DataStructure < amsla.common.DataStructureInterface
    %AMSLA.COMMON.DATASTRUCTURE Implementation of a graph object to be used in
    %partitioning and scheduling algorithms. An DataStructure is a graph
    %whose nodes can be associated with sub-graphs, and whose edges can
    %be associated with time-slots.
    %
    %	G = AMSLA.COMMON.DATASTRUCTURE(I,J,V) Construct an DataStructure object
    %   given the row indices (I), column indices (J), and values (V) of the
    %   edges in the graph.
    %
    %   DataStructure edge/node-level methods:
    %      listOfNodes           - Get the list of the IDs of all the nodes
    %                              in the graph.
    %      childrenOfNode        - Get the children of a node.
    %      parentsOfNode         - Get the parents of a node.
    %      listOfEdges           - Get the list of the IDs of all the edges
    %                              in the graph.
    %      exitingEdgesOfNode    - Get the edges coming out of  a node.
    %      enteringEdgesOfNode   - Get the edges entering a node.
    %      exitingNodeOfEdge     - Get the node at the end of an edge.
    %      enteringNodeOfEdge    - Get the node at the start end of an edge.
    %      loopEdgesOfNode       - Get the edges entering and exiting the
    %                              same node.
    %      sortNodesByOutdegree  - Sort the input nodes by out-degree.
    %      sortNodesByIndegree   - Sort the input nodes by in-degree.
    %      weightOfEdge          - Get the weight of an edge.
    %
    %   DataStructure component-level methods:
    %      listOfComponents      - Get the list of weakly connected
    %                              components.
    %      rootsOfComponent      - Get the root nodes of a weakly connected
    %                              component.
    %      componentOfNode       - Get the component to which a node
    %                              belongs.
    %      computeComponents     - Compute the weakly connected components.
    %
    %   DataStructure sub-graph-level methods:
    %      listOfSubGraphs       - Get the list of sub-graphs.
    %      rootsOfSubGraph       - Get the root nodes of a sub-graph.
    %      subGraphOfNode        - Get the sub-graph to which a node
    %                              belongs.
    %      setSubGraphOfNode     - Assign a node to a sub-graph.
    %      resetSubGraphs        - Reset all sub-graphs to a null value.
    %
    %   DataStructure time-slot-level methods:
    %      edgesInSubGraphAndTimeSlot   - Get the edges in the given
    %                                     time-slot for the given
    %                                     sub-graph.
    %      timeSlotsInSubGraph          - Get a list of all the time-slots
    %                                     in the graph.
    %      timeSlotOfEdge               - Get the time-slot ID of one or
    %                                     more edges.
    %      setTimeSlotOfEdge            - Get the time-slot ID of one or
    %                                     more edges.
    %      resetTimeSlots               - Void all assignments of edges to
    %                                     time-slots.
    %
    %   Other DataStructure methods:
    %      plot                  - Plot a DataStructure.
    
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
        BaseGraph
        
    end
    
    %% PUBLIC METHODS
    
    methods (Access=public)
        
        %% General
        
        function obj = DataStructure(I, J, V)
            %ENHANCEDGRAPH Construct an DataStructure object.
            
            % TODO: parse inputs
            
            % Initialise internal data
            obj.BaseGraph = iInitialiseDataStructure(I,J,V);
        end
        
        function h = plot(obj, varargin)
            %PLOT(G) Produce a plot of the graph.
            %
            %   H = PLOT(G) Produces the plot of the graph and returns the
            %   handle to the plot object.
            %
            %   H = PLOT(G, AH) Produces the plot of the graph using the
            %   given axes handle.
            
            basePlotArguments = { ...
                flipedge(obj.BaseGraph), ...
                'Layout', 'force', ...
                'NodeCData', obj.getNodeColours(), ...
                'EdgeColor', [0.859, 0.859, 0.859] };
            
            if nargin>1
                axesHandle = varargin{1};
                h = plot(axesHandle, basePlotArguments{:});
            else
                h = plot(basePlotArguments{:});
            end
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
        
        function outIds = parentsOfNode(obj, nodeIds)
            %PARENTSOFNODE(G, NODEID) Get the IDs of the parents of one or
            % more nodes in the graph.
            outIds = getNodesConnectedToNode(obj, nodeIds, "Parents");
        end
        
        function outIds = listOfEdges(obj)
            %LISTOFEDGES(G) Get the IDs of all the edges in the graph.
            outIds = unique(obj.BaseGraph.Edges.Id)';
        end
        
        function outIds = exitingEdgesOfNode(obj, nodeIds)
            %EXITINGEDGESOFNODE(G, NODEID) Get the IDs of the edges exiting
            % one or more nodes in the graph.
            outIds = getEdgesConnectedToNode(obj, nodeIds, "Exiting");
        end
        
        function outIds = enteringEdgesOfNode(obj, nodeIds)
            %ENTERINGEDGESOFNODE(G, NODE) Get the IDs of edges entering one or
            %more nodes in the graph.
            outIds = getEdgesConnectedToNode(obj, nodeIds, "Entering");
        end
        
        function outIds = exitingNodeOfEdge(obj, edgeIds)
            %EXITINNODEOFEDGE(G, EDGE) Get the IDs of nodes at the end node
            %of one or more edges in the graph.
            
            outIds = getNodeConnectedToEdge(obj, edgeIds, "Exiting");
        end
        
        function outIds = enteringNodeOfEdge(obj, edgeIds)
            %ENTERINGNODEOFEDGE(G, EDGE) Get the IDs of nodes at the start
            %node of one or more edges in the graph.
            
            outIds = getNodeConnectedToEdge(obj, edgeIds, "Entering");
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
        
        function value = weightOfEdge(obj, edgeIds)
            %WEIGHTOFEDGE(G, EDGEID) Get the weight of one or more edges.
            
            [edgeIds, inverseSorter] = iSorter(edgeIds);
            value = obj.BaseGraph.Edges.Weight( ...
                ismember(obj.BaseGraph.Edges.Id, edgeIds));
            value = value(inverseSorter);            
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
            obj.BaseGraph.Nodes.SubGraphId = ...
                amsla.common.nullId(size(obj.BaseGraph.Nodes.SubGraphId));
        end
        
        %% Time-slot operations
        
        function edgeIds = edgesInSubGraphAndTimeSlot(obj, subGraphId, timeSlotId)
            %EDGESINSUBGRAPHANDTIMESLOT(G, GID) Get the time-slot IDs in the current
            %sub-graph.
            
            edgeSelector = (obj.edgesInSubGraph(subGraphId));
            possibleTimeSlotIds = obj.BaseGraph.Edges.TimeSlot(edgeSelector);
            possibleEdgeIds = obj.BaseGraph.Edges.Id(edgeSelector);
            edgeSelector = ismember(possibleTimeSlotIds, timeSlotId);
            edgeIds = possibleEdgeIds(edgeSelector);
        end
        
        function timeSlotIds = timeSlotsInSubGraph(obj, subGraphId)
            %TIMESLOTSINSUBGRAPH(G, GID) Get the time-slot IDs in the current
            %sub-graph.
            
            edgeSelector = obj.edgesInSubGraph(subGraphId);
            timeSlotIds = obj.BaseGraph.Edges.TimeSlot(edgeSelector);
            % Remove null IDs
            timeSlotIds(amsla.common.isNullId(timeSlotIds)) = [];
            timeSlotIds = unique(timeSlotIds);
        end
        
        function outIds = timeSlotOfEdge(obj, edgeIds)
            %TIMESLOTOFEDGE(G, ID) Get the time-slot IDs of one or more edges.
            outIds = obj.BaseGraph.Edges.TimeSlot(edgeIds);
        end
        
        function setTimeSlotOfEdge(obj, edgeIds, timeSlotIds)
            %SETTIMESLOTOFEDGE(G, ID) Assign one or more edges to the given
            %time-slot IDs.
            obj.BaseGraph.Edges.TimeSlot(edgeIds) = timeSlotIds;
        end
        
        function resetTimeSlots(obj)
            %RESETTIMESLOTS(G) Reset all time-slot IDs. Reset to the
            %initial status.
            obj.BaseGraph.Edges.TimeSlot = ...
                amsla.common.nullId(size(obj.BaseGraph.Edges.TimeSlot));
        end
        
    end
    
    %% PRIVATE METHODS
    
    methods (Access=private)
        
        function edgeSel = edgesInSubGraph(obj, subGraphId)
            % Select the edges in the given sub-graph.
            
            nodeIds = obj.BaseGraph.Nodes.Id(...
                obj.BaseGraph.Nodes.SubGraphId == subGraphId);
            edgeSel = ismember(obj.BaseGraph.Edges.EndNodes(:, 1), nodeIds);
        end
        
        function outIds = getNodesConnectedToNode(obj, nodeIds, nodeProperty)
            % Get parents or children of one or more nodes
            [nodeIds, ~, sorter] = unique(nodeIds);
            selNodes = ismember(obj.BaseGraph.Nodes.Id, nodeIds);
            
            % Check which property to retrieve
            nodeProperty = validatestring(nodeProperty, ["Parents", "Children"]);
            if strcmp(nodeProperty, "Parents")
                tableColumn = "ParentsId";
                cachingFunction = @iCacheParentsOfOneNode;
            elseif strcmp(nodeProperty, "Children")
                tableColumn = "ChildrenId";
                cachingFunction = @iCacheChildrenOfOneNode;
            end
            
            % Cache the children indices that have never been cached
            cacheContent = obj.BaseGraph.Nodes.(tableColumn)(selNodes)';
            if iscell(cacheContent)
                hasNeverBeenCached = cellfun(@(x) any(amsla.common.isNullId(x)), cacheContent, 'UniformOutput', true);
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
            edgeProperty = validatestring(edgeProperty, ...
                ["Entering", "Exiting", "Loop"]);
            if strcmp(edgeProperty, "Entering")
                finderFunction = @iFindEnteringEdgesOfOneNode;
                uniformOutput = false;
            elseif strcmp(edgeProperty, "Exiting")
                finderFunction = @iFindExitingEdgesOfOneNode;
                uniformOutput = false;
            elseif strcmp(edgeProperty, "Loop")
                finderFunction = @iFindLoopEdgesOfOneNode;
                uniformOutput = true;
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
        
        function outIds = getNodeConnectedToEdge(obj, edgeIds, nodeProperty)
            % Get the nodes exiting or entering one edge.
            
            % Check which property to retrieve
            nodeProperty = validatestring(nodeProperty, ...
                ["Entering", "Exiting"]);
            if strcmp(nodeProperty, "Entering")
                finderFunction = @iFindEnteringNodeOfOneEdge;
            elseif strcmp(nodeProperty, "Exiting")
                finderFunction = @iFindExitingNodeOfOneEdge;
            end
            
            if isscalar(edgeIds)
                outIds = finderFunction(edgeIds);
            else
                outIds = arrayfun(finderFunction, edgeIds, 'UniformOutput', true);
            end
            
            % Helper functions
            function nodeId = iFindEnteringNodeOfOneEdge(edgeId)
                nodeId = obj.BaseGraph.Edges.EndNodes( ...
                    obj.BaseGraph.Edges.Id==edgeId, 2)';
            end
            
            function nodeId = iFindExitingNodeOfOneEdge(edgeId)
                nodeId = obj.BaseGraph.Edges.EndNodes( ...
                    obj.BaseGraph.Edges.Id==edgeId, 1)';
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
            
            % Compute the number of nodes in the graphset
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
                parentsByNode = obj.parentsOfNode(nodesInComponent);
                if isscalar(nodesInComponent)
                    hasNoParents = iNoneInSet(parentsByNode, nodesInComponent);
                else
                    hasNoParents = cellfun(@(x) iNoneInSet(x, nodesInComponent), ...
                        parentsByNode, 'UniformOutput', true);
                end
                nodesWithNoParents = nodesInComponent(hasNoParents)';
            end
            
            function tf = iNoneInSet(someElements, aSet)
                tf = ~any(ismember(someElements, aSet));
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
            
            accessType = validatestring(accessType, ["Set", "Get"]);
            if strcmp(accessType, "Set")
                % Check ambiguity of inputs
                iCheckAssignmentAmbiguity(nodeIds, graphSetId);
                accessor = @iSetGraphSetIdOfOneNode;
            elseif strcmp(accessType, "Get")
                accessor = @iGetGraphSetIdOfOneNode;
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
                outColours = zeros(height(obj.BaseGraph.Nodes), 1);
            end
        end
        
    end
    
end

%% HELPER FUNCTIONS

function outGraph = iInitialiseDataStructure(I, J, V)
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
end

function tableColumn = iGetTableColumnByGraphSetType(graphSetType)
graphSetType = validatestring(graphSetType, ["Component", "Sub-graph"]);
if strcmp(graphSetType, "Component")
    tableColumn = "ComponentId";
elseif strcmp(graphSetType, "Sub-graph")
    tableColumn = "SubGraphId";
end
end

function iCheckAssignmentAmbiguity(ids, assignTo)
% Check that there is no ambiguity between elements (graph nodes or edges)
% with indices IDS and the sets to which they're being assigned (assignTo).
%
% Example:
%	% Try assigning the same element with index 1 to two separate
%	% sets with indices 1 and 2
%	checkAssignmentAmbiguity([1, 1], [1, 2]);

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

function [data, inverseSorter] = iSorter(data)
[data, ~, inverseSorter] = unique(data);
end