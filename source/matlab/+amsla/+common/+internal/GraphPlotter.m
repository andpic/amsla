classdef GraphPlotter < handle
    %AMSLA.COMMON.GRAPHPLOTTER Control the plot of graph objects.
    %
    %   Methods of GRAPHPLOTTER:
    %   	plot           - Plots or updates the plot of a graph
    
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
    
    %% PRIVATE PROPERTIES
    
    properties(Access=private)
        
        %Handle to the graph plot object
        PlotHandle
        
        %Handle to the axes object
        AxesHandle
        
    end
    
    %% PUBLIC METHDOS
    
    methods(Access=public)
        
        function obj = GraphPlotter(varargin)
            %GRAPHPLOTTER Construct a GraphPlotter object.
            
            obj.AxesHandle = iParseConstructorArguments(varargin{:});
            obj.PlotHandle = [];
        end
        
        function plotHandle = plot(obj, graphObject)
            %PLOT Plot the graph using the GraphPlotter object
            
            if ~isvalid(obj.AxesHandle)
                error("The axes used for plotting the graph are not valid anymore");
            end
            
            % Save formatting
            titleText = copy(obj.AxesHandle.Title);
            
            % Plot the graph
            obj.PlotHandle = graphObject.plot(obj.AxesHandle);
            plotHandle = obj.PlotHandle;
            drawnow limitrate nocallbacks;
            
            % Restore format
            set(obj.AxesHandle, 'Title', titleText);
        end
        
    end
    
end

%% HELPER FUNCTIONS

function [axesHandle] = iParseConstructorArguments(varargin)
parser = inputParser;
addOptional(parser, 'AxesHandle', gca(), ...
    @(x) isa(x, 'matlab.graphics.axis.Axes') && isscalar(x) && isvalid(x));

parser.parse(varargin{:});
axesHandle = parser.Results.AxesHandle;
end
