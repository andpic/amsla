function [setupStruct, restorePath] = testRunnerSetup()
%AMSLA.TEST.TOOLS.INTERNAL.TESTRUNNERSETUP Setup the MATLAB environment to
%run any type of test.

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

% Setup directories
matlabTestDir = amsla.test.tools.internal.extractTestDir();
matlabSourceDir = amsla.test.tools.internal.extractSourceDir();

% Add directories to the path
oldPath = path();
addpath(matlabSourceDir);
sharedTestDir = fullfile(matlabTestDir, "shared");
addpath(sharedTestDir);

% Remove added directories at the end of tests
restorePath = onCleanup(@() path(oldPath));

% Return a struct with the setup info
setupStruct = struct( ...
    "MatlabTestDir", matlabTestDir, ...
    "MatlabSourceDir", matlabSourceDir, ...
    "SharedTestDir", sharedTestDir);
end