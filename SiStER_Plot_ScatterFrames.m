function SiStER_Plot_ScatterFrames(targetDir, zVar, varargin)
% SiStER_Plot_ScatterFrames Animates and saves scatter plots of SiStER output.
%
% Usage:
%   SiStER_Plot_ScatterFrames('Wedge_default') % Will prompt for variable
%   SiStER_Plot_ScatterFrames('Wedge_default', 'Tm', 'markerSize', 15, 'figWidth', 1200)
%   SiStER_Plot_ScatterFrames('Wedge_default', 'Tm', 'useParallel', true) 
%   SiStER_Plot_ScatterFrames('Wedge_default', 'Tm', 'showFigure', false) 

    % 1. Enforce required directory input
    if nargin < 1 || isempty(targetDir)
        error('A target directory must be provided. Example: SiStER_Plot_ScatterFrames(''Wedge_default'')');
    end
    if ~isfolder(targetDir)
        error('Directory "%s" does not exist.', targetDir);
    end
    
    % 2. Handle zVar input or Interactive prompt
    if nargin >= 2 && isnumeric(zVar)
        zVar = num2str(zVar);
    end
    if nargin < 2 || isempty(zVar)
        fprintf('\n--- Available Marker Variables ---\n');
        fprintf('  1) epsIIm - 2nd invariant of strain rate (1/s)\n');
        fprintf('  2) etam   - Viscosity (Pa.s)\n');
        fprintf('  3) Tm     - Temperature\n');
        fprintf('  4) rhom   - Density (kg/m^3)\n');
        fprintf('  5) im     - Material Phase (rock type index)\n');
        fprintf('  6) ep     - Accumulated Plastic Strain\n');
        fprintf('  7) sxxm   - Normal Deviatoric Stress (Pa)\n');
        fprintf('  8) sxym   - Shear Deviatoric Stress (Pa)\n');
        fprintf('  9) idm    - Unique marker ID numbers\n');
        
        zVar = input('\nEnter a number (1-9) OR type an exact variable name: ', 's');
    end
    
    switch strtrim(zVar)
        case '1', zVar = 'epsIIm';
        case '2', zVar = 'etam';
        case '3', zVar = 'Tm';
        case '4', zVar = 'rhom';
        case '5', zVar = 'im';
        case '6', zVar = 'ep';
        case '7', zVar = 'sxxm';
        case '8', zVar = 'sxym';
        case '9', zVar = 'idm';
        otherwise, zVar = strtrim(zVar); 
    end
    
    % 3. Parse optional arguments
    p = inputParser;
    addParameter(p, 'xVar', 'xm', @ischar);
    addParameter(p, 'yVar', 'ym', @ischar);
    addParameter(p, 'logZ', [], @(x) islogical(x) || isempty(x)); 
    addParameter(p, 'filterAir', true, @islogical);
    addParameter(p, 'markerSize', 10, @isnumeric);
    addParameter(p, 'figWidth', 1000, @isnumeric);
    addParameter(p, 'figHeight', 600, @isnumeric);
    addParameter(p, 'cLimit', [], @isnumeric);      
    addParameter(p, 'imgFormat', 'png', @ischar); 
    addParameter(p, 'showFigure', false, @islogical);  % Toggle visible plotting
    addParameter(p, 'useParallel', true, @islogical); % Enable parfor loop
    % ------------------------------------------
    
    parse(p, varargin{:});
    opts = p.Results;
    
    if isempty(opts.logZ)
        opts.logZ = any(strcmp(zVar, {'epsIIm', 'etam'}));
    end
    
    if opts.logZ
        plotTitleVar = ['log_{10}(' strrep(zVar, '_', '\_') ')'];
    else
        plotTitleVar = strrep(zVar, '_', '\_');
    end
    
    % 4. Locate and sort .mat files
    matFiles = dir(fullfile(targetDir, '*.mat'));
    if isempty(matFiles)
        error('No .mat files found in directory: %s', targetDir);
    end
    
    fileNums = zeros(length(matFiles), 1);
    for k = 1:length(matFiles)
        [~, name, ~] = fileparts(matFiles(k).name);
        fileNums(k) = str2double(name);
    end
    [~, sortIdx] = sort(fileNums);
    matFiles = matFiles(sortIdx);
    numFiles = length(matFiles);
    
    % 5. Create the output image directory
    outDir = fullfile(targetDir, sprintf('%s_plots', zVar));
    if ~isfolder(outDir)
        mkdir(outDir);
    end
    fprintf('Plots will be saved as .%s in: %s\n', opts.imgFormat, outDir);
    
    varsToLoad = unique({opts.xVar, opts.yVar, zVar, 'time', 'im'}); 
    
    % 6. PRE-SCAN: Find Global Min/Max to lock dimensions perfectly
    fprintf('Scanning %d files for global limits...\n', numFiles);
    xMin = inf; xMax = -inf; yMin = inf; yMax = -inf; zMin = inf; zMax = -inf;
    
    for k = 1:numFiles
        data = load(fullfile(targetDir, matFiles(k).name), varsToLoad{:});
        if ~isfield(data, opts.xVar) || ~isfield(data, zVar), continue; end
        
        X = data.(opts.xVar); Y = data.(opts.yVar); Z = data.(zVar);
        if strcmp(opts.xVar, 'xm'), X = X / 1e3; end
        if strcmp(opts.yVar, 'ym'), Y = Y / 1e3; end
        
        if opts.filterAir && isfield(data, 'im')
            mask = data.im > 1;
            X = X(mask); Y = Y(mask); Z = Z(mask);
        end
        if opts.logZ, Z = log10(Z); end
        
        if isempty(X), continue; end
        
        xMin = min(xMin, min(X(:))); xMax = max(xMax, max(X(:)));
        yMin = min(yMin, min(Y(:))); yMax = max(yMax, max(Y(:)));
        zMin = min(zMin, min(Z(:))); zMax = max(zMax, max(Z(:)));
    end
    
    xLims = [xMin, xMax];
    yLims = [yMin, yMax];
    if ~isempty(opts.cLimit)
        cLims = opts.cLimit; 
    else
        cLims = [zMin, zMax];
    end
    fprintf('Global limits locked. Plotting...\n');

    % 7. PLOTTING LOOP (Parallel vs Sequential)
    if opts.useParallel
        % Parallel mode always plots headlessly (requires Parallel Computing Toolbox)
        parfor k = 1:numFiles
            fileName = matFiles(k).name;
            fullPath = fullfile(targetDir, fileName);
            
            % Create an invisible figure for each worker
            fig = figure('Visible', 'off', 'Position', [100, 100, opts.figWidth, opts.figHeight]);
            
            % Call helper function to handle the actual plotting
            processFrame(fig, fullPath, fileName, varsToLoad, opts, zVar, plotTitleVar, xLims, yLims, cLims, outDir, k);
            close(fig);
        end
    else
        % Sequential mode reuses a single figure for speed
        if opts.showFigure, vis = 'on'; else, vis = 'off'; end
        fig = figure('Visible', vis, 'Position', [100, 100, opts.figWidth, opts.figHeight]);
        
        for k = 1:numFiles
            fileName = matFiles(k).name;
            fullPath = fullfile(targetDir, fileName);
            processFrame(fig, fullPath, fileName, varsToLoad, opts, zVar, plotTitleVar, xLims, yLims, cLims, outDir, k);
        end
        close(fig);
    end
    
    fprintf('Finished saving %d frames to %s\n', numFiles, outDir);
