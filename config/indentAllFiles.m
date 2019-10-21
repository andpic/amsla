function indentAllFiles()
%INDENTALLFILES Indent all the MATLAB files in the repository.

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

currentFolder = string(pwd);
returnToFolder = onCleanup(@() cd(currentFolder));

cd ..;
matchingFiles = [ ...
    iListFilesToIndent("source");
    iListFilesToIndent("test");
    iListFilesToIndent("examples");
    iListFilesToIndent("config");
    ];
arrayfun(@edit, matchingFiles);
editorFileHandles = matlab.desktop.editor.getAll;
editorFileHandles.smartIndentContents;
arrayfun(@save, editorFileHandles);
end

%% HELPER FUNCTIONS

function fileList = iListFilesToIndent(folderName)
currentFolder = string(pwd);
returnToFolder = onCleanup(@() cd(currentFolder));

ext = ".m";

% Get all the entry names
cd(folderName);
allEntries = dir(pwd);
allNames = string({allEntries.name}');
isFolder = [allEntries.isdir]';

% Exclude the folders ".." and "."
entriesToExclude = startsWith(allNames, ".");
allNames(entriesToExclude) = [];
isFolder(entriesToExclude) = [];

fileList = fullfile(currentFolder, folderName, ...
    allNames(endsWith(allNames, ext) & ~isFolder));
subFolders = allNames(isFolder);

for k = 1:numel(subFolders)
    fileList = [ fileList; ...
        iListFilesToIndent(subFolders(k)) ]; %#ok<AGROW>
end
end