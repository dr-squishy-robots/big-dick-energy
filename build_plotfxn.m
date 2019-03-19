%buids a function called 'plotfxn' that will plot each mass and link using S
%plot links = 0 don't plot links
%plot links = 1 plot vertical/horizontal links only
%plot links = 2 plot all links
function build_plotfxn(body,plot_links)
    dim = body.dim;
    


%the initial plot function
    file_name = fopen('plotfxn.m','wt');
    fprintf(file_name,'function [h_l,h_m] = plotfxn(S)\n\n');

    fprintf(file_name,'h_l = [];\n'); %handles for the links
    fprintf(file_name,'h_m = [];\n'); %handles for the masses

    fprintf(file_name,'ff = 1e-3;\n\n');%a fudge factor added to x and subtracted from y in the 3D version of the code to ensure that masses always render "in front" of links

    fprintf(file_name,'%% plot links:\n\n');

    for ix = 1:length(body.masses)
        m_trgt = body.masses(ix);
        trgt = (ix - 1)*2*dim;

        for jx = 1:length(m_trgt.links)
            %iterate through each link for that 'target' mass
            lnk = m_trgt.links(jx);
            if (lnk.rest_length == 1 && plot_links == 1) || (plot_links == 2)
                %do the thing
                %find the 'connected' mass for that link
                if m_trgt == lnk.m_a;
                    m_cnct = lnk.m_b;
                else
                    m_cnct = lnk.m_a;
                end

                cnct = (m_cnct.index - 1)*2*dim;

                fprintf(file_name,'%% link m%d -> m%d\n',m_trgt.index,m_cnct.index);



                if dim == 1
                    fprintf(file_name,'h = plot([S(%d),S(%d)],[0,0],''LineWidth'',2,''Color'',[%g,%g,%g]);\n',trgt+1,cnct+1,lnk.clr(1),lnk.clr(2),lnk.clr(3));
                elseif dim == 2
                    fprintf(file_name,'h = plot([S(%d),S(%d)],[S(%d),S(%d)],''LineWidth'',2,''Color'',[%g,%g,%g]);\n',trgt+1,cnct+1,trgt+2,cnct+2,lnk.clr(1),lnk.clr(2),lnk.clr(3));
                else %dim == 3
                    fprintf(file_name,'h = plot3([S(%d),S(%d)],[S(%d),S(%d)],[S(%d),S(%d)],''LineWidth'',2,''Color'',[%g,%g,%g]);\n',trgt+1,cnct+1,trgt+2,cnct+2,trgt+3,cnct+3,lnk.clr(1),lnk.clr(2),lnk.clr(3));
                end

                fprintf(file_name,'h_l = [h_l h];\n\n');
            end
        end
    end

    fprintf(file_name,'\n\n');
    fprintf(file_name,'%% plot masses:\n\n');
    for ix = 1:length(body.masses)
        m_trgt = body.masses(ix);
        trgt = (ix - 1)*2*dim;

        fprintf(file_name,'%% mass m%d\n',m_trgt.index); %m_trgt.index can be replaced by ix
        %plot(S(trgt + 1),S(trgt + 2),'.','MarkerSize',40,'Color',[0.4941 0.1843 0.5569]);

        if dim == 1
            fprintf(file_name,'h = plot(S(%d),0,''.'',''MarkerSize'',40,''Color'',[%g,%g,%g]);\n',(trgt + 1),m_trgt.clr(1),m_trgt.clr(2),m_trgt.clr(3));
        elseif dim ==2
            fprintf(file_name,'h = plot(S(%d),S(%d),''.'',''MarkerSize'',40,''Color'',[%g,%g,%g]);\n',(trgt + 1),(trgt + 2),m_trgt.clr(1),m_trgt.clr(2),m_trgt.clr(3));
        else %dim == 3
            fprintf(file_name,'h = plot3(S(%d) + ff,S(%d) - ff,S(%d),''.'',''MarkerSize'',40,''Color'',[%g,%g,%g]);\n',(trgt + 1),(trgt + 2),(trgt + 3),m_trgt.clr(1),m_trgt.clr(2),m_trgt.clr(3));
        end

        fprintf(file_name,'h_m = [h_m h];\n\n');
    end
    
    fprintf(file_name,'end\n');
    fclose(file_name);





% the plot update function
    file_name = fopen('plot_updatefxn.m','wt');
    fprintf(file_name,'function [h_l,h_m] = plot_updatefxn(S,h_l,h_m)\n\n');

    fprintf(file_name,'ff = 1e-3;\n\n');%a fudge factor added to x and subtracted from y in the 3D version of the code to ensure that masses always render "in front" of links

    fprintf(file_name,'%% update links:\n\n');
    hx = 1; %a counter to keep track of which link object to update
    for ix = 1:length(body.masses)
        m_trgt = body.masses(ix);
        trgt = (ix - 1)*2*dim;

        for jx = 1:length(m_trgt.links)
            %iterate through each link for that 'target' mass
            lnk = m_trgt.links(jx);
            if (lnk.rest_length == 1 && plot_links == 1) || (plot_links == 2)
        
                %find the 'connected' mass for that link
                if m_trgt == lnk.m_a;
                    m_cnct = lnk.m_b;
                else
                    m_cnct = lnk.m_a;
                end

                cnct = (m_cnct.index - 1)*2*dim;

                fprintf(file_name,'%% link m%d -> m%d\n',m_trgt.index,m_cnct.index);

                if dim == 1
                    fprintf(file_name,'h_l(%d).XData = [S(%d),S(%d)];\n',hx,trgt+1,cnct+1);
                elseif dim == 2
                    fprintf(file_name,'h_l(%d).XData = [S(%d),S(%d)];\n',hx,trgt+1,cnct+1);
                    fprintf(file_name,'h_l(%d).YData = [S(%d),S(%d)];\n',hx,trgt+2,cnct+2);
                else %dim == 3
                    fprintf(file_name,'h_l(%d).XData = [S(%d),S(%d)];\n',hx,trgt+1,cnct+1);
                    fprintf(file_name,'h_l(%d).YData = [S(%d),S(%d)];\n',hx,trgt+2,cnct+2);
                    fprintf(file_name,'h_l(%d).ZData = [S(%d),S(%d)];\n',hx,trgt+3,cnct+3);
                end

                hx = hx + 1;
            end
        end
    end


    fprintf(file_name,'\n\n');
    fprintf(file_name,'%% update masses:\n\n');
    for ix = 1:length(body.masses)
        m_trgt = body.masses(ix);
        trgt = (ix - 1)*2*dim;

        fprintf(file_name,'%% mass m%d\n',m_trgt.index); %m_trgt.index can be replaced by ix
        %plot(S(trgt + 1),S(trgt + 2),'.','MarkerSize',40,'Color',[0.4941 0.1843 0.5569]);

        if dim == 1
            fprintf(file_name,'h_m(%d).XData = S(%d);\n',ix,(trgt+1));
        elseif dim == 2
            fprintf(file_name,'h_m(%d).XData = S(%d);\n',ix,(trgt+1));
            fprintf(file_name,'h_m(%d).YData = S(%d);\n',ix,(trgt+2));
        else %dim == 3
            fprintf(file_name,'h_m(%d).XData = S(%d) + ff;\n',ix,(trgt+1));
            fprintf(file_name,'h_m(%d).YData = S(%d) - ff;\n',ix,(trgt+2));
            fprintf(file_name,'h_m(%d).ZData = S(%d);\n',ix,(trgt+3));
        end
    end

    fprintf(file_name,'end\n');
    fclose(file_name);
end