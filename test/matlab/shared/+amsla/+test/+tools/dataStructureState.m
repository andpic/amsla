function edgesTable = dataStructureState(aDataStructure)
%DATASTRUCTURESTATE Returns a table to represent the status of the
%DataStructure.

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

edgesTable = [];

allEdges = aDataStructure.listOfEdges();
% Corner case
if isempty(allEdges)
    return;
end

J = aDataStructure.enteringNodeOfEdge(allEdges)';
I = aDataStructure.exitingNodeOfEdge(allEdges)';
weights = aDataStructure.weightOfEdge(allEdges);
subGraphI = aDataStructure.subGraphOfNode(I);
subGraphJ = aDataStructure.subGraphOfNode(J);
timeSlot = aDataStructure.timeSlotOfEdge(allEdges);

edgesTable = table(I, J, timeSlot, subGraphI, subGraphJ, weights);
end