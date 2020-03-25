function testResults = runAllAmslaTests(varargin)
%RUNALLAMSLATESTS(NAME, VALUE, ...) Execute all the tests in the AMSLA test
%suite.
%
%   TR = RUNALLAMSLATESTS() Execute all the available tests. Returns the test
%   results.
%
%   TR = RUNALLAMSLATESTS(NAME, VALUE, ...) Execute the tests with added
%   settings. Currently supported name-value paris are:
%       'CodeCoverage'      - If true, prints out a code coverage report.
%

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

import matlab.unittest.TestSuite;
import matlab.unittest.TestRunner;
import matlab.unittest.plugins.CodeCoveragePlugin;
import matlab.unittest.plugins.XMLPlugin;

% Setup directories
[setupStruct, restorePath] = amsla.test.tools.internal.testRunnerSetup(); %#ok<ASGLU>

% Test suite
concreteTests = fullfile(setupStruct.MatlabTestDir, "suite");
suite = TestSuite.fromFolder(concreteTests, "IncludingSubfolders", true);

% Test runner
runner = TestRunner.withTextOutput("LoggingLevel", 3, "OutputDetail", 3);

% Check for Code coverage plugin
if nargin==2 && strcmp(varargin{1}, "CodeCoverage") && varargin{2}
    runner.addPlugin(CodeCoveragePlugin.forFolder(matlabSourceDir, ...
        "IncludeSubFolders", true));
end

% Write output to XML
xmlFolder = fullfile(tempdir, "testResults");
iCreateFolder(xmlFolder);
xmlFile = fullfile(xmlFolder, "junit.xml");
runner.addPlugin(XMLPlugin.producingJUnitFormat(xmlFile));

% Run tests
testResults = runner.run(suite);

% Check test output
failedTests = [testResults.Failed];
assert(~any(failedTests), "Some test failures occurred.");
end

%% HELPER FUNCTIONS

function iCreateFolder(xmlFolder)
if exist(xmlFolder, 'dir')~=7
    mkdir(xmlFolder);
end
end