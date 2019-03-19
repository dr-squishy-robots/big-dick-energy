# big-dick-energy

Yep, it's all done in MATLAB. While it's really not the best language for doing something like this, it's what the homework required.

All in all, the code does some interesting things that you probably won't see in MATALB very often, so I though it could be useful to throw it up here for y'all to look thru.

Here's roughly how the code works:

Part 1. Building the member (Object oriented construction)
  - Material, Mass, Link, Voxel, and Body are classes specifying the behavior of the elements of the system
  - using the methods of Body, we construct the mass-spring-damper network that we want to simulate
  - this object-oriented structure is easy to modify, but relatively slow to simulate
  
Part 2. Preparing member for stimulation (Conversion to array form)
  - the positions and velocities of each mass are compiled into a state vector S
  - build_odefxn generates odefxn, which contains the set of dynamical equations governing the system
  - odefxn directly references elements from the state vector S
  - likewise, build_plotfxn generates plotfxn and plot_updatefxn, two files which build the initial plot and animate it
  - these files also pull values directly from the state vector S
  
 Part 3. Stimulation ;) (ODE solver)
  - using the state vector S, odefxn and the ode23 solver, simulate the physics of the mass-spring-damper network
  - for each time step of the simulation, use plot_fxn or plot_updatefxn to generate a plot
  - save video frames if needed
