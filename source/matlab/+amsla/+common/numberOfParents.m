function num = numberOfParents(dataStructure, nodeIds)
%AMSLA.COMMON.NUMBEROFPARENTS(P, NID) Number of parents of the given nodes,
%given their IDs.

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

parentsOfNodes = dataStructure.parentsOfNode(nodeIds);
if iscell(parentsOfNodes)
    num = cellfun(@numel, parentsOfNodes, 'UniformOutput', true);
else
    num = numel(parentsOfNodes);
end
end