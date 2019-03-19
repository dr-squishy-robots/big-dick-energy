classdef Link < handle
    properties
        k = 1; %stiffness (inherited from material)
        b = 0.5; %damping (inherited from material)
        rest_length;
        m_a = [];
        m_b = [];
        clr;    %the color of the link (inherited from material)
        wt = 1; %the weight factor used when averaging multiple links
        dim;    %inherited from body
    end
    methods
        function obj = Link(dim,matl)
            obj.k = matl.k;
            obj.b = matl.b;
            obj.clr = matl.clr;
            obj.dim = dim;
        end
        function obj = add_masses(obj,m_a,m_b)
            obj.m_a = m_a;
            obj.m_b = m_b;
            obj.rest_length = norm(m_b.pos_rest - m_a.pos_rest);
        end
        

        function obj = plot_link(obj)
            if obj.dim == 1
                x = [obj.m_a.pos_rest(1) obj.m_b.pos_rest(1)];
                plot(x,0,'-','LineWidth',2,'Color',obj.clr);
            elseif obj.dim == 2
                x = [obj.m_a.pos_rest(1) obj.m_b.pos_rest(1)];
                y = [obj.m_a.pos_rest(2) obj.m_b.pos_rest(2)];
                plot(x,y,'-','LineWidth',2,'Color',obj.clr);
            else %dim == 3
                x = [obj.m_a.pos_rest(1) obj.m_b.pos_rest(1)];
                y = [obj.m_a.pos_rest(2) obj.m_b.pos_rest(2)];
                z = [obj.m_a.pos_rest(3) obj.m_b.pos_rest(3)];
                plot3(x,y,z,'-','LineWidth',2,'Color',obj.clr);
            end
        end
    end
end