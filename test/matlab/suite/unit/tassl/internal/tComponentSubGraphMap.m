classdef tComponentSubGraphMap < amsla.test.tools.AmslaTest
    %TCOMPONENTSUBGRAPHMAP Tests for class amsla.tassl.internal.ComponentSubGraphMap
    
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
    
    %% TEST METHODS
    
    methods (Test)
        
        function checkConstructor(testCase)
            % Check that a simple object can be initialised without any
            % problem.
            testCase.verifyWarningFree(@() iGetASimpleMap());
        end
        
        function checkListOfMergedComponents(testCase)
            % Check that the components are merged as expected.
            aMap = iGetASimpleMap();
            
            mergedComponentIds = [2, 3, 4, 5];
            testCase.verifyEqual(aMap.listOfMergedComponents(), mergedComponentIds);
        end
        
        function checkComponentToMergedComponent(testCase)
            % Check that component IDs are correctly translated to merged
            % component IDs.
            [aMap, componentIds] = iGetASimpleMap();
            
            mergedComponentIds   = [2, 3, 4, 5, 2, 2];
            testCase.verifyEqual(aMap.componentToMergedComponent(componentIds), mergedComponentIds);
        end
        
        function checkMergedComponentToComponent(testCase)
            % Check that merged component IDs are correctly translated to
            % component IDs.
            [aMap] = iGetASimpleMap();
            
            mergedComponentIds  = [2,         3, 4, 5, 2,         2];
            componentIds        = {[1, 2, 8], 3, 4, 5, [1, 2, 8], [1, 2, 8]};
            
            testCase.verifyEqual(aMap.mergedComponentToComponent(mergedComponentIds), componentIds);
        end
        
        function checkListOfSubGraphs(testCase)
            % Check that the list of sub-graphs is as expected
            aMap = iGetASimpleMap();
            
            subGraphIds = [1, 2, 3, 4, 5];
            testCase.verifyEqual(aMap.listOfSubGraphs(), subGraphIds);
        end
        
        function checkSubGraphsOfMergedComponent(testCase)
            % Check that the list of sub-graphs per merged component is as
            % expected
            aMap = iGetASimpleMap();
            
            subGraphIds = [2, 3];
            testCase.verifyEqual(aMap.subGraphsOfMergedComponent(3), subGraphIds);
        end
        
        function checkSubGraphsOfMergedComponentVector(testCase)
            % Check that the list of sub-graphs per merged component is as
            % expected, if the input is a vector
            aMap = iGetASimpleMap();
            
            subGraphIds = {1, [2, 3], 4, 5};
            testCase.verifyEqual(aMap.subGraphsOfMergedComponent([2, 3, 4, 5]), subGraphIds);
        end
        
        function checkAddElementToSubGraphSimultaneously(testCase)
            % Check that elements can be added to all sub-graphs
            % simultaneously
            aMap = iGetASimpleMap();
            
            allSubGraphs = aMap.listOfSubGraphs();
            aMap.addElementToSubGraph(allSubGraphs);
            testCase.verifyEqual(aMap.sizeOfSubGraph(allSubGraphs), ones(size(allSubGraphs)));
        end
        
        function checkAddElementToSubGraphSplillOver(testCase)
            % Check that elements can be added to one sub-graph until it
            % becomes full and the following are added to the next non-full
            % sub-graph in the same merged component.
            aMap = iGetASimpleMap();
            
            aMap.addElementToSubGraph(ones(1, 12)*2);
            testCase.verifyEqual(aMap.sizeOfSubGraph([2, 3]), [10, 2]);
        end
        
        function checkAddElementToSubGraphThrowsError(testCase)
            % Check that elements if the last sub-graph in a merged
            % component is filled, the method throws an error
            aMap = iGetASimpleMap();
            
            import matlab.unittest.constraints.Throws;
            testCase.verifyThat( ...
                @() aMap.addElementToSubGraph(ones(1, 11)*3), ...
                Throws(?MException));
        end
        
        function checkResetSubGraphs(testCase)
            % Check that the method resets all sub-graph sizes
            aMap = iGetASimpleMap();
            
            allSubGraphs = aMap.listOfSubGraphs();
            aMap.addElementToSubGraph(allSubGraphs);
            aMap.resetSubGraphs();
            testCase.verifyEqual(aMap.sizeOfSubGraph(allSubGraphs), zeros(size(allSubGraphs)));
        end
        
    end
    
end

function [aMap, componentIds, componentSizes, maxSize] = iGetASimpleMap()
componentIds   = [1, 3,  4, 5,  8, 2];
componentSizes = [2, 20, 5, 10, 3, 5];
maxSize = 10;
aMap = amsla.tassl.internal.ComponentSubGraphMap(componentIds, componentSizes, maxSize);
end