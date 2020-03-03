classdef ComponentPartitioner
    
    properties(Access=private)
        DataStructure
        
        Component table
    end
    
    
    methods(Access=public)
        
        function obj = ComponentPartitioner(dataStructure)
            obj.DataStructure = dataStructure;
            
            allNodes = dataStructure.listOfNodes;
            obj.Component = table(allNodes, amsla.common.nullId(numel(allNodes)), ...
                'VariableNames', {'NodeId', 'ComponentId'});
        end
        
        function [componentId, numOfNodes] = listOfComponents(obj)
            %LISTOFCOMPONENTS(C) Get the IDs of components in the graph.
            %
            %   C = LISTOFCOMPONENTS(C) Get the IDs of the components
            %   only.
            %
            %   [C, NC] = LISTOFCOMPONENTS(C) Get the IDs and the number of
            %   nodes in each component.
            
            componentId = unique(obj.Component.ComponentId);
            numOfNodes = sum(obj.Component.ComponentId == componentId');
            componentId = iRowVector(componentId);
            numOfNodes = iRowVector(numOfNodes);
        end
        
        function outIds = rootsOfComponent(obj, componentIds)
            %ROOTSOFCOMPONENT(G, ID) Get the IDs of the nodes without a
            %parent in one or more components.
            
            [componentIds, ~, invSorter] = unique(componentIds);
            
            rootNodes = arrayfun(@parentlessNodesInComponent, componentIds, ...
                'UniformOutput', false);
            outIds = rootNodes(invSorter);
            
            function rootNodes = parentlessNodesInComponent(componentId)
                % Get the nodes in the given component ID that don't have
                % parents.
                
                nodesInComponent = ...
                    obj.Component.NodeId(obj.Component.ComponentId == componentId);
                parentsOfNodes = obj.DataStructure.parentsOfNode(nodesInComponent);
                if iscell(parentsOfNodes)
                    rootNodes = nodesInComponent( ...
                        cellfun(@isempty, parentsOfNodes, 'UniformOutput', true));
                else
                    rootNodes = nodesInComponent(isempty(parentsOfNodes));
                end
            end
        end
        
        function outIds = componentOfNode(obj, nodeIds)
            %COMPONENTOFNODE(G, ID) Get the component IDs of one or more nodes.
            
            [nodeIds, ~, invSorter] = unique(nodeIds);
            outIds = obj.Component.ComponentId(obj.Component.NodeId == nodeIds);
            outIds = outIds(invSorter);
        end
        
        function computeComponents(obj)
            %COMPUTECOMPONENTS(G) Compute the weakly-connected components in
            %the graph.
            whichComponent = conncomp(obj.BaseGraph, 'Type', 'weak');
            obj.BaseGraph.Nodes.ComponentId = whichComponent';
        end
        
    end
    
    methods(Access=private)
        
        
    end
end

%% HELPER FUNCTIONS

function dataOut = iRowVector(dataIn)
dataOut = reshape(dataIn, 1, []);
end