end

% =========================================================================
% LOCAL HELPER FUNCTION: Handles the plotting and exporting for a single frame
% =========================================================================
function processFrame(fig, fullPath, fileName, varsToLoad, opts, zVar, plotTitleVar, xLims, yLims, cLims, outDir, k)
    try
        data = load(fullPath, varsToLoad{:});
    catch
        warning('Could not load %s. Skipping.', fileName);
        return;
    end
    
    if ~isfield(data, opts.xVar) || ~isfield(data, opts.yVar) || ~isfield(data, zVar)
        return;
    end
    
    X = data.(opts.xVar); Y = data.(opts.yVar); Z = data.(zVar);
    if strcmp(opts.xVar, 'xm'), X = X / 1e3; end
    if strcmp(opts.yVar, 'ym'), Y = Y / 1e3; end
    
    if opts.filterAir && isfield(data, 'im')
        mask = data.im > 1;
        X = X(mask); Y = Y(mask); Z = Z(mask);
    end
    if opts.logZ, Z = log10(Z); end
    
    % Draw Frame
    figure(fig);
    cla;
    fastscatter(X, Y, Z, 'markersize', opts.markerSize);
    
    if isfield(data, 'time')
        timeMyrs = data.time / (365.25 * 24 * 3600 * 1e6);
        title(sprintf('%s | Time: %.3f Myrs (File: %s)', plotTitleVar, timeMyrs, fileName), 'FontSize', 14);
    else
        title(sprintf('%s | File: %s', plotTitleVar, fileName), 'FontSize', 14);
    end
    
    xlabel([strrep(opts.xVar, '_', '\_') ' (km)'], 'FontSize', 12);
    ylabel([strrep(opts.yVar, '_', '\_') ' (km)'], 'FontSize', 12);
    
    % Lock layout with global limits
    axis equal;
    xlim(xLims);
    ylim(yLims);
    set(gca, 'YDir', 'reverse', 'FontSize', 12);
    
    colormap('parula');
    cb = colorbar;
    clim(cLims); % Forces colorbar tick widths to remain completely static
    ylabel(cb, plotTitleVar, 'FontSize', 12);
    
    % Export
    drawnow;
    imgName = fullfile(outDir, sprintf('frame_%04d.%s', k, opts.imgFormat));
    exportgraphics(fig, imgName, 'Resolution', 300);
end