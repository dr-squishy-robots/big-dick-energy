classdef Body < handle
    properties
        dim;
        voxels = [];
        masses = [];
        links = [];
    end
    methods
        %constructor simply makes an EMPTY body of a certain dim
        function obj = Body(dim)
            %set number of dimensions
            obj.dim = dim;
        end

        function obj = index_masses(obj)
            for ix = 1:length(obj.masses)
                %assign a unique index value to each mass OBJECT -> corresponds to its position in the state variable list
                obj.masses(ix).index = ix;
            end
        end

        function obj = add_voxel(obj,sep,origin,matl)
            new_voxel = Voxel(obj.dim,sep,origin,matl); %creates a new voxel called "new_voxel"
            obj.voxels = [obj.voxels, new_voxel]; %appends the new voxel to the body

            %iterate thru the masses in the new voxel, and compare them to existing masses in the body, and merge duplicates
            for ix = 1:length(new_voxel.masses) %for each mass in the new voxel
                new_voxel_mass = new_voxel.masses(ix);%select the relevant mass in the new voxel
                unique_mass = true; %assume the mass is unique unless proven otherwise

                for jx = 1:length(obj.masses) %for each mass already in the body
                    body_mass = obj.masses(jx); %select each mass in the body

                    %two masses are identical if their rest positions are identical

                    %NOTE: if this doesn't work, add error tolerance to account for floating point errors
                    %if norm(new_voxel_mass.pos_rest - body_mass.pos_rest) < 10*eps;
                    if new_voxel_mass.pos_rest == body_mass.pos_rest
                        %if the new voxel mass has a duplicate in the body:

                        %1. the mass is not unique (don't add it to the body)
                        unique_mass = false;

                        %2. average the masses and colors of the two point masses and save them to body_mass (the one we're gonna keep)
                        %however, we can't just use a direct average, as more than 2 masses will be averaged, and so the result would become order-dependent
                        %solution: use weighted average, where each mass has a weight that increases every time it gets merged
                        body_mass.mass = (body_mass.wt*body_mass.mass + new_voxel_mass.mass)/(body_mass.wt + 1);
                        body_mass.clr = (body_mass.wt*body_mass.clr + new_voxel_mass.clr)./(body_mass.wt + 1);
                        body_mass.wt = body_mass.wt + 1; %update the weight

                        %3. find all links connected to the duplicate new voxel mass and replace their mass objects with the mass already in the body
                        for kx = 1:length(new_voxel_mass.links)
                            relevant_link = new_voxel_mass.links(kx); %select the relevant link
                            %determine if the new voxel mass is m_a or m_b for that link
                            if relevant_link.m_a == new_voxel_mass
                                %the new voxel mass is stored as m_a in the link: replace it
                                relevant_link.m_a = body_mass;
                            else
                                %the new voxel mass is stored as m_b in the link: replace it
                                relevant_link.m_b = body_mass;
                            end
                        end

                        %4. append the voxel mass links to the body mass
                        %note this may cause duplicate links, but it gets resolved later
                        body_mass.links = [body_mass.links new_voxel_mass.links];

                        %5. replace voxel mass object with body mass object
                        new_voxel.masses(ix) = body_mass;
                    end
                end

                if unique_mass
                    %add it to the body because it's not there yet
                    obj.masses = [obj.masses new_voxel_mass];
                end
            end

            %iterate thru the links in the new voxel, compare them to existing links in the body, and merge duplicates

            for ix = 1:length(new_voxel.links) %for each link in the new voxel
                new_voxel_link = new_voxel.links(ix); %select each relevant link
                unique_link = true; %assume a link is unique unless proven otherwise

                %at this point, all end masses should be the correct for all links, however, duplicate links may exist
                %to fix that, for each new voxel link, iterate through each link already in the body and check for duplicates
                for jx = 1:length(obj.links)
                    body_link = obj.links(jx); %extract each link already in the body


                    %two links are the same if their end masses are the same - however, the order of those masses can be flipped
                    if ((new_voxel_link.m_a == body_link.m_a) && (new_voxel_link.m_b == body_link.m_b)) || ((new_voxel_link.m_a == body_link.m_b) && (new_voxel_link.m_b == body_link.m_a))
                        %if two links are the same:
                    
                        %1. the link is not unique (don't add it to the body)
                        unique_link = false;

                        %2. average the stiffness, damping, and color of the two links, and save them to body_link (the one we're gonna keep)
                        %see masses for explanation of weighting (body_link.wt)
                        body_link.k = (body_link.wt*body_link.k + new_voxel_link.k)/(body_link.wt + 1);
                        body_link.b = (body_link.wt*body_link.b + new_voxel_link.b)/(body_link.wt + 1);
                        body_link.clr = (body_link.wt.*body_link.clr + new_voxel_link.clr)./(body_link.wt + 1); %element-wise averaging of rgb
                        body_link.wt = body_link.wt + 1; %update the weight

                        %3(a). delete the duplicate (voxel) link for for m_a of that (voxel) link
                        %because both masses already have both links
                        for kx = 1:length(new_voxel_link.m_a.links)
                            m_a_link = new_voxel_link.m_a.links(kx);
                            if m_a_link == new_voxel_link
                                %at this point, kx is the index value representing the new voxel link in mass m_a 
                                %(and we want to delete it)
                                index = kx;
                            end
                        end

                        %if index = 1 or index = end, this is a problem, so, 3 cases:
                        if index == 1 %if the link is stored as the fist one
                            new_voxel_link.m_a.links = new_voxel_link.m_a.links(2:end);
                        elseif index == length(new_voxel_link.m_a.links)%if the link is stored as the last one
                            new_voxel_link.m_a.links = new_voxel_link.m_a.links(1:(end-1));
                        else %the link is stored somewhere in the middle
                            new_voxel_link.m_a.links = [new_voxel_link.m_a.links(1:(index-1)),new_voxel_link.m_a.links((index+1):end)];
                        end

                        %3(b). delete the duplicate link for for m_b of that link
                        %because both masses already have both links
                        for kx = 1:length(new_voxel_link.m_b.links)
                            m_b_link = new_voxel_link.m_b.links(kx);
                            if m_b_link == new_voxel_link
                                %at this point, kx is the index value representing the new voxel link in mass m_b 
                                %(and we want to delete it)
                                index = kx;
                            end
                        end

                        %if index = 1 or index = end, this is a problem, so, 3 cases:
                        if index == 1 %if the link is stored as the fist one
                            new_voxel_link.m_b.links = new_voxel_link.m_b.links(2:end);
                        elseif index == length(new_voxel_link.m_b.links)%if the link is stored as the last one
                            new_voxel_link.m_b.links = new_voxel_link.m_b.links(1:(end-1));
                        else %the link is stored somewhere in the middle
                            new_voxel_link.m_b.links = [new_voxel_link.m_b.links(1:(index-1)),new_voxel_link.m_b.links((index+1):end)];
                        end

                        %4. replace the link in the voxel
                        new_voxel.links(ix) = body_link;
                        
                    end
                end

                if unique_link
                    %add it to the body because it's not there yet
                    obj.links = [obj.links new_voxel_link];
                end
            end
        end

        function obj = add_multi_voxel(obj,sep,origin,lwh,matl)
            %here, origin is the point from which this method will run

            %lwh (length width height) is a vector that must match dim
            if obj.dim ~= length(lwh)
                error('you done fucked up son')
            end

            %objective:
            %1. calculate the appropriate origin for each voxel given sep
            %2. use the add_voxel method to create each voxel
            if obj.dim == 1
                nx = lwh;
                for ix = 1:nx
                    x = origin(1) + sep*(ix-1);
                    obj.add_voxel(sep,x,matl);
                end
            elseif obj.dim == 2
                nx = lwh(1);
                ny = lwh(2);
                for ix = 1:nx
                    for jx = 1:ny
                        x = origin(1) + sep*(ix-1);
                        y = origin(2) + sep*(jx-1);
                        obj.add_voxel(sep,[x,y],matl);
                    end
                end
            elseif obj.dim == 3
                nx = lwh(1);
                ny = lwh(2);
                nz = lwh(3);
                for ix = 1:nx
                    for jx = 1:ny
                        for kx = 1:nz
                            x = origin(1) + sep*(ix-1);
                            y = origin(2) + sep*(jx-1);
                            z = origin(3) + sep*(kx-1);
                            obj.add_voxel(sep,[x,y,z],matl);
                        end
                    end
                end
            end
        end

        function obj = fix_mass(obj,pos)
            for ix = 1:length(obj.masses)
                relevant_mass = obj.masses(ix);
                if relevant_mass.pos_rest == pos
                    %fix this mass
                    relevant_mass.fixed = true;
                end
            end
        end

        function obj = fix_multi_mass(obj,ax,pos)
            for ix = 1:length(obj.masses)
                relevant_mass = obj.masses(ix);
                if ax == 'x'
                    if relevant_mass.pos_rest(1) == pos
                        %fix this mass
                        relevant_mass.fixed = true;
                    end
                elseif ax == 'y'
                    if relevant_mass.pos_rest(2) == pos
                        %fix this mass
                        relevant_mass.fixed = true;
                    end
                else %ax == 'z'
                    if relevant_mass.pos_rest(3) == pos
                        %fix this mass
                        relevant_mass.fixed = true;
                    end
                end

                
            end
        end

        function obj = merge_body(obj,bb)
            % the new body 'body_b' or bb
            %merge two bodies into one (merge new body into obj)

            obj.voxels = [obj.voxels, bb.voxels]; %appends the body voxels to the body

            %iterate thru the masses in the new body, and compare them to the existing masses in the body, and merge duplicates
            for ix = 1:length(bb.masses) %for each mass in the new body
                bb_mass = bb.masses(ix);%select the relevant mass in the new body
                unique_mass = true; %assume the mass is unique unless proven otherwise

                for jx = 1:length(obj.masses) %for each mass already in the body
                    body_mass = obj.masses(jx);

                    %two masses are identical if their rest positions are identical

                    if bb_mass.pos_rest == body_mass.pos_rest
                        %if the new voxel mass has a duplicate in the body:

                        %1. the mass is not unique (don't add it to the body)
                        unique_mass = false;

                        %2. average the masses and colors of the two point masses and save them to body_mass (the one we're gonna keep)
                        %unlike the add_voxel method, bb_mass potentially has a weight larger than one, so we need to account for that
                        body_mass.mass = (body_mass.wt*body_mass.mass + bb_mass.wt*bb_mass.mass)/(body_mass.wt + bb_mass.wt);
                        body_mass.clr = (body_mass.wt.*body_mass.clr + bb_mass.wt.*bb_mass.clr)./(body_mass.wt + bb_mass.wt);
                        body_mass.wt = body_mass.wt + bb_mass.wt; %update the weight

                        %3. find all links connected to the duplicate new body mass and replace their mass objects with the mass already in the body
                        for kx = 1:length(bb_mass.links)
                            relevant_link = bb_mass.links(kx); %select the relevant link
                            %determine if the new voxel mass is m_a or m_b for that link
                            if relevant_link.m_a == bb_mass
                                %the new voxel mass is stored as m_a in the link: replace it
                                relevant_link.m_a = body_mass;
                            else
                                %the new voxel mass is stored as m_b in the link: replace it
                                relevant_link.m_b = body_mass;
                            end
                        end

                        %4. append the voxel mass links to the body mass
                        %note this may cause duplicate links, but it gets resolved later
                        body_mass.links = [body_mass.links bb_mass.links];

                        %5. replace body mass in all voxels in the new body
                        %has to be done this way because unlike links, masses don't know which voxels they're in

                        for kx = 1:length(bb.voxels)
                            vox = bb.voxels(kx); %select the relevant voxel
                            
                            %find the relevant mass in the voxel
                            for lx = 1:length(vox.masses)
                                relevant_mass = vox.masses(lx);

                                %determine if the masses are the same
                                if relevant_mass == bb_mass
                                    %if they're the same, add body_mass to the voxel
                                    vox.masses(lx) = body_mass;
                                end

                                %if that mass isn't in the voxel - do nothing
                            end
                        end
                    end
                end

                if unique_mass
                    %add it to the body because it's not there yet
                    obj.masses = [obj.masses bb_mass];
                end
            end

            %iterate thru the links in the new voxel, compare them to existing links in the body, and merge duplicates

            for ix = 1:length(bb.links) %for each link in the new body
                bb_link = bb.links(ix); %select each relevant link
                unique_link = true; %assume a link is unique unless proven otherwise

                %at this point, all end masses should be the correct for all links, however, duplicate links may exist
                %to fix that, for each new voxel link, iterate through each link already in the body and check for duplicates

                for jx = 1:length(obj.links)
                    body_link = obj.links(jx); %extract each link already in the body

                    %two links are the same if their end masses are the same - however, the order of those masses can be flipped
                    if ((bb_link.m_a == body_link.m_a) && (bb_link.m_b == body_link.m_b)) || ((bb_link.m_a == body_link.m_b) && (bb_link.m_b == body_link.m_a))
                        %if two links are the same:

                        %1. the link is not unique (don't add it to the body)
                        unique_link = false;

                        %2. average the stiffness, damping, and color of the two links, and save them to body_link (the one we're gonna keep)
                        %see masses for explanation of weighting (body_link.wt)
                        body_link.k = (body_link.wt*body_link.k + bb_link.wt*bb_link.k)/(body_link.wt + bb_link.wt);
                        body_link.b = (body_link.wt*body_link.b + bb_link.wt*bb_link.b)/(body_link.wt + bb_link.wt);
                        body_link.clr = (body_link.wt.*body_link.clr + bb_link.wt.*bb_link.clr)./(body_link.wt + bb_link.wt); %element-wise averaging of rgb
                        body_link.wt = body_link.wt + bb_link.wt; %merge the weights

                        %3(a). delete the duplicate (new body) link for for m_a of that (new body) link
                        for kx = 1:length(bb_link.m_a.links)
                            m_a_link = bb_link.m_a.links(kx);
                            if m_a_link == bb_link
                                %at this point, kx is the index value representing the new body link in mass m_a 
                                %(and we want to delete it)
                                index = kx;
                            end
                        end

                        %if index = 1 or index = end, this is a problem, so, 3 cases:
                        if index == 1 %if the link is stored as the fist one
                            bb_link.m_a.links = bb_link.m_a.links(2:end);
                        elseif index == length(bb_link.m_a.links)%if the link is stored as the last one
                            bb_link.m_a.links = bb_link.m_a.links(1:(end-1));
                        else %the link is stored somewhere in the middle
                            bb_link.m_a.links = [bb_link.m_a.links(1:(index-1)),bb_link.m_a.links((index+1):end)];
                        end

                        %3(b). delete the duplicate (new body) link for for m_a of that (new body) link
                        for kx = 1:length(bb_link.m_b.links)
                            m_b_link = bb_link.m_b.links(kx);
                            if m_b_link == bb_link
                                %at this point, kx is the index value representing the new body link in mass m_a 
                                %(and we want to delete it)
                                index = kx;
                            end
                        end

                        %if index = 1 or index = end, this is a problem, so, 3 cases:
                        if index == 1 %if the link is stored as the fist one
                            bb_link.m_b.links = bb_link.m_b.links(2:end);
                        elseif index == length(bb_link.m_b.links)%if the link is stored as the last one
                            bb_link.m_b.links = bb_link.m_b.links(1:(end-1));
                        else %the link is stored somewhere in the middle
                            bb_link.m_b.links = [bb_link.m_b.links(1:(index-1)),bb_link.m_b.links((index+1):end)];
                        end

                        %4. replace the link in each voxel in the new body
                        % again, has to be done this way bc each link doesn't know which voxels its in
                        
                        for kx = 1:length(bb.voxels)
                            vox = bb.voxels(kx); %select the relevant voxel
                            
                            %find the relevant mass in the voxel
                            for lx = 1:length(vox.links)
                                relevant_link = vox.links(lx);

                                %determine if the links are the same
                                if relevant_link == bb_link
                                    %if they're the same, add body_mass to the voxel
                                    vox.links(lx) = body_link;
                                end

                                %if that link isn't in the voxel - do nothing
                            end
                        end
                    end
                end

                if unique_link
                    %add it to the body because it's not there yet
                    obj.links = [obj.links bb_link];
                end
            end
        end
 
        function plot_body(obj,plot_links)
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