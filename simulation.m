close all; clear; clc;
R = FORMAT();

dim = 3;
frame_rate = 10; %simulation-frames per second (the video is 30fps by default)
t_end = 60;

rebuild = true; %should we rebuild the object-oriented structure? set to true if changing the shape or material properties
resimulate = true; %should we re-run the ODE solver for the system? set to true if rebuild is true or if changing the simulation time
reanimate = true; %should we re-render the video? set to true if resimulate is true, or if changing plotting properties (frame size, export format, etc.)

if rebuild
    %building the body OBJECT
    fprintf('building member\n');
    %member = Material(8,8,1,R.c3);
    m1 = Material(600,80,1,R.c3);%shaft
    m2 = Material(550,80,1,(R.c3 + R.c2)./2);
    m3 = Material(500,80,1,R.c2);
    m4 = Material(200,30,2,R.c1);%balls
    m5 = Material(400,80,1,R.c4);%tip


    %build balls
    ball_1 = Body(dim);
    ball_1.add_multi_voxel(1,[1,0,-2],[1,1,3],m4);
    ball_1.add_multi_voxel(1,[0,0,-1],[3,1,1],m4);

    ball_1.add_multi_voxel(1,[0,-1,-2],[3,1,3],m4);

    ball_1.add_multi_voxel(1,[1,-2,-2],[1,1,3],m4);
    ball_1.add_multi_voxel(1,[0,-2,-1],[3,1,1],m4);

    ball_2 = Body(dim);
    ball_2.add_multi_voxel(1,[1,4,-2],[1,1,3],m4);
    ball_2.add_multi_voxel(1,[0,4,-1],[3,1,1],m4);

    ball_2.add_multi_voxel(1,[0,3,-2],[3,1,3],m4);

    ball_2.add_multi_voxel(1,[1,2,-2],[1,1,3],m4);
    ball_2.add_multi_voxel(1,[0,2,-1],[3,1,1],m4);

    fprintf('()');
   
    %build shaft
    body = Body(dim);
    body.add_multi_voxel(1,[0,0,0],[2,3,3],m1);
    body.fix_multi_mass('x',-0.5);

    shaft_1 = Body(dim);
    shaft_1.add_multi_voxel(1,[2,0,0],[2,3,3],m1);

    shaft_2 = Body(dim);
    shaft_2.add_multi_voxel(1,[4,0,0],[2,3,3],m1);

    shaft_3 = Body(dim);
    shaft_3.add_multi_voxel(1,[6,0,0],[2,3,3],m2);

    shaft_4 = Body(dim);
    shaft_4.add_multi_voxel(1,[8,0,0],[2,3,3],m2);

    shaft_5 = Body(dim);
    shaft_5.add_multi_voxel(1,[10,0,0],[2,3,3],m3);

    shaft_6 = Body(dim);
    shaft_6.add_multi_voxel(1,[12,0,0],[2,3,3],m3);

    fprintf('()\n');

    %build tip
    tip = Body(dim);
    tip.add_multi_voxel(1,[13,0,-1],[1,3,5],m5);
    tip.add_multi_voxel(1,[13,-1,0],[1,5,3],m5);
    tip.add_multi_voxel(1,[14,0,0],[1,3,3],m5);
    tip.add_voxel(1,[15,1,1],m5);

    fprintf(' ||\n');

    %merge bodies
    %order designed to minimize overlap and therefore speed up the code
    body.merge_body(shaft_2);
    tip.merge_body(shaft_4);
    ball_1.merge_body(ball_2);
    shaft_3.merge_body(shaft_5);
    shaft_1.merge_body(shaft_6);

    fprintf(' ||\n');

    shaft_1.merge_body(shaft_3);
    body.merge_body(tip);

    fprintf(' ||\n');

    ball_1.merge_body(shaft_1);

    fprintf(' \\/\n');

    body.merge_body(ball_1);


    %body.add_multi_voxel(1,[0.5,0.5,0.5],[4,3,3],shaft);
    %body.add_multi_voxel(1,[3.5,0.5,0.5],[10,3,3],member);
    %body.add_multi_voxel(1,[7.5,0.5,0.5],[2,3,3],shaft);

    %body.fix_multi_mass('x',0);
    %body.fix_multi_mass('x',9);



    %converting the body OBJECT into an easy-to-simulate STATE VECTOR
    fprintf('preparing member for stimulation\n');
    body.index_masses;
    S0 = build_odefxn(body);
    build_plotfxn(body,2);
    save('S0','S0');
else
    load('S0');
end

if resimulate
    fprintf('stimulating ;)\n');
    %the simulation itself
    tspan = [0:(1/frame_rate):t_end];
    [t,S] = ode23(@(t,y) odefxn(t,y),tspan,S0);
    
    save('S','t','S');
else
    load('S');
end

if reanimate
    %plots and animations
    vid = VideoWriter('video','MPEG-4');
    %vid.FrameRate = frame_rate;
    %vid = VideoWriter('video');
    open(vid);
end

    figure(R.fig)
    axes(R.ax);
    %view(60,7);
    view(51,13);
    %view(22,19);
    xlim([-1.5 16]);
    ylim([-7 9]);
    zlim([-10.5 3.5]);
    axis off
    hold on

    [h_l,h_m] = plotfxn(S0);
    text(2,4,-9,'BIG DICK ENERGY','FontSize',72,'FontName','CMUBright','HorizontalAlignment','center')
    %text(-7,3,-10,'BIG DICK ENERGY','FontSize',64,'FontName','CMUBright')
    
if reanimate
    drawnow;
    writeVideo(vid,getframe(gcf));

    for ix = 2:length(t)
        %from 2 because S(1,:) == S0
        %iterate thru each time step (frame)
        fprintf('t = %5.3f\n',t(ix));
        [h_l,h_m] = plot_updatefxn(S(ix,:),h_l,h_m);
        drawnow;
        writeVideo(vid,getframe(gcf));
    end

    close(vid);
end