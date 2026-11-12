% SiStER_RESUME.m
%
% Simple Stokes solver with Exotic Rheologies
% Script to resume a calculation
%
close all

% 1. INITIALIZE GRID AND PARAMETERS
if exist('running_from_SiStER_RUN','var')==0
    clear 
    % Call SiStER_Input with menu auto-list and validation support
    InpFil = SiStER_Input(input('Input file (or press Enter to list): ', 's'));
end
run(InpFil)
SiStER_Initialize % Sets up PARAMS, dx, dy, Nt, and fresh arrays

% 2. OVERWRITE WITH SAVED STATE
clear RestartFile
RestartInput = strtrim(input('Enter the .mat file to resume from (or press Enter to list): ', 's'));

if isempty(RestartInput)
    allMats = dir('**/*.mat');
    if isempty(allMats)
        error('No .mat checkpoint files found.');
    end
    
    % Filter .mat files that match the chosen InpFil (via saved InpFil or grid/BC signature)
    matched = false(size(allMats));
    for k = 1:length(allMats)
        fPath = fullfile(allMats(k).folder, allMats(k).name);
        info = whos('-file', fPath);
        varNames = {info.name};
        
        if ismember('InpFil', varNames)
            m = matfile(fPath);
            matched(k) = strcmp(m.InpFil, InpFil);
        elseif ismember('X', varNames) && ismember('BC', varNames)
            xInfo = info(strcmp(varNames, 'X'));
            if isequal(xInfo.size, [Ny, Nx])
                m = matfile(fPath);
                matched(k) = isequal(m.BC, BC);
            end
        end
    end
    
    % Use filtered list if any matched; otherwise show all .mat files
    if any(matched)
        matFiles = allMats(matched);
    else
        matFiles = allMats;
    end
    
    % Sort by folder name, then numerically by iteration number (1, 2, ..., 10)
    folders = {matFiles.folder};
    nums = arrayfun(@(f) str2double(erase(f.name, '.mat')), matFiles);
    [~, sortIdx] = sortrows([folders(:), num2cell(nums(:))]);
    matFiles = matFiles(sortIdx);
    
    fprintf('\nMatching Checkpoint Files:\n');
    for k = 1:length(matFiles)
        relPath = erase(fullfile(matFiles(k).folder, matFiles(k).name), [pwd filesep]);
        fprintf('  [%d] %s\n', k, relPath);
    end
    fprintf('\n');
    
    choice = strtrim(input('Select file number or type path/filename: ', 's'));
    numChoice = str2double(choice);
    if ~isnan(numChoice) && floor(numChoice) == numChoice && numChoice >= 1 && numChoice <= length(matFiles)
        RestartFile = fullfile(matFiles(numChoice).folder, matFiles(numChoice).name);
    else
        RestartInput = choice;
    end
end

if ~exist('RestartFile', 'var') || isempty(RestartFile)
    if isempty(RestartInput)
        error('No checkpoint file selected.');
    end
    if ~endsWith(RestartInput, '.mat')
        RestartInput = [RestartInput, '.mat'];
    end
    RestartFile = RestartInput;
end

% Remember which folder the checkpoint came from so new outputs go back there
[resumeFolder, ~, ~] = fileparts(RestartFile);
load(RestartFile); % Overwrites time, xm, ym, ep, etam, etc. with saved state

% Extract current time step from filename to start loop correctly
[~, name, ~] = fileparts(RestartFile);
t_start = str2double(name);

% Recalculate advection time step for the loaded velocity field
[dt_m] = SiStER_set_timestep(dx,dy,vx,vy,PARAMS);

% --- RECONSTRUCT UNSAVED STATE VARIABLES FOR CONTINUATION ---
% The .mat file saves 'etam' but the bisection solver requires 'etas' 
% and 'etas_new' (shear node viscosity) leftover from the previous step.
tmp_etas = SiStER_interp_markers_to_shear_nodes(xm,ym,icn,jcn,qd,x,y,etam);
etas = tmp_etas(1).data;
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
        save(filename,'X','Y','vx','vy','p','time','xm','ym','etam','rhom','BC','etan','Tm','im','idm','epsIIm','sxxm','sxym','ep','epNH','icn','jcn','qd','topo_x','topo_y','InpFil')
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

% Move newly saved .mat outputs back into the resumed run's folder
if ~isempty(resumeFolder)
    SiStER_MoveFiles2Folder(resumeFolder);
end

disp('FIN')