% SiStER_Input_File_OTF7.m
% Vertical Cross-Section with Static Bathymetry, Flexible Moho, and Fixed Timestep

quickPlot='OTF7';

% DURATION OF SIMULATION AND FREQUENCY OF OUTPUT %%%%%%%%%%%%%%%%%%%%%%%%%%
Nt = 20;             % number of time iterations
dt_out = 1;          % save output every iteration

% DOMAIN SIZE AND GRIDDING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
xsize = 100e3;       % 100 km wide domain
ysize = 50e3;        % 30 km deep domain

% Horizontal Gridding: Refined in the center near the fault/relief (40-60 km)
GRID.dx(1) = 2000;   GRID.x(1) = 40e3;   % Coarse left far-field (0 to 40 km)
GRID.dx(2) = 250;    GRID.x(2) = 48e3;   % 250 m resolution across central zone (40 to 60 km)
GRID.dx(3) = 100;    GRID.x(3) = 52e3;
GRID.dx(4) = 250;    GRID.x(4) = 60e3;
GRID.dx(5) = 2000;                       % Coarse right far-field (60 to 100 km)

% Vertical Gridding: High resolution from 3 to 15 km depth (relief, crust & Moho)
GRID.dy(1) = 500;   GRID.y(1) = 2e3;    % Coarse upper water layer (0 to 3 km) -> 2 exact cells of 1500 m
GRID.dy(2) = 250;    GRID.y(2) = 16e3;   % 250 m resolution across seafloor & Moho (3 to 15 km) -> 48 cells
GRID.dy(3) = 2000;                       % Coarse deep mantle (15 to 50 km) -> 14 exact cells of 2500 m

% LAGRANGIAN MARKERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Mquad = 8;           % markers in smallest quadrant
Mquad_crit = 4;      % minimum markers allowed for reseeding

% BATHYMETRY / TOPOGRAPHY & MOHO DEFINITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% x = distance along profile (m), y = depth from top of domain (m)
x_data = [0,  45e3, 45e3+1, 49e3, 50e3, 51e3, 55e3-1, 55e3, 100e3];
y_data = [4e3, 4e3, 6e3,    6e3,  5.5e3, 6e3,  6e3,    4e3,  4e3];

PARAMS.x_data = x_data;
PARAMS.y_data = y_data;
PARAMS.moho_depth = 12e3;  % Flexible Moho depth (m) — change for continental/other settings

% GEOMETRY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Nphase = 3;          % 1: Sticky Water/Air, 2: Crust, 3: Mantle

% Baseline horizontal layers (overridden by PARAMS.x_data/y_data/moho_depth in SiStER_Initialize)
% 1 = layer (then specify top and bot) or 2 = circle % 1 = layer (then specify top and bot) or 2 = circle (then specify center and radius)
GEOM(1).type = 1; GEOM(1).top = 0;                 GEOM(1).bot = 4e3;
GEOM(2).type = 1; GEOM(2).top = 4e3;               GEOM(2).bot = PARAMS.moho_depth;
GEOM(3).type = 1; GEOM(3).top = PARAMS.moho_depth; GEOM(3).bot = ysize;

% MATERIAL PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% creep laws of the form: pre^(-1/n)*epsII^((1-n)/n)*exp(E/(nRT))
% harmonically averaging diffusion creep, dislocation creep 
% (and plastic creep to simulate brittle failure)

% --- Phase 1: Sticky Water ---
MAT(1).phase = 1;
MAT(1).rho0 = 1000;      % Water density (kg/m^3)
MAT(1).alpha = 0;        % Thermal Expansion parameter (Thermal dependence of density)
MAT(1).k = 3;            % Conductivity   
MAT(1).cp = 1000;        % heat capacity
MAT(1).G = 1e18;         % Shear Modulus (Elasticity) effectively non-elastic fluid when really high
% diffusion creep parameters
MAT(1).pre_diff = .5/1e18; 
MAT(1).Ediff = 0;
MAT(1).ndiff = 1;
% dislocation creep parameters
MAT(1).pre_disc = .5/1e18;
MAT(1).Edisc = 0;
MAT(1).ndisc = 1;
% plasticity
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
PARAMS.YNElast = 1;      % Elasticity ON (1) or off (0)
PARAMS.YNPlas = 1;       % Plasticity ON (1) or off (0)
PARAMS.tau_heal = 1e12;  % healing time for plasticity (s)
PARAMS.gx = 0;           % Gravity along X (m/s^2)
PARAMS.gy = 9.81;        % Gravity along Y (downward) (m/s^2)
PARAMS.fracCFL = 0.5;    % distance by which a marker is allowed to move over a time step, expressed as a fraction of the smallest cell size
PARAMS.dt_fixed = 1e10;  % Fixed timestep in seconds (~317 yrs) to prevent jumping dt
PARAMS.R = 8.314;        % Gas Constatnt   
PARAMS.etamax = 1e25;    % Maximum Viscosity
PARAMS.etamin = 1e18;    % Minimum Viscosity
PARAMS.Tsolve = 1;       % yes (1) or no (0) solve for temperature

