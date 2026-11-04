function SiStER_Plot_ScatterFrames(targetDir, zVar, varargin)
% SiStER_Plot_ScatterFrames Animates and saves scatter plots of SiStER output.
%
% Usage:
%   SiStER_Plot_ScatterFrames('Wedge_default') % Will prompt for variable
%   SiStER_Plot_ScatterFrames('Wedge_default', 'all') % Plots all 9 variables
%   SiStER_Plot_ScatterFrames('Wedge_default', 10)    % Plots all 9 variables
%   SiStER_Plot_ScatterFrames('Wedge_default', 'Tm', 'markerSize', 15, 'figWidth', 1200)

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
        fprintf(' 10) all    - Plot all 9 standard variables\n');
        
        zVar = input('\nEnter a number (1-10), an exact variable name, or "all": ', 's');
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
        case '10', zVar = 'all';
        otherwise
            zVar = strtrim(zVar); 
            validVars = {'epsIIm', 'etam', 'Tm', 'rhom', 'im', 'ep', 'sxxm', 'sxym', 'idm', 'all'};
            % Validate that the input is actually a recognized variable
            if ~any(strcmpi(zVar, validVars))
                error('Invalid variable requested: "%s". Must be a valid variable name or number (1-10).', zVar);
            end
            % Ensure exact casing for consistency (e.g., if user typed 'tm', convert to 'Tm')
            matchIdx = find(strcmpi(zVar, validVars));
            zVar = validVars{matchIdx};
    end
    
    % === BATCH PROCESSING LOGIC FOR "ALL" ===
    if strcmp(zVar, 'all')
        allVars = {'epsIIm', 'etam', 'Tm', 'rhom', 'im', 'ep', 'sxxm', 'sxym', 'idm'};
        fprintf('\n======================================================\n');
        fprintf('Batch plotting ALL 9 variables in: %s\n', targetDir);
        fprintf('======================================================\n');
        
        for v = 1:length(allVars)
            fprintf('\n>>> Plotting variable %d/9: %s <<<\n', v, allVars{v});
            % Recursively call this function for each variable, passing all extra arguments
            SiStER_Plot_ScatterFrames(targetDir, allVars{v}, varargin{:});
        end
        fprintf('\n=== Finished batch plotting all variables ===\n');
        return; % Exit to prevent running the single-plot logic below
    end
    % ==============================================
    
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
    addParameter(p, 'showFigure', false, @islogical); 
    addParameter(p, 'useParallel', true, @islogical); 
    addParameter(p, 'colormap', 'parula'); 
    addParameter(p, 'bgColor', 'w');       
    % ---------------------------------------
    
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
    
    % --- NEW: Fix for uniform variables or flat spatial dimensions ---
    if cLims(1) >= cLims(2)
        if cLims(1) == 0, cLims = [-0.1, 0.1]; 
        else, cLims = [cLims(1) - abs(cLims(1))*0.01, cLims(1) + abs(cLims(1))*0.01]; end
    end
    
    if xLims(1) >= xLims(2)
        if xLims(1) == 0, xLims = [-0.1, 0.1]; 
        else, xLims = [xLims(1) - abs(xLims(1))*0.01, xLims(1) + abs(xLims(1))*0.01]; end
    end
    
    if yLims(1) >= yLims(2)
        if yLims(1) == 0, yLims = [-0.1, 0.1]; 
        else, yLims = [yLims(1) - abs(yLims(1))*0.01, yLims(1) + abs(yLims(1))*0.01]; end
    end
    % -----------------------------------------------------------------
    
    fprintf('Global limits locked. Plotting...\n');
    
    % 7. PLOTTING LOOP (Parallel vs Sequential)
    if opts.useParallel
        parfor k = 1:numFiles
            fileName = matFiles(k).name;
            fullPath = fullfile(targetDir, fileName);
            
            fig = figure('Visible', 'off', 'Position', [100, 100, opts.figWidth, opts.figHeight], 'Color', opts.bgColor);
            processFrame(fig, fullPath, fileName, varsToLoad, opts, zVar, plotTitleVar, xLims, yLims, cLims, outDir, k);
            close(fig);
        end
    else
        if opts.showFigure, vis = 'on'; else, vis = 'off'; end
        fig = figure('Visible', vis, 'Position', [100, 100, opts.figWidth, opts.figHeight], 'Color', opts.bgColor);
        
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
    
    % Text color handling 
    if isequal(opts.bgColor, 'k') || isequal(opts.bgColor, [0 0 0]) || isequal(opts.bgColor, 'black')
        txtColor = 'w';
    else
        txtColor = 'k';
    end
    
    if isfield(data, 'time')
        timeMyrs = data.time / (365.25 * 24 * 3600 * 1e6);
        title(sprintf('%s | Time: %.3f Myrs (File: %s)', plotTitleVar, timeMyrs, fileName), 'FontSize', 14, 'Color', txtColor);
    else
        title(sprintf('%s | File: %s', plotTitleVar, fileName), 'FontSize', 14, 'Color', txtColor);
    end
    
    xlabel([strrep(opts.xVar, '_', '\_') ' (km)'], 'FontSize', 12, 'Color', txtColor);
    ylabel([strrep(opts.yVar, '_', '\_') ' (km)'], 'FontSize', 12, 'Color', txtColor);
    
    % Lock layout
    axis equal;
    xlim(xLims);
    ylim(yLims);
    set(gca, 'YDir', 'reverse', 'FontSize', 12, 'Color', opts.bgColor, 'XColor', txtColor, 'YColor', txtColor);
    
    % Apply colormap
    colormap(opts.colormap);
    cb = colorbar('Color', txtColor);
    clim(cLims); 
    ylabel(cb, plotTitleVar, 'FontSize', 12, 'Color', txtColor);
    
    % Export
    drawnow;
    imgName = fullfile(outDir, sprintf('frame_%04d.%s', k, opts.imgFormat));
    exportgraphics(fig, imgName, 'Resolution', 300, 'BackgroundColor', opts.bgColor);
end