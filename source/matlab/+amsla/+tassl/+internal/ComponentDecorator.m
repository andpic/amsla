classdef ComponentDecorator < amsla.tassl.internal.DataStructureDecorator
    
    
    properties(SetAccess=immutable)
        TagName
    end
    
    methods(Access=public)
        function obj = ComponentDecorator(aDataStructure)
            tagName = "Component";
            obj = obj@amsla.tassl.internal.DataStructureDecorator(aDataStructure, tagName);
            obj.TagName = tagName;
        end
        
        function [componentId, numOfNodes] = listOfComponents(obj)
            [componentId, numOfNodes] = obj.listOfTags(obj.TagName);
        end
        
        function componentId = componentOfNode(obj, nodeId)
            componentId = obj.tagOfNode(obj.TagName, nodeId);
        end
        
        function setComponentOfNode(obj, nodeId, componentId)
            obj.setTagOfNode(obj.TagName, nodeId, componentId);
        end
    end
end