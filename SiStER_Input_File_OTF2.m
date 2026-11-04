% SiStER_Input_File_otf1
% Vertical Cross-Section across an Ocean Transform Fault (OTF)

% DURATION OF SIMULATION AND FREQUENCY OF OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%
Nt = 100;          % max number of time iterations
dt_out = 10;        % output files every "dt_out" iterations



%Testing/initialization
Nt=1; % max number of time iterations
dt_out=10; % output files every "dt_out" iterations




% DOMAIN SIZE AND GRIDDING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xsize = 100e3;     % 100 km wide domain
ysize = 50e3;      % 50 km deep domain

% Horizontal Gridding: Refined in the center near the fault zone (40-60 km)
GRID.dx(1) = 2000;  GRID.x(1) = 40e3;
GRID.dx(2) = 500;   GRID.x(2) = 60e3;  % High resolution across the fault core
GRID.dx(3) = 2000;

% Vertical Gridding: High resolution near the top (0-15 km) to capture water & crust
GRID.dy(1) = 500;   GRID.y(1) = 15e3;  % High resolution for crust/water interface
GRID.dy(2) = 2000;

% LAGRANGIAN MARKERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Mquad = 8;          % number of markers in the smallest quadrant
Mquad_crit = 4;     % minimum number of markers allowed in smallest quadrant (for reseeding)

% GEOMETRY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nphase = 4;         % 1: Water, 2: Crust, 3: Mantle, 4: Fault Core

% Phase 1: Sticky Water Layer
GEOM(1).type = 1; 
GEOM(1).top  = 0;
GEOM(1).bot  = 5e3;    % 5 km ocean depth

% Phase 2: Oceanic Crust (Basalt/Gabbro)
GEOM(2).type = 1; 
GEOM(2).top  = 5e3;
GEOM(2).bot  = 12e3;   % 7 km crustal thickness

% Phase 3: Lithospheric Mantle (Olivine)
GEOM(3).type = 1; 
GEOM(3).top  = 12e3;
GEOM(3).bot  = ysize;  % Down to 50 km depth

% Phase 4: Transform Fault Weak Zone
% GEOM(4) is intentionally left blank here. Phase 4 will be assigned
% over the central region in your runner script.

% MATERIAL PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Phase 1: Sticky Water ---
MAT(1).phase = 1;
MAT(1).rho0 = 1000;      % Water density
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
MAT(2).rho0 = 2900;      % Crustal density
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
MAT(3).rho0 = 3300;      % Mantle density
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

% --- Phase 4: Transform Fault Core (Damaged/Weakened Rock) ---
MAT(4) = MAT(2);         % Inherit base properties from crust/mantle
MAT(4).phase = 4;
MAT(4).mu = 0.1;         % Lower friction coefficient
MAT(4).mumin = 0.05;
MAT(4).Cmax = 1e6;       % Heavily reduced cohesion (1 MPa vs 40 MPa)
MAT(4).Cmin = 0.01e6;

% ADDITIONAL PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.YNElast = 1;      % Elasticity ON
PARAMS.YNPlas = 1;       % Plasticity ON
PARAMS.tau_heal = 1e12;  % Healing time (s)
PARAMS.gx = 0;           % Gravity along X
PARAMS.gy = 9.8;         % Gravity along Y
PARAMS.fracCFL = 0.5;    % CFL condition
PARAMS.R = 8.314;        % Gas constant
PARAMS.etamax = 1e25;    % Max viscosity
PARAMS.etamin = 1e18;    % Min viscosity
PARAMS.Tsolve = 1;       % Solve for temperature

% Default polynomial zeroed out so custom initial T profile is clean
PARAMS.a0 = 0;
PARAMS.a1 = 0;
PARAMS.a2 = 0;
PARAMS.a3 = 0;
PARAMS.amp = 0;
PARAMS.lam = 1;
PARAMS.ynTreset = 1;     % Reset T=T0 in sticky water layer
PARAMS.T0 = 0;           % Surface/water temperature

% Reference thermal properties
PARAMS.rhoref = MAT(3).rho0; 
PARAMS.kref = 3.3;
PARAMS.cpref = 1000;

% TOPOGRAPHY EVOLUTION
PARAMS.Ntopo_markers = 1000;
PARAMS.YNSurfaceProcesses = 1;
PARAMS.topo_kappa = 1e-8;

% SOLVER ITERATIONS
PARAMS.Npicard_min = 10;
PARAMS.Npicard_max = 100;
PARAMS.conv_crit_ResL2 = 1e-9;
PARAMS.pitswitch = 0;

% BOUNDARY CONDITIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pressure anchor
PARAMS.p0cell = 0;

% Flow: Static Cross-Section (rollers on all sides, zero normal velocity)
BC.top   = [1 0 0];
BC.bot   = [1 0 0];
BC.left  = [1 0 0];
BC.right = [1 0 0];

PARAMS.BalanceStickyLayer = 1;

% Thermal Boundary Conditions
BCtherm.top   = [1 0];     % Dirichlet T = 0 at surface
BCtherm.bot   = [1 1000];  % Dirichlet T = 1000 deg C at bottom boundary
BCtherm.left  = [2 0];     % Neumann zero heat flux
BCtherm.right = [2 0];     % Neumann zero heat flux