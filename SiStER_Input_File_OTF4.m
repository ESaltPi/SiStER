% SiStER_Input_File_OTF4.m
% Vertical Cross-Section with Static Bathymetry, Flexible Moho, and Fixed Timestep

% DURATION OF SIMULATION AND FREQUENCY OF OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%
Nt = 20;             % number of time iterations
dt_out = 1;          % save output every iteration

% DOMAIN SIZE AND GRIDDING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xsize = 100e3;       % 100 km wide domain
ysize = 50e3;        % 50 km deep domain

% Horizontal Gridding: Refined in the center near the fault/relief (40-60 km)
GRID.dx(1) = 2000;   GRID.x(1) = 40e3;
GRID.dx(2) = 500;    GRID.x(2) = 60e3;  % 500 m resolution across central zone
GRID.dx(3) = 2000;

% Vertical Gridding: High resolution near top (0-15 km) for relief, crust & Moho
GRID.dy(1) = 500;    GRID.y(1) = 15e3;  % 500 m resolution
GRID.dy(2) = 2000;

% LAGRANGIAN MARKERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Mquad = 8;           % markers in smallest quadrant
Mquad_crit = 4;      % minimum markers allowed for reseeding

% BATHYMETRY / TOPOGRAPHY & MOHO DEFINITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% x = distance along profile (m), y = depth from top of domain (m)
x_data = [0, 45e3, 45e3+1, 55e3-1, 55e3, 100e3];
y_data = [4e3, 4e3,   6e3,    6e3,  4e3,   4e3];

PARAMS.x_data = x_data;
PARAMS.y_data = y_data;
PARAMS.moho_depth = 8e3;  % Flexible Moho depth (m) — change for continental/other settings

% GEOMETRY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nphase = 3;          % 1: Sticky Water/Air, 2: Crust, 3: Mantle

% Baseline horizontal layers (overridden by PARAMS.x_data/y_data/moho_depth in SiStER_Initialize)
GEOM(1).type = 1; GEOM(1).top = 0;                 GEOM(1).bot = 4e3;
GEOM(2).type = 1; GEOM(2).top = 4e3;               GEOM(2).bot = PARAMS.moho_depth;
GEOM(3).type = 1; GEOM(3).top = PARAMS.moho_depth; GEOM(3).bot = ysize;

% MATERIAL PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Phase 1: Sticky Water ---
MAT(1).phase = 1;
MAT(1).rho0 = 1000;      % Water density (kg/m^3)
MAT(1).alpha = 0;        
MAT(1).k = 3;
MAT(1).cp = 1000;
MAT(1).G = 1e18;         % Effectively non-elastic fluid
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

% --- Phase 2: Crust (Basalt/Gabbro) ---
MAT(2).phase = 2;
MAT(2).rho0 = 2900;      % Crustal density (kg/m^3)
MAT(2).alpha = 3e-5;
MAT(2).k = 3;
MAT(2).cp = 1000;
MAT(2).G = 30e9;         % Shear modulus (30 GPa)
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

% --- Phase 3: Lithospheric Mantle (Olivine) ---
MAT(3).phase = 3;
MAT(3).rho0 = 3300;      % Mantle density (kg/m^3)
MAT(3).alpha = 3e-5;
MAT(3).k = 3.3;
MAT(3).cp = 1000;
MAT(3).G = 30e9;         % Shear modulus (30 GPa)
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

% ADDITIONAL PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.YNElast = 1;      % Elasticity ON
PARAMS.YNPlas = 1;       % Plasticity ON
PARAMS.tau_heal = 1e12;  % Healing time (s)
PARAMS.gx = 0;           % Gravity along X
PARAMS.gy = 9.8;         % Gravity along Y (downward)
PARAMS.fracCFL = 0.5;    
PARAMS.dt_fixed = 1e10;  % Fixed timestep in seconds (~317 yrs) to prevent jumping dt
PARAMS.R = 8.314;        
PARAMS.etamax = 1e25;    
PARAMS.etamin = 1e18;    
PARAMS.Tsolve = 1;       

% Initial linear geotherm (0 deg C at top to 1000 deg C at bottom; water reset to 0 deg C)
PARAMS.a0 = 0;
PARAMS.a1 = 1000 / ysize;
PARAMS.a2 = 0;
PARAMS.a3 = 0;
PARAMS.amp = 0;
PARAMS.lam = 1;
PARAMS.ynTreset = 1;     % Keeps T = T0 in Phase 1 (sticky water)
PARAMS.T0 = 0;           

PARAMS.rhoref = MAT(3).rho0; 
PARAMS.kref = 3.3;
PARAMS.cpref = 1000;

% TOPOGRAPHY CONTROL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.Ntopo_markers = 1000; 
PARAMS.YNSurfaceProcesses = 0;  % OFF: Prevents diffusive erosion
PARAMS.FixTopography = 1;       % ON: Locks topography profile & marker interface in place
PARAMS.topo_kappa = 0;          

% Initialize topography marker chain directly from x_data, y_data
PARAMS.custom_topo_x = linspace(0, xsize, PARAMS.Ntopo_markers);
PARAMS.custom_topo_y = interp1(x_data, y_data, PARAMS.custom_topo_x, 'linear', 'extrap');

% SOLVER ITERATIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.Npicard_min = 10;
PARAMS.Npicard_max = 100;
PARAMS.conv_crit_ResL2 = 1e-9;
PARAMS.pitswitch = 0;

% BOUNDARY CONDITIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.p0cell = 0;

% Free-slip rollers with zero normal velocity on all boundaries
BC.top   = [1 0 0];
BC.bot   = [1 0 0];
BC.left  = [1 0 0];
BC.right = [1 0 0];
PARAMS.BalanceStickyLayer = 0;

% Thermal Boundary Conditions
BCtherm.top   = [1 0];     % T = 0 deg C at top
BCtherm.bot   = [1 1000];  % T = 1000 deg C at bottom
BCtherm.left  = [2 0];     % Insulating side walls
BCtherm.right = [2 0];