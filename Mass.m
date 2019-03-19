classdef Mass < handle
    properties
        index;      %the index of the mass in the state variable array
        mass;       %the mass of the mass (inherited from material)
        pos;        %the position at a given point in time
        pos_rest;   %the rest position of the mass
        pos_init;   %the initial position of the mass
        vel;        %the velocity at a given point in time
        vel_rest;   %the rest velocity of the mass
        vel_init;   %the initial velocity of the mass
        links = []; %an array of links associated with the mass
        fixed = false; %is the mass fixed?
        clr;        %the color of the mass (inherited from material)
        wt = 1;     %the weight factor used when averaging multiple masses
        dim;        %inherited from body
    end
    methods
        %constructor for a mass
        function obj = Mass(dim,pos_rest,matl)
            obj.mass = matl.m;
            obj.clr = matl.clr;

            if length(pos_rest) == dim
                obj.pos_rest = pos_rest;
                obj.pos_init = pos_rest;
                obj.pos = pos_rest;
            else
                error('invalid dimension');
            end
            
            obj.vel_rest = zeros(1,dim); %makes a rest velocity vector of the correct dimension
            obj.vel_init = zeros(1,dim);
            obj.vel = zeros(1,dim);
            obj.dim = dim;
        end

        function obj = add_link(obj,new_link)
            obj.links=[obj.links,new_link]; %append the new link to the existing list
        end

        function obj = plot_mass(obj)
            if obj.dim == 1
                plot(obj.pos_rest(1),0,'.','MarkerSize',30,'Color',obj.clr);
            elseif obj.dim == 2
                plot(obj.pos_rest(1),obj.pos_rest(2),'.','MarkerSize',30,'Color',obj.clr);
            else %dim == 3
                plot3(obj.pos_rest(1),obj.pos_rest(2),obj.pos_rest(3),'.','MarkerSize',30,'Color',obj.clr);
            end
        end
    end
end