classdef(Abstract) DataStructureDecorator < amsla.common.DataStructure
    
    
    properties(Access=private)
        DataStructure
        
        NodeTagMap
    end
    
    methods(Access=protected)
        function [tags, numOfNodes] = listOfTags(obj, tagName)
            tags = unique(obj.NodeTagMap.(tagName).Tag);
            numOfNodes = sum(obj.NodeTagMap.(tagName).Tag == tags');
            tags = iRowVector(tags);
            numOfNodes = iRowVector(numOfNodes);
        end
        
        function tag = tagOfNode(obj, tagName, nodeIds)
            [nodeIds, ~, invSorter] = unique(nodeIds);
            tag = obj.NodeTagMap.(tagName).Tag(...
                ismember(obj.NodeTagMap.(tagName).NodeId, nodeIds));
            tag = iRowVector(tag(invSorter));
        end
        
        function setTagOfNode(obj, tagName, nodeIds, tags)
            [uniqueNodes, sorter] = unique(nodeIds);
            assert(numel(uniqueNodes)==numel(nodeIds), ...
                "Ambiguous input.");
            
            uniqueTags = tags(sorter);
            obj.NodeTagMap.(tagName).Tag(...
                ismember(obj.NodeTagMap.(tagName).NodeId, uniqueNodes)) = ...
                iRowVector(uniqueTags)';
        end
    end
    
    methods(Access=public)
        function obj = DataStructureDecorator(aDataStructure, tagName)
            obj.DataStructure = aDataStructure;
            
            allNodes = iRowVector(dataStructure.listOfNodes());
            obj.NodeTagMap.(tagName) = struct( ...
                allNodes, ...
                amsla.common.nullId(size(allNodes)), ...
                'VariableNames', {'NodeId', 'Tag'});
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
        
        % Component-level operations
        % :NOTE: this is going to be removed once partitioning is
        % refactored.
        
        function varargout = listOfComponents(obj)
            [varargout{:}] = obj.DataStructure.listOfComponents();
        end
        
        function outIds = rootsOfComponent(obj, componentIds)
            outIds = obj.DataStructure.rootsOfComponents(componentIds);
        end
        
        function outIds = componentOfNode(obj, nodeIds)
            outIds = obj.DataStructure.componentOfNode(nodeIds);
        end
        
        function computeComponents(obj)
            obj.DataStructure.computeComponents();
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
