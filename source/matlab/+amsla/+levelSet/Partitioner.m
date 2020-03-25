classdef Partitioner < amsla.common.PartitionerInterface & ...
        amsla.common.BreadthFirstSearch
    %AMSLA.LEVELSET.PARTITIONER Construct an object that carries out the
    %partitioning of a matrix according to the level-set algorithm
    %
    %   A = PARTITIONER(G, []) Partition the sparse matrix defined by the
    %   EnhancedGraph object G.
    %
    %   A = PARTITIONER(__, 'Plot', true) Plot the progress of the
    %   partitioning algorithm.
    %
    %   Methods of Partitioner:
    %       partition        - Partitions the matrix according to the
    %                          level-set algorithm.
    
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
        
        function obj = Partitioner(dataStructure, varargin)
            %PARTITIONER Construct an object that executes the
            %analysis of a matrix according to the level-set algorithm.
            
            obj@amsla.common.PartitionerInterface(varargin{:});
            obj@amsla.common.BreadthFirstSearch(dataStructure);
            
            if ~isempty(obj.MaxSubGraphSize)
                warning("amsla:levelSet:sizeIgnored", ...
                    "The level-set algorithm does not enforce a maximum sub-graph size. Input will be ignored.");
            end
        end
        
        function partitioningResult = partition(obj)
            %PARTITION(A) Partition the graph according to the level-set
            %algorithm.
            
            obj.executeAlgorithm();
            
            assert(amsla.common.allNodesAreAssigned(obj.DataStructure), ...
                "Not all nodes were assigned to sub-graphs.");
            
            partitioningResult = amsla.common.PartitioningResult(true);
        end
        
    end
    
    %% PROTECTED METHODS
    
    methods(Access=protected)
        
        function [nodeIds, initialSubGraphIds] = initialNodesAndTags(obj)
            %INITIALNODESANDTAGS Get the nodes and tags to initialise the
            %algorithm.
            
            nodeIds = iArray(obj.rootNodes());
            initialSubGraphIds = iArray(ones(size(nodeIds)));
        end
        
        function nodeIds = selectNextNodes(obj, currentNodeIds)
            %SELECTNEXTNODES Select the nodes whose parents have all been
            %assigned to a sub-graph.
            
            % Find children of current nodes
            nodeIds = iArray(obj.selectChildrenIfAllParentsAssigned(currentNodeIds, ...
                @subGraphOfNode));
        end
        
        function subGraphIds = computeTags(obj, currentNodeIds)
            %COMPUTETAGS Compute the sub-graph ID for each of the current
            %nodes to assign.
            
            subGraphIds = iArray(obj.maxTagOfParents(currentNodeIds, @subGraphOfNode));
            subGraphIds = subGraphIds+1;
        end
        
        function assignTagsToNodes(obj, nodeIds, subGraphIds)
            %ASSIGNTAGSTONODES Assign the sub-graph to the given node IDs.
            
            assert(all(~iIsNullId(subGraphIds)), ...
                "Assigning to an invalid sub-graph ID");
            obj.DataStructure.setSubGraphOfNode(nodeIds, subGraphIds);            
            obj.updateProgressPlot();
        end
        
    end
    
    %% PRIVATE METHODS
    
    methods(Access=private)
        
        function nodeIds = rootNodes(obj)
            %ROOTNODES(P, CID) Root nodes in a given component.
            
            allNodes = obj.DataStructure.listOfNodes();
            nodeIds = allNodes( ...
                amsla.common.numberOfParents(obj.DataStructure, allNodes) == 0);
        end
        
    end
    
end

%% HELPER METHODS

function dataOut = iArray(dataIn)
dataOut = iRow(amsla.common.numericArray(dataIn));
end

function tf = iIsNullId(dataIn)
tf = amsla.common.isNullId(dataIn);
end

function tf = iRow(dataIn)
tf = amsla.common.rowVector(dataIn);
end