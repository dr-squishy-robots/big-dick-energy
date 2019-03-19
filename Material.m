classdef Material < handle
%speeds up the creation of different voxel types
    properties
        k; %stiffness
        b; %damping
        m; %mass
        clr; %the color (will be used to plot the masses/links of that mat'l)
    end
    methods
        %constructor
        function obj = Material(k,b,m,clr)
            obj.k = k;
            obj.b = b;
            obj.m = m;

            %color is an optional argument, grey by default
            if nargin < 4 %if the number of arguments to the function is less than 4, for example matl = Material(1,1,1)
                obj.clr = [0.3,0.3,0.3]; %clr is grey by default
            else
                obj.clr = clr; %else, if 4 arguments, eg. matl = Material(1,1,1,[r,g,b]), that [r,g,b] triplet is stored as clr
            end
        end
    end
end