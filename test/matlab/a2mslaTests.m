function testResults = a2mslaTests(varargin)
%A2MSLATESTS(NAME, VALUE, ...) Execute all the tests in the A²MSLA test
%suite.
%
%   TR = A2MSLATESTS() Execute all the available tests. Returns the test
%   results.
%
%   TR = A2MSLATESTS(NAME, VALUE, ...) Execute the tests with added
%   settings. Currently supported name-value paris are:
%       'CodeCoverage'      - If true, prints out a code coverage report.
%

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

import matlab.unittest.TestSuite;
import matlab.unittest.TestRunner;
import matlab.unittest.plugins.CodeCoveragePlugin;

% Setup directories
matlabTestDir = extractTestDir();
matlabSourceDir = extractSourceDir();
oldPath = path();
addpath(matlabSourceDir);
addpath(matlabTestDir);
% Remove added directories at the end of tests
restorePath = onCleanup(@() path(oldPath));

% Test suite
suite = TestSuite.fromFolder(matlabTestDir, "IncludingSubfolders", true);

% Test runner
runner = TestRunner.withTextOutput("LoggingLevel", 3, "OutputDetail", 3);

% Check for plugin
if nargin==2 && strcmp(varargin{1}, "CodeCoverage") && varargin{2}
    runner.addPlugin(CodeCoveragePlugin.forFolder(matlabSourceDir, "IncludeSubFolders", true));
end

% Run tests
testResults = runner.run(suite);

end
