  % Program:
  % Rocket_Trajectory_Simulation.m
  % Multi-stage rocket dynamics and trajectory simulation.
  %
  % Description:
  % Predicts multi-stage rocket dynamics and trajectories based on the given 
  % rocket mass, mass flow, engine thrust, launch parameters, and drag coefficient.
  % The drag is related to the ambient air pressure which modelled with the ISA
  % standard atmosphere.

  clear, clc      % Clear command window and workspace

  % Simulation parameters
  Delta = 1;                      % Incremental step 
  Memory_Allocation = 10000;    % Maximum number of time steps expected

  method = 1; %=0                 % Calculation method
                                  % 0 - simplistic incremental calculation
                                  % 1 - finite difference method

  % Preallocate memory for arrays
  t = zeros(1, Memory_Allocation);        % t = Time (s)
  Thrust = zeros(1, Memory_Allocation);   % Thrust = Thrust (N)
  Mass = zeros(1, Memory_Allocation);     % Mass = Mass (kg)
  Theta = zeros(1, Memory_Allocation);    % Theta = Angle (deg)
  Fn = zeros(1, Memory_Allocation);
  Drag = zeros(1, Memory_Allocation);     % Drag = Drag force (N)
  Fx = zeros(1, Memory_Allocation);       % Fx = Sum of forces in the horizontal direction (N)
  Fy = zeros(1, Memory_Allocation);       % Fy = Sum of forces in the vertical direction (N)
  Ax = zeros(1, Memory_Allocation);       % Ax = Acceleration in the horizontal direction (m/s^2)
  Ay = zeros(1, Memory_Allocation);       % Ay = Acceleration in the vertical direction (m/s^2)
  Vx = zeros(1, Memory_Allocation);       % Vx = Velocity in the horizontal direction (m/s)
  Vy = zeros(1, Memory_Allocation);       % Vy = Velocity in the vertical direction (m/s)
  x = zeros(1, Memory_Allocation);        % x = Horizontal position (m)
  y = zeros(1, Memory_Allocation);        % y = Vertical position (m)
  Rho=zeros(1, Memory_Allocation);          % Rho = Air density (kg/m^3)
  Mass_Flow = zeros(1, Memory_Allocation);  % Mass_Flow = Flow of mass per second that comes out of the thruster (kg/s)

  % Inital param  eters
  if method == 1
    n=2;
    x(1)=0;
    x(2)=0;
    y(1)=0;
    y(2)=0.1;
    Rho(1) = 1.2;
    Rho(2) = 1.2;
    Mass(1) = Mass_Start;
    Mass(2) = Mass_Start;                 % Initial rocket mass (kg)
    Thrust(1) = Thrust_One;               % Inital rocket thrust ( (kg*m)/s^2 )
    Thrust(2) = Thrust_One;               % Inital rocket thrust ( (kg*m)/s^2 )
    Mass_Flow(3) = Mass_Flow_One * Delta; % Inital mass flow equals the mass flow of the first stage times the delta
    Theta(1) = 90;                        % Initial angle (deg)
    Theta(2) = 90;                        % Initial angle (deg)
    stage = 1;                            % Initial stage (1 for the first one)

  else
    Vx(1) = 0;                      % Initial horizontal speed (m/s)
    Vy(1) = 0;                      % Initial vertical speed (m/s)
    x(1) = 0;                       % Initial horizontal position (m)
    y(1) = 0.1;                     % Initial vertical position (m)
    Distance_x(1) = 0;              % Initial horizontal distance travelled (m)
    Distance_y(1) = 0;              % Initial vertical distance travelled (m)
    Distance(1) = 0;                % Initial distance travelled (m)
    Rho(1) = 1.2;                   % Initial air density (kg/m^3)
    Mass(1) = Mass_Start;           % Initial rocket mass (kg)
    Thrust(1) = Thrust_One;         % Inital rocket thrust ( (kg*m)/s^2 )
    n = 1;                          % Initial time step            
    stage = 1;                      % Initial stage (1 for the first one)
  
    Mass(1)=Mass_Start;
    Mass_Flow(1) = Mass_Flow_One * Delta; % Inital mass flow equals the mass flow of the first stage times the delta
    Theta(1) = 89;                     % Initial angle (deg)

  endif
  Seperation_One = false;         % Stage one at start not seperated
  Seperation_Two = false;         % Stage two at start not seperated

  clc % clean the console


  Mission_Success = false;

  while y(n) > 0  && Mission_Success == false      % Run until rocket hits the ground or mission completed
      
      n = n+1;                    % Increment time step
      t(n)= (n-1)*Delta;          % Elapsed time, starts with n=1 * Delta, Delta represents the space between increments 

     
      % Determine rocket thrust and mass based on launch phase 
    if (stage == 1)
      disp('Stage 1 active');
      Thrust(n) = Thrust_One;
      Mass_Flow(n) = Mass_Flow_One * Delta;
      disp('Mass flow in if');disp(Mass_Flow(n));
    else
      if(stage == 2)
        disp('Stage 2 active');
        Thrust(n) = Thrust_Two;
        MassFlow(n) = Mass_Flow_Two * Delta;
        k = n + Coasting_Phase_After_Stage_One;      

      else
        Thrust(n)=0; 
      endif
    endif
    Mass(n) = Mass(n-1) - Mass_Flow(n);
     
     disp(Mass(n));
    
    % Seperation logic
      if Mass(n) < (Mass_Start - Mass_Fuel_And_Oxidizer_One) && Seperation_One == false;     % seperation condition first stage
        disp('Seperation first stage');
        Seperation_One = true;
        stage = 2;
        Mass(n) = Mass(n) - 999;
      endif

      if Mass(n) < (Mass_Start - (Mass_Fuel_And_Oxidizer_One+Mass_Motor_And_Structure_One + Mass_Fuel_And_Oxidizer_Two)) && Seperation_Two == false % seperation condition second stage
        disp('Seperation second stage');
        Seperation_Two = true;
        stage = 3;
        Mass(n) = Mass_Payload;
      endif

      disp('Mass');
      disp(Mass(n));


     
      % Drag force calculation
      % C - Drag coefficient, related to the velocity?
      % Rho - Air density
      % A - Refernce area
      % (Vx(n-1)^2+Vy(n-1)^2) - absolute velocity squared
      % Drag(n)= 0.5*C*Rho(n-1)*A*(Vx(n-1)^2+Vy(n-1)^2); % Calculate drag force
      
      if method == 1
        % Finite difference methode
          % basics:
          % Ax(n) = (Thrus(n)*cosd(Theta(n-1))-Drag(n)*cosd(Theta(n-1))) / Mass(n) ; comes out of the physical model & F = m * a 
          % Ax(n) = ( x(n) - 2*x(n-1) + x(n-2) ) / ( t(n)^2 ); out of the definition of differntial equation second order
          % see https://en.wikipedia.org/wiki/Finite_difference_method

        % Position of the rocket
        x(n) = ((Delta*Delta) / Mass(n) )* ( Thrust(n)*cosd(Theta(n-1)) ) + 2*x(n-1) - x(n-2);
        y(n) = ((Delta*Delta) / Mass(n) )* ( Thrust(n)*sind(Theta(n-1)) - Mass(n)* Gravity ) + 2*y(n-1) - y(n-2);
        disp([x(n),y(n)]);

        % Velocity of the rocket
        Vx(n) = (x(n) - x(n-1)) / Delta;
        Vy(n) = (y(n) - y(n-1)) / Delta;
        
        % Accleration
        Ax(n) = ( x(n-2) - 2*x(n-1) + x(n) ) / (Delta^2);
        Ay(n) = ( y(n-2) - 2*y(n-1) + y(n) ) / (Delta^2);

      % simplistic incremental calculations

        % Sum of forces calculations 
        Fx(n)= Thrust(n)*cosd(Theta(n-1))-Drag(n)*cosd(Theta(n-1));   % Sum x forces horizontal
        Fy(n)= Thrust(n)*sind(Theta(n-1))-(Mass(n)*Gravity);          % Sum y forces veritcal
    
        % Acceleration calculation
        Ax(n)= Fx(n)/Mass(n);                       % Net accel in x direction 
        Ay(n)= Fy(n)/Mass(n);                       % Net accel in y direction

        % Velocity calculations
        Vx(n)= Vx(n-1)+Ax(n)*Delta;                 % Velocity in x direction
        Vy(n)= Vy(n-1)+Ay(n)*Delta;                 % Velocity in y direction

        % Position calculations
        x(n)= x(n-1)+Vx(n)*Delta;                   % Position in x direction
        y(n)= y(n-1)+Vy(n)*Delta;                   % Position in y direction   
      
      endif
      
      % Air pressure calculation with ISA model
      %Rho(n) = isa(y(n),"R");   
      
      % Rocket angle calculation
      % ^ Vy
      % |   / 
      % |  / angle in between velocity vector and x-direction
      % | /  
      % |/---> Vx
     if y(n) >= Height_Start_Gravity_Turn  % if y(n) > Height_Start_Gravity_Turn  % if a certain heigth is reached, the rocket is actively tilting
       Theta(n) = atand(Vy(n)/Vx(n)) - DeltaTheta;  % Angle defined by velocity vector in degrees    
     else 
      Theta(n)= 89;        
     endif
     
      % set the mission goals and end the mission if archieved
      if y(n) > 500000 || Theta(n) <= 5
        Mission_Success = true;
      endif
      
  end


  figure('units','normalized','outerposition',[0 0 1 1]) % Maximize plot window


    % Figure 2
    subplot(3,2,2)
    plot(t(1:n),y(1:n), "linewidth", 5);
    set(gca, "linewidth", 4, "fontsize", 30); 
    xlabel({'Time (s)'});
    ylabel({'Height (m)'});
    title({'Trajectory'});
    %ylim([0 500500]);
  
    % Figure 6
    subplot(3,2,6)
    plot(t(1:n),Mass(1:n), "linewidth", 5);
    set(gca, "linewidth", 4, "fontsize", 30); 
    xlabel({'Time (s)'});
    ylabel({'Mass (kg)'});
    title({'Rocket mass'});
    
    % Figure 3
    subplot(3,2,3)
    plot(y(1:n),Vy(1:n), "linewidth", 5);
    set(gca, "linewidth", 4, "fontsize", 30); 
    xlabel({'Height (m)'});
    ylabel({'Vy (m/s)'});
    title({'Horizontal Velocity'});

    % Figure 5
    subplot(3,2,5)
    plot(y(1:n),Vx(1:n), "linewidth", 5);
    set(gca, "linewidth", 4, "fontsize", 30); 
    xlabel({'Height (m)'});
    ylabel({'Vy (m/s)'});
    title({'Vertical Velocity'});


    % Figure 1
    subplot(3,2,1)
    plot(y(1:n),Thrust(1:n), "linewidth", 5);
    set(gca, "linewidth", 4, "fontsize", 30); 
    xlabel({'Height (m)'});
    ylabel({'Thrust (N)'});
    title({'Thrust' });


    % Figure 4
    subplot(3,2,4)
    plot(t(1:n),Theta(1:n), "linewidth", 5);
    set(gca, "linewidth", 4, "fontsize", 30); 
    xlabel({'Time (s)'});
    ylabel({'Theta (Deg)'});
    title({'Theta'});

    figure('units','normalized','outerposition',[0 0 1 1]) % Maximize plot window
    
    
    subplot(2,1,1)
    plot(y(1:n),Drag(1:n), "linewidth", 5);
    set(gca, "linewidth", 4, "fontsize", 30); 
    xlabel({'Height (m)'});
    ylabel({'Drag (N)'});
    title({'Drag Force'});

    subplot(2,1,2)
    plot(y(1:n),Rho(1:n), "linewidth", 5);
    set(gca, "linewidth", 4, "fontsize", 30); 
    xlim([0 50000]);
    xlabel({'Height (m)'});
    ylabel({'Density (kg/m^3)'});
    title({'Air density'});

