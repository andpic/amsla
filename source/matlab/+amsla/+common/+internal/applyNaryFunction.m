function result = applyNaryFunction(functionToApply, dataIn, varargin)
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

numArguments = numel(varargin)+1;

if ~iscell(dataIn)
    result = functionToApply(dataIn, varargin{:});
else
    result = cell(size(dataIn));    
    currArguments = cell(1, numArguments);
    
    for k = 1:numel(dataIn)
        [currArguments{:}] = iSelectArguments(k, dataIn, varargin{:});
        result{k} = functionToApply(currArguments{:});
    end
end
end

%% HELPER FUNCTION

function varargout = iSelectArguments(index, varargin)
numInputs = numel(varargin);
varargout = cell(1, numInputs);

for k = 1:numInputs
    currArgument = varargin{k};
   if ~iscell(currArgument) && isscalar(currArgument)
       varargout{k} = currArgument;
   elseif ~iscell(currArgument) && ~isscalar(currArgument)
       varargout{k} = currArgument(index);
   else
       varargout{k} = currArgument{index};
   end   
end
end