% initial temperature profile, polynomial with depth 
% T = a0 + a1*y+a2*y^2+a3*y^3+amp*sin(2*pi*X/lam)
% (make sure it matches the BCs)

% Initial linear geotherm (0 deg C at top to 1000 deg C at bottom; water reset to 0 deg C)
y_sf = 4e3;                % Reference seafloor depth (m)
dTdz = 20e-3;              % Desired geothermal gradient (e.g., 20 deg C/km)

PARAMS.a0 = -dTdz * y_sf;  % T = 0 deg C right at the 4 km seafloor
PARAMS.a1 = dTdz;
PARAMS.a2 = 0;
PARAMS.a3 = 0;
PARAMS.amp = 0;          % amplitude of sinusoidal perturbation
PARAMS.lam = 1;          % wavelength of sinusoidal perturbation
PARAMS.ynTreset = 1;     % Keeps T = T0 in Phase 1 (sticky water). if ==1, reset T=T0 where im==1 (sticky layer)
PARAMS.T0 = 0;           

% reference values for the constant diffusivity thermal solver
% (kappa = kref / (rhoref*cpref))
PARAMS.rhoref = MAT(2).rho0; 
PARAMS.kref = 3;
PARAMS.cpref = 1000;

% TOPOGRAPHY CONTROL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.Ntopo_markers = 2000;    % number of markers in marker chain tracking topography
PARAMS.YNSurfaceProcesses = 0;  % OFF: Prevents diffusive erosion  % surface processes (diffusion of topography) on or off
PARAMS.FixTopography = 1;       % ON: Locks topography profile & marker interface in place
PARAMS.topo_kappa = 0;          % diffusivity of topography (m^2/s)  

% Initialize topography marker chain directly from x_data, y_data
PARAMS.custom_topo_x = linspace(0, xsize, PARAMS.Ntopo_markers);
PARAMS.custom_topo_y = interp1(x_data, y_data, PARAMS.custom_topo_x, 'linear', 'extrap');

% SOLVER ITERATIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.Npicard_min = 10;        % minimum number of Picard iterations per time step
PARAMS.Npicard_max = 100;       % maximum number of Picard iterations per time step
PARAMS.conv_crit_ResL2 = 1e-9;  % Convergence is achieved when residual is below this value
PARAMS.pitswitch = 0;           % number of Picard iterations at which the solver switches to quasi-Newton

% BOUNDARY CONDITIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PARAMS.p0cell = 0;              % pressure in the top-left corner of the domain (anchor point)

% Flow

% boundary conditions
% entries in BC correspond to
% 1/ rollers? (1=yes, 0=no)
% 2/ type of velocity normal to boundary (0=constant)
% 3/ value of normal velocity 

% Free-slip rollers with zero normal velocity on all boundaries
BC.top   = [1 0 0];
BC.bot   = [1 0 0];
BC.left  = [1 0 0];
BC.right = [1 0 0];
PARAMS.BalanceStickyLayer = 0;  % if set to 1, the code will reset the inflow 
% / outflow BCs to balance the inflow / outflow of sticky layer material,
% and rock separately, based on the position of the sticky layer / air
% interface

% Thermal Boundary Conditions
% entries in BCtherm correspond to
% 1/ type? (1=Dirichlet, 2=Neumann)
% 2/ value
BCtherm.top   = [1 0];     % T = 0 deg C at top
BCtherm.bot   = [1, dTdz * (ysize - y_sf)];  % Matches geotherm at y = ysize
BCtherm.left  = [2 0];     % Insulating side walls
BCtherm.right = [2 0];