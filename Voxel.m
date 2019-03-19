classdef Voxel < handle
    properties
        dim;            %1D/2D/3D
        sep;            %separation between masses in the voxel
        origin;         %the "origin" of the voxel (for now, one corner)
        masses = [];    %an array of masses belonging to that voxel
        links = [];     %an array of links belonging to that voxel
    end
    methods
        %constructor
        function obj = Voxel(dim,sep,origin,matl)
            obj.dim = dim;
            obj.sep = sep;
            if length(origin) == dim
                obj.origin = origin;
            else
                error('invalid dimension');
            end

            %create and position masses appropriate to the dimension
            if dim == 1
                n_masses = 2;

                x_off = sep/2;

                for ix = -1:2:1
                    pos = origin + ix*x_off;
                    m = Mass(dim,pos,matl);
                    obj.masses = [obj.masses, m];
                end
            elseif dim == 2
                n_masses = 4;

                x_off = [1,0]*(sep/2);
                y_off = [0,1]*(sep/2);

                for ix = -1:2:1
                    for jx = -1:2:1
                        pos = origin + ix*x_off + jx*y_off;
                        m = Mass(dim,pos,matl);
                        obj.masses = [obj.masses, m];
                    end
                end

            elseif dim == 3
                n_masses = 8;

                x_off = [1,0,0]*(sep/2);
                y_off = [0,1,0]*(sep/2);
                z_off = [0,0,1]*(sep/2);

                for ix = -1:2:1
                    for jx = -1:2:1
                        for kx = -1:2:1
                            pos = origin + ix*x_off + jx*y_off + kx*z_off;
                            m = Mass(dim,pos,matl);
                            obj.masses = [obj.masses, m];
                        end
                    end
                end
            else
                error('invalid dimension');
            end

            %create links (structure of nested for loop ensures every pair is accounted for)
            for ix = 1:(n_masses - 1)
                for jx = (ix + 1):n_masses
                    lnk = Link(dim,matl); %create a new link object
                    lnk.add_masses(obj.masses(ix),obj.masses(jx)); %connect link to respective masses
                    obj.masses(ix).add_link(lnk);
                    obj.masses(jx).add_link(lnk);
                    obj.links = [obj.links, lnk]; %assign link to voxel object
                end
            end

        end

        function plot_voxel(obj,plot_links)
            %plot links = 0 don't plot links
            %plot links = 1 plot vertical/horizontal links only
            %plot links = 2 plot all links  

            %plot links
            for ix = 1:length(obj.links)
                lnk = obj.links(ix);
                if (lnk.rest_length == 1 && plot_links == 1) || (plot_links == 2)
                    lnk.plot_link();
                end
            end

            %plot masses
            for ix = 1:length(obj.masses)
                mass = obj.masses(ix);
                mass.plot_mass();
            end
        end
    end
end