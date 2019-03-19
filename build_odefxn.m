%build state vector The assumption is that the state var is ordered as
        %[x,vx] for 1D, [x,y,vx,vy] for 2D and [x,y,z,vx,vy,vz] for 3D


%TODO: figure out how to deal with fixed masses

%building each row of
%dS = fxn(S(i))
function S0 = build_odefxn(body)
    dim = body.dim; %because its easier to write dim than body.dim a bunch
    %body.index_masses; <- this is called directly in simulation now
        %assign an index to each mass object within the entire body
        %[x,vx] for 1D, [x,y,vx,vy] for 2D and [x,y,z,vx,vy,vz] for 3D

    %open a new file
    file_name = fopen('odefxn.m','wt');
    fprintf(file_name,'function dS =  odefxn(t,S)\n\n');
    fprintf(file_name,'g = 0.8;\n'); %gravity!
    %fprintf(file_name,'dim = %d;\n',body.dim); %have access to dimension
    

    %preallocate S0: a 1xn vector, where  the number of entries n = number of masses(m1,m2,etc.) * number of dimensions (x,y,z) * 2 (position and velocity for each)
    S0 = zeros(1,length(body.masses) * dim * 2);
    

    for ix = 1:length(body.masses)
        m_trgt = body.masses(ix);
        fprintf(file_name,'\n%%===== m%d =====%%\n\n',ix);
        %NOTE: ix == m_trgt.index;

        %state vector indices for the ix mass
        trgt = (ix - 1)*2*dim;
            %trgt_pos = (ix - 1)*6 + [1,2,3];
            %trgt_vel = (ix - 1)*6 + [4,5,6];
            %same as trgt = (m_trgt.index - 1)*2*dim;

        %assign initial positions and velocities for that mass (m_trgt) to S0
        S0([trgt + 1 : trgt + dim]) = m_trgt.pos_init;
        S0([trgt + 1 + dim : trgt + dim + dim]) = m_trgt.vel_init;
            %this code used to be in 'simulation', now its here but spread out a bit
            % for ix = 1:length(body.masses)
            %     m_trgt = body.masses(ix);
            %     trgt = (ix - 1)*2*dim;
            %     S0(trgt + [1:dim]) = m_trgt.pos_init;
            %     S0(trgt + [1:dim] + dim) = m_trgt.vel_init;
            % end

        
        % assign velocities
        % dS(trgt_pos) = S(trgt_vel); %[dx,dy,dz] = [dx,dy,dz]  
        fprintf(file_name,'%%copy velocity values from S to dS\n');
        %fprintf(file_name,'dS([trgt+1:trgt+dim]) = S([trgt + 1 + dim: trgt + 2*dim]);\n',trgt,trgt);
        fprintf(file_name,'dS([%d:%d]) = S([%d:%d]);\n',(trgt + 1),(trgt + dim),(trgt + 1 + dim),(trgt + dim + dim));

        if m_trgt.fixed
            %store 0 for acceleration
            fprintf(file_name,'%%fixed mass: zero acceleration in dS\n');

            if dim == 1
                fprintf(file_name,'dS([%d:%d]) = [0];\n\n',(trgt + 1 + dim),(trgt + dim + dim));
            elseif dim == 2
                fprintf(file_name,'dS([%d:%d]) = [0,0];\n\n',(trgt + 1 + dim),(trgt + dim + dim));
            else %dim == 3
                fprintf(file_name,'dS([%d:%d]) = [0,0,0];\n\n',(trgt + 1 + dim),(trgt + dim + dim));
            end       

        else
            %do the thing

            %fprintf(file_name,'dS(%d + [1:dim]) = S(%d + dim + [1:dim]);\n',trgt,trgt);
            fprintf(file_name,'%%preallocate empty force vector\n');
            fprintf(file_name,'F = zeros(%d,1);\n\n',dim);

            for jx = 1:length(m_trgt.links)
                %iterate through each link for that 'target' mass
                lnk = m_trgt.links(jx);
        
                %find the 'connected' mass for that link
                if m_trgt == lnk.m_a;
                    m_cnct = lnk.m_b;
                else
                    m_cnct = lnk.m_a;
                end

                %label what's going on
                fprintf(file_name,'%% link m%d -> m%d\n',m_trgt.index,m_cnct.index);

                %state vector indices for the mass at the other end of the connection
                %cnct_pos = (m_cnct.index - 1)*6;% + [1,2,3];
                %cnct_vel = (m_cnct.index - 1)*6;% + [4,5,6];
                cnct = (m_cnct.index - 1)*2*dim;
                %(m_cnct - m_trgt)
                %TODO: use m_cnct.index
                %define everything in terms of indices in the state vector
                %V = S(cnct_pos) - S(trgt_pos); %vector from m_trgt -> m_cnct (m_cnct.pos - m_trgt.pos)




                %fprintf(file_name,'dS([%d:%d]) = S([%d:%d]);\n',(trgt + 1),(trgt + dim),(trgt + 1 + dim),(trgt + dim + dim));

                %fprintf(file_name,'V = S(%d + [1:dim]) - S(%d + [1:dim]);\n',cnct,trgt);
                fprintf(file_name,'V = S([%d:%d]) - S([%d:%d]);\n',(cnct + 1), (cnct + dim), (trgt + 1), (trgt + dim));




                %dV = S(cnct_vel) - S(trgt_vel); %d(vector from m_trgt -> m_cnct)/dt (m_cnct.vel - m_trgt.vel])
                %fprintf(file_name,'dV = S(%d + dim + [1:dim]) - S(%d + dim + [1:dim]);\n',cnct,trgt);

                fprintf(file_name,'dV = S([%d:%d]) - S([%d:%d]);\n',(cnct + dim + 1), (cnct + dim + dim),(trgt + dim +1), (trgt + dim + dim));



                %V_unit = V/norm(V); %unit vector in the m_trgt -> m_cnct direction
                fprintf(file_name,'V_unit = V/norm(V);\n');

                %find spring force on 'target' by 'connected' mass
                %Fs(i) = -k*(displacement)*direction
                %+ lnk.k*(norm(V) - lnk.rest_length)*V_unit;
                fprintf(file_name,'F = F + %g * (norm(V) - %.20g)*V_unit;\n',lnk.k,lnk.rest_length);
        
                
                %find damper force on 'target' by 'connected' mass
                %Fd(i) = -b*(velocity in direction)*direction
                %+ lnk.b*(dot(dV,V_unit))*V_unit;
                fprintf(file_name,'F = F + %g*(dot(dV,V_unit))*V_unit;\n\n',lnk.b);
            end

            fprintf(file_name,'%%gravity and acceleration:\n');

            %gravity
            if dim == 2
                fprintf(file_name,'F = F - %g * [0;g];\n',m_trgt.mass);
            elseif dim == 3
                fprintf(file_name,'F = F - %g * [0;0;g];\n',m_trgt.mass);
            end

            %build accelerations
            %a = (1/m)*F;
            fprintf(file_name,'dS([%d:%d]) = (1/%g)*F;\n\n',(trgt + 1 + dim),(trgt + dim + dim),m_trgt.mass);
        end
    end
    fprintf(file_name,'dS = dS'';\n');
    fprintf(file_name,'end\n');    %end the outer function
    fclose(file_name);

end