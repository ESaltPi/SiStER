% SiStER_Input_File_otf3
% Vertical Cross-Section across an Ocean Transform Fault (OTF)

% DURATION OF SIMULATION AND FREQUENCY OF OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%
Nt=20; % max number of time iterations
dt_out=1; % output files every "dt_out" iterations

%Testing/initialization
%Nt = 1;             % max number of time iterations (testing)
%dt_out = 10;        % output files every "dt_out" iterations

% DOMAIN SIZE AND GRIDDING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xsize = 100e3;     % 100 km wide domain
ysize = 50e3;      % 50 km deep domain

% Horizontal Gridding: Refined in the center near the fault zone (40-60 km)
GRID.dx(1) = 2000;  GRID.x(1) = 40e3;
GRID.dx(2) = 500;   GRID.x(2) = 60e3;  % High resolution across fault core
GRID.dx(3) = 2000;

% Vertical Gridding: High resolution near top (0-15 km) for crust/water
GRID.dy(1) = 500;   GRID.y(1) = 15e3;  
GRID.dy(2) = 2000;

% LAGRANGIAN MARKERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Mquad = 8;          % markers in smallest quadrant
Mquad_crit = 4;     % minimum markers allowed for reseeding

% BATHYMETRY PROFILE DEFINITION (Rectangular Box Divot) %%%%%%%%%%%%%%%%%%%%
% Seafloor is flat at 4 km depth, with a 2 km deep box divot (6 km depth) from 45 to 55 km
x_data = [0, 45e3, 45e3+1, 55e3-1, 55e3, 100e3];
y_data = [4e3, 4e3,   6e3,    6e3,  4e3,   4e3];

% Pass profile vectors into PARAMS so SiStER_Initialize can access them
PARAMS.x_data = x_data;
PARAMS.y_data = y_data;

% GEOMETRY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nphase = 4; 
% Baseline horizontal setup
GEOM(1).type = 1; GEOM(1).top = 0; GEOM(1).bot = 12e3; 
GEOM(2).type = 1; GEOM(2).top = 12e3; GEOM(2).bot = 19e3;
GEOM(3).type = 1; GEOM(3).top = 19e3; GEOM(3).bot = ysize;
% Phase 4: Transform Fault Weak Zone (e.g., 10 km wide central block)
GEOM(4).type  = 3; 
GEOM(4).top   = 4e3;
GEOM(4).bot   = 19e3;
GEOM(4).left  = 45e3;
GEOM(4).right = 55e3;


% MATERIAL PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Phase 1: Sticky Water ---
MAT(1).phase = 1;
MAT(1).rho0 = 1000;      
MAT(1).alpha = 0;        
MAT(1).k = 3;
MAT(1).cp = 1000;
MAT(1).G = 1e18;
MAT(1).pre_diff = .5/1e18;
MAT(1).Ediff = 0;
MAT(1).ndiff = 1;
MAT(1).pre_disc = .5/1e18;
MAT(1).Edisc = 0;
MAT(1).ndisc = 1;
MAT(1).mu = 0.6;
MAT(1).mumin = 0.3;
MAT(1).Cmax = 40e6;
MAT(1).Cmin = 0.01e6;
MAT(1).ecrit = 0.1;

% --- Phase 2: Oceanic Crust ---
MAT(2).phase = 2;
MAT(2).rho0 = 2900;
MAT(2).alpha = 3e-5;
MAT(2).k = 3;
MAT(2).cp = 1000;
MAT(2).G = 30e9;
MAT(2).pre_diff = .5/1e40;
MAT(2).Ediff = 0;
MAT(2).ndiff = 1;
MAT(2).pre_disc = 1.0e-3;
MAT(2).Edisc = 167000*2.25;
MAT(2).ndisc = 2;
MAT(2).mu = 0.6;
MAT(2).mumin = 0.3;
MAT(2).Cmax = 40e6;
MAT(2).Cmin = 0.01e6;
MAT(2).ecrit = 0.1;

% --- Phase 3: Lithospheric Mantle ---
MAT(3).phase = 3;
MAT(3).rho0 = 3300;
MAT(3).alpha = 3e-5;
MAT(3).k = 3.3;
MAT(3).cp = 1000;
MAT(3).G = 30e9;
MAT(3).pre_diff = .5/1e40;
MAT(3).Ediff = 0;
MAT(3).ndiff = 1;
MAT(3).pre_disc = 1.0e-3;
MAT(3).Edisc = 167000*2.25;
MAT(3).ndisc = 2;
MAT(3).mu = 0.6;
MAT(3).mumin = 0.3;
MAT(3).Cmax = 40e6;
MAT(3).Cmin = 0.01e6;
MAT(3).ecrit = 0.1;

% --- Phase 4: Transform Fault Core (Inherits from Crust, weakened cohesion/friction) ---
MAT(4) = MAT(2); 
MAT(4).phase = 4;
MAT(4).mu = 0.1;
MAT(4).mumin = 0.05;
MAT(4).Cmax = 1e6;
MAT(4).Cmin = 0.01e6;



% ADDITIONAL PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.YNElast = 1;      
PARAMS.YNPlas = 1;       
PARAMS.tau_heal = 1e12;  
PARAMS.gx = 0;           
PARAMS.gy = 9.8;         
PARAMS.fracCFL = 0.5;    
PARAMS.R = 8.314;        
PARAMS.etamax = 1e25;    
PARAMS.etamin = 1e18;    
PARAMS.Tsolve = 1;       
PARAMS.a0 = 0;
PARAMS.a1 = 0;
PARAMS.a2 = 0;
PARAMS.a3 = 0;
PARAMS.amp = 0;
PARAMS.lam = 1;
PARAMS.ynTreset = 1;     
PARAMS.T0 = 0;           
PARAMS.rhoref = MAT(3).rho0; 
PARAMS.kref = 3.3;
PARAMS.cpref = 1000;

% TOPOGRAPHY EVOLUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.Ntopo_markers = 1000; 
PARAMS.YNSurfaceProcesses = 1; 
PARAMS.topo_kappa = 1e-8; 

% Interpolate custom topography tracking chain
PARAMS.custom_topo_x = linspace(0, xsize, PARAMS.Ntopo_markers);
PARAMS.custom_topo_y = interp1(x_data, y_data, PARAMS.custom_topo_x, 'linear', 'extrap');

% SOLVER ITERATIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.Npicard_min = 10;
PARAMS.Npicard_max = 100;
PARAMS.conv_crit_ResL2 = 1e-9;
PARAMS.pitswitch = 0;

% BOUNDARY CONDITIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.p0cell = 0;
BC.top   = [1 0 0];
BC.bot   = [1 0 0];
BC.left  = [1 0 0];
BC.right = [1 0 0];
PARAMS.BalanceStickyLayer = 1;

BCtherm.top   = [1 0];     
BCtherm.bot   = [1 1000];  
BCtherm.left  = [2 0];     
BCtherm.right = [2 0];