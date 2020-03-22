classdef test_Partitioner < amsla.test.shared.PartitionerTests
    %TEST_PARTITIONER Tests for the class amsla.tassl.Partitioner
    
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
    
    methods(Access=protected, Static)
        
        function analyserObject = createPartitionerObject(underlyingObject, maxSubGraphSize)
            analyserObject = amsla.tassl.Partitioner(underlyingObject, maxSubGraphSize);
        end
        
    end
end