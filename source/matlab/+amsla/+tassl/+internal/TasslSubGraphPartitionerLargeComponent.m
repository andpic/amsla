classdef(Sealed) TasslSubGraphPartitionerLargeComponent < ...
        amsla.tassl.internal.TasslSubGraphPartitionerImplInterface & ...
        amsla.common.BreadthFirstSearch
    %AMSLA.TASSL.INTERNAL.TASSLSUBGRAPHPARTITIONERLARGECOMPONENT Partition
    %a large graph component into sub-graphs.
    
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
    
    %% PRIVATE PROPERTIES
    
    properties(Access=private)
        
        %Number of nodes in each sub-graph
        SubGraphSizes
        
        %Criterion to for sorting the nodes at every step
        SortingCriterion string
        
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = TasslSubGraphPartitionerLargeComponent(dataStructure, maxSize, componentId)
            %TASSLSUBGRAPHPARTITIONERLARGECOMPONENT(G) Construct a
            %TasslSubGraphPartitioner and partition the input DataStructure
            %object.
            
            validateattributes(dataStructure, {'amsla.tassl.internal.ComponentDecorator'}, ...
                {'scalar', 'nonempty'});
            
            obj = obj@amsla.common.BreadthFirstSearch(dataStructure);
            obj@amsla.tassl.internal.TasslSubGraphPartitionerImplInterface(dataStructure, maxSize, componentId);
            obj.SubGraphSizes = zeros(1, obj.NumSubGraphs);
        end
        
        function partitionComponent(obj)
            %PARTITIONCOMPONENT Partition the component.
            
            obj.SortingCriterion = "out-degree";
            success = obj.executeAlgorithm();
            
            if ~success
                obj.resetSubGraphAssignment();
                obj.SortingCriterion = "in-degree";
                success = obj.executeAlgorithm();
            end
            
            if ~success
                obj.resetSubGraphAssignment();
                obj.SortingCriterion = "nodeId";
                success = obj.executeAlgorithm();
            end
            
            assert(success && obj.allNodesAreAssigned(), ...
                "Partitioning wasn't succesful.");
        end
        
    end
    
    %% PROTECTED METHODS
    
    methods(Access=protected)
        
        function [nodeIds, initialSubGraphIds] = initialNodesAndTags(obj)
            %INITIALNODESANDTAGS Get the nodes and tags to initialise the
            %algorithm.
            
            nodeIds = iArray(obj.rootNodes());
            nodeIds = obj.sortByCriterion(nodeIds);
            initialSubGraphIds = iArray(iStartingSubGraphs( ...
                obj.NumSubGraphs, numel(nodeIds)));
        end
        
        function nodeIds = selectNextNodes(obj, currentNodeIds)
            %SELECTNEXTNODES Select the nodes whose parents have all been
            %assigned to a sub-graph.
            
            % Find children of current nodes
            nodeIds = obj.selectChildrenIfAllParentsAssigned(currentNodeIds, ...
                @subGraphOfNode);
            nodeIds = obj.sortByCriterion(nodeIds);
        end
        
        function subGraphIds = computeTags(obj, currentNodeIds)
            %COMPUTETAGS Compute the sub-graph ID for each of the current
            %nodes to assign.
            
            subGraphIds = obj.maxTagOfParents(currentNodeIds, @subGraphOfNode);
            subGraphIds = obj.nextNonfullSubGraphs(subGraphIds);
        end
        
        function assignTagsToNodes(obj, nodeIds, tags)
            %ASSIGNTAGSTONODES Assign the sub-graph to the given node IDs.
            
            assert(all(tags>0) && all(tags<=obj.NumSubGraphs), ...
                "Assigning to an invalid sub-graph ID");
            
            obj.DataStructure.setSubGraphOfNode(nodeIds, tags);
            obj.recordSubGraphAssignment(tags);
        end
        
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
        
        function nodeId = sortByCriterion(obj, nodeId)
            %SORTBYCRITERION Sort a set of nodes by the current sorting
            %criterion.
            
            if obj.SortingCriterion == "out-degree"
                nodeId = iSortByProperty(nodeId, obj.numberOfChildren(nodeId));
            elseif obj.SortingCriterion == "in-degree"
                nodeId = iSortByProperty(nodeId, obj.numberOfPartents(nodeId));
            elseif obj.SortingCriterion == "nodeId"
                nodeId = sort(nodeId, "ascend");
            end
        end
        
        function recordSubGraphAssignment(obj, subGraphId)
            %RECORDSUBGRAPHASSIGNMENT Record the assignment of sub-graphs.
            
            [uniqueSubg, numNodes] = iCountUnique(subGraphId);
            for k = 1:numel(uniqueSubg)
                currSubg = uniqueSubg(k);
                obj.SubGraphSizes(currSubg) = ...
                    obj.SubGraphSizes(currSubg) + numNodes(k);
            end
        end
        
        function subGraphIds = nextNonfullSubGraphs(obj, subGraphIds)
            %NEXTNONFULLSUBGRAPHS Given a set of sub-graph assignments,
            %fix them such that no sub-graph has more than MaxSize
            %elements.
            
            currentSizes = obj.SubGraphSizes;
            
            for k = 1:numel(subGraphIds)
                currId = subGraphIds(k);
                while currId <= obj.NumSubGraphs && currentSizes(currId) > obj.MaxSize
                    currId = currId + 1;
                end
                
                if currId <= obj.NumSubGraphs
                    currentSizes(currId) = ...
                        currentSizes(currId) + 1;
                    subGraphIds(k) = currId;
                else
                    subGraphIds(k) = amsla.common.nullId(1);
                    break;
                end
            end
        end
        
        function nodeIds = rootNodes(obj)
            %ROOTNODES(P, CID) Root nodes in a given component.
            
            allNodes = obj.DataStructure.listOfNodes();
            allComponents = obj.DataStructure.componentOfNode(allNodes);
            allNodes = allNodes(allComponents == obj.ComponentId);
            
            nodeIds = allNodes(...
                amsla.common.numberOfParents(obj.DataStructure, allNodes) == 0);
        end
        
        function num = numberOfChildren(obj, nodeIds)
            %NUMBEROFCHILDREN(P, NID) Number of children of the given nodes,
            %given their IDs.
            
            childrenOfNode = obj.DataStructure.childrenOfNode(nodeIds);
            if iscell(childrenOfNode)
                num = cellfun(@numel, childrenOfNode, 'UniformOutput', true);
            else
                num = numel(childrenOfNode);
            end
        end
        
        function resetSubGraphAssignment(obj)
            %RESETSUBGRAPHASSIGNMENT Clear all sub-graph assignments.
            
            allNodes = obj.DataStructure.listOfNodes();
            obj.setSubGraphOfNode(allNodes, amsla.common.nullId(size(allNodes)));
            obj.SubGraphSizes = zeros(1, obj.NumSubGraphs);
        end
        
        function tf = allNodesAreAssigned(obj)
            %ALLNODESAREASSIGNED Return true if all nodes were assigned to
            %sub-graphs.
            
            allNodes = obj.nodesInComponent();
            subGraphs = obj.DataStructure.subGraphOfNode(allNodes);
            tf = ~any(amsla.common.isNullId(subGraphs));
        end
        
    end
end

%% HELPER FUNCTIONS

function dataOut = iArray(dataIn)
dataOut = amsla.common.numericArray(dataIn);
end

function tf = iRow(dataIn)
tf = amsla.common.rowVector(dataIn);
end

function startSubg = iStartingSubGraphs(numSubGraphs, numRootNodes)
startSubg = mod(0:(numRootNodes-1), numSubGraphs)+1;
end

function [uniqueTags, numNodes] = iCountUnique(tags)
uniqueTags = reshape(unique(tags), [], 1);
numNodes = iRow(accumarray(uniqueTags, 1));
uniqueTags = iRow(uniqueTags);
end

function [dataOut, sorter] = iSortByProperty(dataIn, property)
[~, sorter] = sort(property, "descend");
dataOut = dataIn(sorter);
end