% SiStER_RESUME.m
%
% Simple Stokes solver with Exotic Rheologies
% Script to resume a calculation
%
close all

% 1. INITIALIZE GRID AND PARAMETERS
if exist('running_from_SiStER_RUN','var')==0
    clear 
    InpFil = input('Input file ? ','s');
end
run(InpFil)
SiStER_Initialize % Sets up PARAMS, dx, dy, Nt, and fresh arrays

% 2. OVERWRITE WITH SAVED STATE
RestartInput = input('Enter the .mat file to resume from (e.g., ''80'' or ''80.mat''): ', 's');

% Check if the input ends with '.mat'
if ~endsWith(RestartInput, '.mat')
    RestartFile = [RestartInput, '.mat'];
else
    RestartFile = RestartInput;
end
load(RestartFile); % Overwrites time, xm, ym, ep, etam, etc. with saved state

% Extract current time step from filename to start loop correctly
[~, name, ~] = fileparts(RestartFile);
t_start = str2double(name);

% Recalculate advection time step for the loaded velocity field
[dt_m] = SiStER_set_timestep(dx,dy,vx,vy,PARAMS);

% --- RECONSTRUCT UNSAVED STATE VARIABLES FOR CONTINUATION ---
% The .mat file saves 'etam' but the bisection solver requires 'etas' 
% and 'etas_new' (shear node viscosity) leftover from the previous step.
etas = SiStER_interp_markers_to_shear_nodes(xm,ym,icn,jcn,qd,x,y,etam);
etas_new = etas;
% ------------------------------------------------------------

% 3. BEGIN TIME LOOP FROM RESUMED STEP
for t = (t_start + 1):Nt 
    
    disp(['STARTING ITERATION: ' num2str(t) ' out of ' num2str(Nt)])
    
    % update time
    time=time+dt_m;
    
    % Here we prepare nodal arrays to feed the Stokes solver 
    SiStER_material_props_on_nodes
    
    %%% SOLVE STOKES WITH NON-LINEAR RHEOLOGY HERE 
    SiStER_flow_solve
    
    % GET STRAIN RATE FROM CURRENT SOLUTION
    epsIIm=SiStER_interp_shear_nodes_to_markers(epsII_s,x,y,xm,ym,icn,jcn);
    
    % USE STRAIN RATE TO UPDATE STRESSES ON MARKERS
    SiStER_update_marker_stresses;
    
    % BUILD UP PLASTIC STRAIN IN YIELDING AREAS IF PLASTICITY IS ACTIVATED
    if (PARAMS.YNPlas==1) 
        SiStER_update_ep;
    end
  
    % OUTPUT VARIABLES OF INTEREST (prior to rotation & advection)
    if (mod(t,dt_out)==0 && dt_out>0) || t==1 || t==Nt 
        disp('SAVING SELECTED VARIABLES TO OUTPUT FILE') 
        filename=num2str(t);
        [etam]=SiStER_interp_shear_nodes_to_markers(etas,x,y,xm,ym,icn,jcn); 
        save(filename,'X','Y','vx','vy','p','time','xm','ym','etam','rhom','BC','etan','Tm','im','idm','epsIIm','sxxm','sxym','ep','epNH','icn','jcn','qd','topo_x','topo_y')
    end
    
    % SET ADVECTION TIME STEP BASED ON CURRENT FLOW SOLUTION
    [dt_m]=SiStER_set_timestep(dx,dy,vx,vy,PARAMS);
    
    % ROTATE ELASTIC STRESSES IN CURRENT FLOW FIELD
    if (PARAMS.YNElast==1) 
        SiStER_rotate_stresses;
    end
    
    % EVOLVE TEMPERATURE FIELD THROUGH DIFFUSION
    if PARAMS.Tsolve==1
        SiStER_thermal_update;
    end
    
    % MARKER ADVECTION, REMOVAL, AND ADDITION 
    SiStER_move_remove_and_reseed_markers;
    SiStER_update_topography_markers
    
    disp('---------------')
    disp(['END OF ITERATION: ' num2str(t) ' out of ' num2str(Nt) ' - SIMULATION TIME: ' num2str(time/365.25/24/3600/1000) ' kyrs.'])
    disp('--------------------------------')
    disp('--------------------------------')
    
end
disp('FIN')