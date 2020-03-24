function currentResults = runAllAmslaPerformanceTests()
%RUNALLAMSLAPERFORMANCETESTS(NAME, VALUE, ...) Execute all the performance tests
% in the AMSLA test suite.
%
%   TR = RUNALLAMSLAPERFORMANCETESTS() Execute all the available tests. 
%       Returns the test results.
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

% Setup directories
[setupStruct, restorePath] = amsla.test.tools.internal.testRunnerSetup(); %#ok<ASGLU>

% Test suite
testFolder = fullfile(setupStruct.MatlabTestDir, "suite", "performance");

% Current performance results
currentResults = iRunPerformanceTest(testFolder);
fileName = fullfile(iResultsFolder(), "CurrentResults.csv");
iWriteResults(currentResults, fileName);

% Previous performance results
if iGoToPreviousCommit()
    returnToCommit = onCleanup(@() iGoBackToCurrentCommit());
    
    previousResults = iRunPerformanceTest(testFolder);
    
    % Write previous results to log
    fileName = fullfile(iResultsFolder(), "PreviousResults.csv");
    iWriteResults(previousResults, fileName);
    
    % Plot a comparison figure
    fileName = fullfile(iResultsFolder(), "Comparison.png");
    compFigure = iCompareResults(previousResults, currentResults);
    exportgraphics(compFigure, fileName, "Resolution", 300);
end
end

%% HELPER FUNCTIONS

function success = iGoToPreviousCommit()
[~, message] = system("git checkout HEAD~1");
success = iGitSuccess(message);
end

function success = iGoBackToCurrentCommit()
[~, message] = system("git checkout -");
success = iGitSuccess(message);
end

function tf = iGitSuccess(message)
tf = contains(message, "HEAD is now at");
end

function testResults = iRunPerformanceTest(testFolder)
% Run the performance test and get data with a confidence interval of 95%

import matlab.unittest.TestSuite;
import matlab.unittest.TestRunner;

testSuite = TestSuite.fromFolder(testFolder, "IncludingSubfolders", true);
experiment = matlab.perftest.TimeExperiment.limitingSamplingError();
testResults = run(experiment, testSuite);
end

function compFigure = iCompareResults(previousResults, currentResults)
compFigure = comparisonPlot(previousResults, currentResults, ...
    'SimilarityTolerance', 0.05, ...
    'Scale', 'log');
end

function resultsFolder = iResultsFolder()
resultsFolder = fullfile(tempdir, "testResults");
if ~iFolderExists(resultsFolder)
    mkdir(resultsFolder);
end
end

function iWriteResults(testResults, logFile)
fullTable = vertcat(testResults.Samples);
summaryStats = varfun(@min, fullTable,...
    'InputVariables', 'MeasuredTime', 'GroupingVariables', 'Name');
writetable(summaryStats, logFile);
end

function tf = iFolderExists(folderName)
tf = exist(folderName, 'dir') == 7;
end
