classdef(Abstract) SelectChildrenIfReady < handle
    %AMSLA.TASSL.INTERNAL.SELECTCHILDRENIFREADY A mixin that helps finding
    %out which children nodes are ready to be processed.
    
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
    
    %% ABSTRACT METHODS
    
    methods(Abstract, Access=protected)
        
        % A method executing a function on the parents of a node.
        isReady = computeBasedOnParents(obj, nodeIds, isReadyFcn);
        
        % Get the DataStructure object
        dataStructure = getDataStructure(obj);
        
    end
    
    %% PROTECTED METHODS
    
    methods(Access=protected)
        
        function nodeIds = selectChildrenIfReady(obj, currentNodeIds, isReadyFcn)
            %SELECTCHILDRENIFREADY Select the children of the input nodes if
            %they satisfy the given function.
            
            % Find children of current nodes
            dataStructure = obj.getDataStructure();
            nodeIds = dataStructure.childrenOfNode(currentNodeIds);
            nodeIds = unique(amsla.common.numericArray(nodeIds));
            
            % Find out which ones are ready
            isChildReady = obj.computeBasedOnParents(nodeIds, isReadyFcn);
            nodeIds = nodeIds(isChildReady);
        end
        
    end
end