classdef tAnalysis < hA2mslaTest
    %TANALYSIS Tests for the class a2msla.tassl.Analysis
    
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
    
    %% Manage corner cases for a single root in the sub-graph
    methods (Test)
        function manages_single_root_in_sub_graph(~)
            % Check that distributing the roots into the sub-graphs does
            % not give an error if there is only one root in the whole graph.
            
            aMatrix =  gallery('poisson', 10);
            aMatrix = tril(aMatrix);
            [I, J, V] = find(aMatrix);
            subGraphSize = 10;
            
            objectUnderTest = a2msla.tassl.Analysis(I, J, V, subGraphSize);
            objectUnderTest.partition();
        end
    end
end