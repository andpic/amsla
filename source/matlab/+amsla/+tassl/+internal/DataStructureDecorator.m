classdef(Abstract) DataStructureDecorator < amsla.common.DataStructureInterface
    %AMSLA.TASSL.INTERNAL.DATASTRUCTUREDECORATOR An abstract class for a
    %decorator of a DataStructure object.
    %
    %   AMSLA.TASSL.INTERNAL.DATASTRUCTUREDECORATOR decoration methods:
    %      listOfTags      - Get the list of the tags of a certain type
    %                        associated with nodes in the graph.
    %      tagOfNode       - Get the tag of a node.
    %      setTagOfNode    - Associate a node with a tag.
    
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
    
    properties(Access=private)
        %The DataStructure object being wrapped
        DataStructure
        
        %Maps nodes to tags
        NodeTagMap
    end
    
    %% PROTECTED
    
    methods(Access=protected)
        function [tags, numOfNodes] = listOfTags(obj, tagName)
            %LISTOFTAGS(D, T) Obtain the list of tags associated with
            %nodes.
            
            tags = unique(obj.NodeTagMap.(tagName).Tag);
            numOfNodes = sum(obj.NodeTagMap.(tagName).Tag == tags');
            tags = iRowVector(tags);
            numOfNodes = iRowVector(numOfNodes);
        end
        
        function tag = tagOfNode(obj, tagName, nodeIds)
            %TAGOFNODE(D, TN, N) Get the tag named TN associated with the
            %node N.
            
            [nodeIds, ~, invSorter] = unique(nodeIds);
            tag = obj.NodeTagMap.(tagName).Tag(...
                ismember(obj.NodeTagMap.(tagName).NodeId, nodeIds));
            tag = iRowVector(tag(invSorter));
        end
        
        function setTagOfNode(obj, tagName, nodeIds, tags)
            %SETTAGOFNODE(D, T, N) Set the tag named TN associated with the
            %node of ID N.
            
            if isscalar(tags)
                tags = tags*ones(size(nodeIds));
            end
            [uniqueNodes, sorter] = unique(nodeIds);
            assert(numel(uniqueNodes)==numel(nodeIds), ...
                "Ambiguous input.");
            
            uniqueTags = tags(sorter);
            obj.NodeTagMap.(tagName).Tag(...
                ismember(obj.NodeTagMap.(tagName).NodeId, uniqueNodes)) = ...
                iRowVector(uniqueTags)';
        end
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        function obj = DataStructureDecorator(dataStructure, tagName)
            obj.DataStructure = dataStructure;
            
            allNodes = iRowVector(dataStructure.listOfNodes());
            obj.NodeTagMap = struct();
            obj.NodeTagMap.(tagName) = struct( ...
                'NodeId', allNodes, ...
                'Tag', amsla.common.nullId(size(allNodes)));
        end
        
        % General
        
        function h = plot(obj, varargin)
            h = obj.DataStructure.plot(varargin{:});
        end
        
        % Graph operations
        
        function outIds = listOfNodes(obj)
            outIds = obj.DataStructure.listOfNodes();
        end
        
        function outIds = childrenOfNode(obj, nodeIds)
            outIds = obj.DataStructure.childrenOfNode(nodeIds);
        end
        
        function outIds = exitingEdgesOfNode(obj, nodeIds)
            outIds = obj.DataStructure.exitingEdgesOfNode(nodeIds);
        end
        
        function outIds = parentsOfNode(obj, nodeIds)
            outIds = obj.DataStructure.parentsOfNode(nodeIds);
        end
        
        function outIds = listOfEdges(obj)
            outIds = obj.DataStructure.listOfEdges();
        end
        
        function outIds = enteringEdgesOfNode(obj, nodeIds)
            outIds = obj.DataStructure.enteringEdgesOfNode(nodeIds);
        end
        
        function outIds = loopEdgesOfNode(nodeIds)
            outIds = obj.DataStructure.loopEdgesOfNode(nodeIds);
        end
        
        % Sub-graph-level operations
        
        function varargout = listOfSubGraphs(obj)
            [varargout{:}] = obj.DataStructure.listofSubGraphs();
        end
        
        function outIds = rootsOfSubGraph(obj, subGraphId)
            outIds = obj.DataStructure.rootsOfSubGraph(subGraphId);
        end
        
        function outIds = subGraphOfNode(obj, nodeIds)
            outIds = obj.DataStructure.subGraphofNode(nodeIds);
        end
        
        function outIds = setSubGraphOfNode(obj, nodeIds, subGraphIds)
            outIds = obj.DataStructure.setSubGraphOfNode(nodeIds, subGraphIds);
        end
        
        function resetSubGraphs(obj)
            obj.DataStructure.resetSubGraphs();
        end
        
        % Edge-level operations
        
        function outIds = timeSlotOfEdge(obj, edgeIds)
            outIds = obj.DataStructure.timeSlotOfEdge(edgeIds);
        end
        
        function setTimeSlotOfEdge(obj, edgeIds, timeSlotIds)
            obj.DataStructure.setTimeSlotOfEdge(edgeIds, timeSlotIds);
        end
        
        function resetTimeSlots(obj)
            obj.DataStructure.resetTimeSlots();
        end
    end
end

%% HELPER FUNCTIONS

function dataOut = iRowVector(dataIn)
dataOut = amsla.common.rowVector(dataIn);
end
