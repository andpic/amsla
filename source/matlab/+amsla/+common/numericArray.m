function dataOut = numericArray(dataIn)
%AMSLA.COMMON.NUMERICARRAY Turn cell arrays into numeric arrays.

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

dataOut = dataIn;
if iscell(dataOut)
    dataOut = amsla.common.rowVector(cell2mat(dataOut));
end
end