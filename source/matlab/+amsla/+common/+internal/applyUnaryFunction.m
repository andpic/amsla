function result = applyUnaryFunction(functionToApply, dataIn)
%AMSLA.COMMON.INTERNAL.APPLYUNARYFUNCTION Apply a unary function to all
%elements of a numerical array or cell array.

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

assert(nargin(functionToApply)==1 && nargout(functionToApply)==1);

if ~iscell(dataIn)
    result = functionToApply(dataIn);
else
    result = cell(size(dataIn));
    for k = 1:numel(dataIn)
        result{k} = ...
            functionToApply(dataIn{k});
    end
end
end