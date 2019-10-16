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
            
            [obj.DataStructure, obj.Format] = ...
                iParseConstructorArguments(varargin{:});
        end
        
        function [obj, partitioningResults] = analyse(obj, varargin)
            %ANALYSE Analyse the input matrix.
            
            [maxSize, plotProgress] = iParseAnalyseArguments(varargin{:});
            
            obj = obj.setupAnalysisAccordingToFormat(maxSize, plotProgress);
            partitioningResults = obj.Partitioner.partition();
        end
        
    end
    
    %% PRIVATE METHDOS
    
    methods(Access=private)
        
        function obj = setupAnalysisAccordingToFormat(obj, maxSize, plotProgress)
            % Choose partitioner and scheduler according to the storage
            % format.
            
            switch obj.Format
                case "TASSL"
                    obj.Partitioner = amsla.tassl.Partitioner(obj.DataStructure, ...
                        maxSize, ...
                        "PlotProgress", plotProgress);
                    obj.Scheduler = amsla.tassl.Scheduler(obj.DataStructure);
                case "Level-set"                    
                    obj.Partitioner = amsla.levelSet.Partitioner(obj.DataStructure, ...
                        maxSize, ...
                        "PlotProgress", plotProgress);
                    obj.Scheduler = [];
                otherwise
                    error("amsla:invalidFormat", "Invalid matrix format.");
            end
        end
        
    end
end

%% HELPER METHODS

function [dataStructure, format] = iParseConstructorArguments(varargin)
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
validatestring(format, ...
    ["TASSL", "Level-set"]);

format = string(format);
dataStructure = amsla.common.EnhancedGraph(I, J, V);
end

function [maxSize, plotProgress] = iParseAnalyseArguments(varargin)
parser = inputParser;
addOptional(parser,'MaxSize', [], @(x) isnumeric(x) && isscalar(x));
addParameter(parser,'PlotProgress', false, @(x) islogical(x) && isscalar(x));

parse(parser, varargin{:});

maxSize = parser.Results.MaxSize;
plotProgress = parser.Results.PlotProgress;
end