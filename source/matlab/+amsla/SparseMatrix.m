classdef SparseMatrix
    %AMSLA.SPARSEMATRIX A sparse matrix in the AMSLA framework.
    %
    %   M = AMSLA.SPARSEMATRIX(I, J, V, FORMAT) Create a sparse matrix in
    %   the format FORMAT from the triplet I, J, V.
    %
    %   M = AMSLA.SPARSEMATRIX(A, FORMAT) Create a sparse matrix in the
    %   format FORMAT from MATLAB's sparse matrix A.
    
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
    
    %% PROPERTIES
    
    properties(GetAccess=public, SetAccess=private)
        
        %Name of the storage format.
        Format
        
    end
    
    properties(Access=private)
        
        %Data structure associated with the storage format.
        DataStructure
        
        %Partitioner used to analyse the matrix.
        Partitioner
        
        %Scheduler used to analyse the matrix.
        Scheduler
        
    end
    
    %% PUBLIC METHODS
    
    methods
        
        function obj = SparseMatrix(varargin)
            %SPARSEMATRIX Construct an instance of this class
            
            [I, J, V, obj.Format] = ...
                iParseConstructorArguments(varargin{:});
            objConstructor = iGetPackageObject("DataStructure", obj.Format);
            obj.DataStructure = objConstructor(I, J, V);
        end
        
        function [obj, partitioningResults] = analyse(obj, varargin)
            %ANALYSE Analyse the input matrix.
            
            [maxSize, plotProgress] = iParseAnalyseArguments(varargin{:});
            
            obj = obj.setupAnalysisAccordingToFormat(maxSize, plotProgress);
            partitioningResults = obj.Partitioner.partition();
            obj.Scheduler.scheduleOperations();
        end
        
    end
    
    %% PRIVATE METHDOS
    
    methods(Access=private)
        
        function obj = setupAnalysisAccordingToFormat(obj, maxSize, plotProgress)
            % Choose partitioner and scheduler according to the storage
            % format.
            
            partitionerConstructor = iGetPackageObject("Partitioner", obj.Format);
            obj.Partitioner = partitionerConstructor(...
                obj.DataStructure, ...
                maxSize, ...
                "PlotProgress", plotProgress);
            
            schedulerConstructor = iGetPackageObject("Scheduler", obj.Format);
            obj.Scheduler = schedulerConstructor(obj.DataStructure);
        end
        
    end
end

%% HELPER METHODS

function [I, J, V, format] = iParseConstructorArguments(varargin)
% Parse the inputs to the constructor

if nargin==2
    % If the input is a sparse MATLAB matrix, extract row indices, column
    % indices, and values
    sparseMatrix = varargin{1};
    validateattributes(sparseMatrix, ...
        {'numeric'}, {'sparse', 'square', 'nonempty'});
    [I, J, V] = find(sparseMatrix);
    
    format = varargin{2};
elseif nargin==4
    % Input is the matrix elements in the coordinate form
    I = varargin{1};
    J = varargin{2};
    V = varargin{3};
    
    requiredAttributes = {'vector', 'nonsparse', 'finite', 'nonempty', 'numel', numel(I)};
    validateattributes(I, {'numeric'}, requiredAttributes);
    validateattributes(J, {'numeric'}, requiredAttributes);
    validateattributes(V, {'numeric'}, requiredAttributes);
    
    format = varargin{4};
else
    error("amsla:badInputs", "Bad inputs to the matrix constructor");
end

% Validate the matrix format
validateattributes(format, {'string', 'char'}, {'nonempty', 'scalartext'});
format = validatestring(format, iGetSupportedFormats());
end

function [maxSize, plotProgress] = iParseAnalyseArguments(varargin)
% Parse the inputs to the method "analyse"

parser = inputParser;
addOptional(parser,'MaxSize', [], @(x) isnumeric(x) && isscalar(x));
addParameter(parser,'PlotProgress', false, @(x) islogical(x) && isscalar(x));

parse(parser, varargin{:});

maxSize = parser.Results.MaxSize;
plotProgress = parser.Results.PlotProgress;
end

function formatList = iGetSupportedFormats()
% Return the list of supported formats.

% Find all amsla.* packages, remove those about tests and common
% interfaces.
mainPackage = meta.package.fromName("amsla");
amslaPackages = mainPackage.PackageList;
amslaPackageNames = string({amslaPackages.Name}');
amslaPackageNames(amslaPackageNames == "amsla.test" | amslaPackageNames == "amsla.common") = ...
    [];
formatList = erase(amslaPackageNames, "amsla.");
end

function objectConstructor = iGetPackageObject(objectName, formatName)
% Get the required object given the format/amsla package name. If the
% object is not available in the package, search in the "common" package.

fullObjectName = "amsla." + formatName + "." + objectName;
if ~exist(fullObjectName, "class")
    fullObjectName = "amsla.common." + objectName;
end
objectConstructor = str2func(fullObjectName);
end