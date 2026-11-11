% SiStER Initialize

PARAMS.Nphase = Nphase; % for convenience

% construct staggered grids
[X,Y,x,y,xc,yc,dx,dy,Nx,Ny] = SiStER_initialize_grid(xsize,ysize,GRID);

% initialize marker arrays and positions
[xm, ym] = SiStER_initialize_marker_positions(xsize,ysize,dx,dy,Mquad);

% locate markers with respect to grid
[qd,icn,jcn] = SiStER_locate_markers_in_grid(xm,ym,x,y,dx,dy);

% assign marker phases
[im] = SiStER_initialize_marker_phases(Nphase,GEOM,xm,ym);
% initialize marker plastic strain (to zero) and strain rate (to one)
ep=zeros(size(xm));
epNH=ep;
epsIIm=ones(size(xm));

% initialize marker stresses
sxxm=zeros(size(xm));
sxym=sxxm;

% initialize marker index (a unique number to identify and track each marker)
idm=1:length(xm);

% initialize temperature structure on nodes
T=PARAMS.a0+PARAMS.a1*Y+PARAMS.a2*Y.^2+PARAMS.a3*Y.^3;
T=T+PARAMS.amp*sin(2*pi*X/PARAMS.lam);
if PARAMS.ynTreset==1 % reset T=T0 in top layer
    T(T<PARAMS.T0)=PARAMS.T0;
end
% pass initial nodal T to markers
[Tm]=SiStER_interp_shear_nodes_to_markers(T,x,y,xm,ym,icn,jcn);
Tm0=Tm;

% initialize nodal strain rate and other useful arrays
EXX=zeros(size(X));
EXY=zeros(size(X));
vx=zeros(size(X));
vy=zeros(size(X));
v=vx;
p=1e12*ones(size(EXX));  %initialize to be high so plasticity doesnt activate at t=1, pit=1;
etan_new=zeros(Ny,Nx);
%-------------------------------------------------------------------------
% initialize dt_m small to keep things elastic & no plasticity at t=1, G.Ito
%-------------------------------------------------------------------------
if (exist('dt_m','var')==0);
    dt_m=1e2;
end

% initialize marker chain to track base of layer 1 (sticky layer)
Ntopo = PARAMS.Ntopo_markers;
topo_x = linspace(0, xsize, Ntopo);

if isfield(PARAMS, 'custom_topo_y')
    topo_y = PARAMS.custom_topo_y;
else
    topo_y = GEOM(1).bot * ones(size(topo_x));
end

topo_marker_spacing = mean(diff(topo_x));

% CUSTOM MARKER PHASE OVERRIDE (Rectangular Box + Constant Moho Depth at 8 km)
if isfield(PARAMS, 'x_data') && isfield(PARAMS, 'y_data')
    y_seafloor_at_xm = interp1(PARAMS.x_data, PARAMS.y_data, xm, 'linear', 'extrap');
    
    % Phase 1 (Sticky Water): Surface (0 km) down to bathymetry seafloor
    im(ym <= y_seafloor_at_xm) = 1;
    
    % Phase 2 (Oceanic Crust): Seafloor down to fixed Moho depth of 8 km
    % (Crust is 4 km thick along the flanks, narrowing to 2 km thick under the box divot)
    im(ym > y_seafloor_at_xm & ym <= 8e3) = 2;
    
    % Phase 3 (Lithospheric Mantle): Everything below 8 km depth down to bottom
    im(ym > 8e3) = 3;
end