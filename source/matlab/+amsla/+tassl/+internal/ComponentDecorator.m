classdef ComponentDecorator < amsla.common.DataStructureDecorator
    %AMSLA.TASSL.INTERNAL.COMPONENTDECORATOR A DataStructure decorator that
    %associates graph nodes to graph components.
    %
    %   AMSLA.TASSL.INTERNAL.COMPONENTDECORATOR decoration methods:
    %      listOfComponents     - Get the list of the component IDs in the
    %                             graph.
    %      componentsOfNode     - Get the ID of the component of nodes.
    %      setComponentOfNode   - Associate a node with a component.
    
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
    
    properties(SetAccess=immutable)
        
        % Name of the node tag used by the decorator
        TagName
        
    end
    
    %% PUBLIC METHODS
    
    methods(Access=public)
        
        function obj = ComponentDecorator(aDataStructure)
            %COMPONENTDECORATOR(DS) Decorate the DataStructure object DS to
            %deal with components.
            
            tagName = "Component";
            obj = obj@amsla.common.DataStructureDecorator(aDataStructure, tagName);
            obj.TagName = tagName;
        end
        
        function [componentId, numOfNodes] = listOfComponents(obj)
            %LISTOFCOMPONENTS(D) Retireve a list of component IDs in the
            %graph.
            
            [componentId, numOfNodes] = obj.listOfTags(obj.TagName);
        end
        
        function componentId = componentOfNode(obj, nodeId)
            %COMPONENTOFNODE(D, NID) Get the component ID of node NID.
            
            componentId = obj.tagOfNode(obj.TagName, nodeId);
        end
        
        function setComponentOfNode(obj, nodeId, componentId)
            %SETCOMPONENTOFNODE(D, NID, CID) Associate node NID with the
            %component CID.
            
            obj.setTagOfNode(obj.TagName, nodeId, componentId);
        end
        
    end
end