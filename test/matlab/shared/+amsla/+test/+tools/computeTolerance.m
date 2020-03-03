function tol = computeTolerance(toleranceType, complexityFcn, varargin)
    %AMSLA.TEST.TOOLS.COMPUTETOLERANCE A test tool that computes the
    %tolerance to be used in numerical verifications
    %
    % TOL = AMSLA.TEST.TOOLS.COMPUTETOLERANCE(TYPE, C, D)
    %   Compute the tolerance of type TYPE ("Absolute" or "Relative") based
    %   on the complexity function C applied to the input data D.
    %   The complexity function C can have more than one input, and each
    %   input matches one of the arguments after it.
    %   
    % TOL = AMSLA.TEST.TOOLS.COMPUTETOLERANCE(TYPE, C, D1, D2)
    %   Compute the tolerance based on a function of D1 and D2 representing
    %   the complexity of an algorithm.
    %
    % In general, the tolerance obtained with this function is given by
    %   TOL = EPS(dataType(D1))*C(D1, D2, ...)
    
    % Copyright 2020 Andrea Picciau
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
    
end