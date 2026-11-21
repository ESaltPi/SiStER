function SiStER_Plot_ScatterFrames(targetDir, zVar, varargin)
% SiStER_Plot_ScatterFrames Animates and saves scatter plots of SiStER output.
%
% Usage:
%   SiStER_Plot_ScatterFrames('Wedge_default') % Will prompt for variable
%   SiStER_Plot_ScatterFrames('Wedge_default', 'all') % Plots all 9 variables
%   SiStER_Plot_ScatterFrames('Wedge_default', 10)    % Plots all 9 variables
%   SiStER_Plot_ScatterFrames('Wedge_default', 'Tm', 'markerSize', 15, 'dpi', 150)
%   SiStER_Plot_ScatterFrames('OTF6', 'sxxm', 'zoomx', [40 60], 'zoomy', [0 12], 'plotTopo', true)

% Turn off warning
warning('off', 'MATLAB:ui:figure:ScrollableAccessibilityTextSize')

    % 1. Enforce required directory input
    if nargin < 1 || isempty(targetDir)
        error('A target directory must be provided. Example: SiStER_Plot_ScatterFrames(''Wedge_default'')');
    end
    if ~isfolder(targetDir)
        error('Directory "%s" does not exist.', targetDir);
    end
    
    % 2. Handle zVar input or Interactive prompt
    if nargin >= 2 && ischar(zVar) && contains(zVar, {'filterAir','xVar','yVar','markerSize','figWidth','figHeight','cLimit','imgFormat','showFigure','useParallel','closePool','maxWorkers','colormap','bgColor','logZ','zoomx','zoomy','grid','plotTopo','topoColor','topoWidth','dpi','deduplicate'})
        varargin = [{zVar}, varargin];
        zVar = [];
    end

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
            if ~any(strcmpi(zVar, validVars))
                error('Invalid variable requested: "%s". Must be a valid variable name or number (1-10).', zVar);
            end
            matchIdx = find(strcmpi(zVar, validVars));
            zVar = validVars{matchIdx};
    end
    
    % === BATCH PROCESSING LOGIC FOR "ALL" ===
    if strcmp(zVar, 'all')
        pBatch = inputParser;
        pBatch.KeepUnmatched = true;
        addParameter(pBatch, 'useParallel', true, @islogical);
        addParameter(pBatch, 'closePool', true, @islogical);
        parse(pBatch, varargin{:});
        
        if pBatch.Results.useParallel && pBatch.Results.closePool
            batchPoolCleanup = onCleanup(@() delete(gcp('nocreate')));
        end
        
        allVars = {'epsIIm', 'etam', 'Tm', 'rhom', 'im', 'ep', 'sxxm', 'sxym', 'idm'};
        fprintf('\n======================================================\n');
        fprintf('Batch plotting ALL 9 variables in: %s\n', targetDir);
        fprintf('======================================================\n');
        
        for v = 1:length(allVars)
            fprintf('\n>>> Plotting variable %d/9: %s <<<\n', v, allVars{v});
            SiStER_Plot_ScatterFrames(targetDir, allVars{v}, varargin{:}, 'closePool', false);
        end
        fprintf('\n=== Finished batch plotting all variables ===\n');
        return;
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
    addParameter(p, 'dpi', 300, @isnumeric);
    addParameter(p, 'deduplicate', true, @islogical);
    addParameter(p, 'showFigure', false, @islogical); 
    addParameter(p, 'useParallel', true, @islogical); 
    addParameter(p, 'closePool', true, @islogical);
    addParameter(p, 'maxWorkers', 8, @isnumeric);
    addParameter(p, 'colormap', 'parula'); 
    addParameter(p, 'bgColor', 'w');
    addParameter(p, 'zoomx', [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 2 && x(1) < x(2)));
    addParameter(p, 'zoomy', [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 2 && x(1) < x(2)));
    addParameter(p, 'grid', false, @islogical);
    addParameter(p, 'plotTopo', false, @islogical);
    addParameter(p, 'topoColor', []);
    addParameter(p, 'topoWidth', 1.5, @isnumeric);
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
    
    % 5. Create the output image directory (append zoom suffix to prevent overwriting)
    folderName = sprintf('%s_plots', zVar);
    if ~isempty(opts.zoomx) || ~isempty(opts.zoomy)
        folderName = [folderName '_zoom'];
        if ~isempty(opts.zoomx)
            folderName = sprintf('%s_x%gto%g', folderName, opts.zoomx(1), opts.zoomx(2));
        end
        if ~isempty(opts.zoomy)
            folderName = sprintf('%s_y%gto%g', folderName, opts.zoomy(1), opts.zoomy(2));
        end
    end
    
    outDir = fullfile(targetDir, folderName);
    if ~isfolder(outDir)
        mkdir(outDir);
    end
    fprintf('Plots will be saved as .%s (%d DPI) in: %s\n', opts.imgFormat, opts.dpi, outDir);
    
    if opts.plotTopo
        varsToLoad = unique({opts.xVar, opts.yVar, zVar, 'time', 'im', 'topo_x', 'topo_y'});
    else
        varsToLoad = unique({opts.xVar, opts.yVar, zVar, 'time', 'im'});
    end
    
    % Start capped parallel pool so exportgraphics never hits OpenGL/compositor contention
    if opts.useParallel
        pool = gcp('nocreate');
        if isempty(pool)
            targetWorkers = min([numFiles, opts.maxWorkers]);
            if targetWorkers > 1
                parpool('Processes', targetWorkers);
            end
        end
        if opts.closePool
            poolCleanup = onCleanup(@() delete(gcp('nocreate')));
        end
    end
    
    % 6. SINGLE-PASS LOAD & LIMIT SCAN: Load each .mat file once and cache trimmed arrays
    fprintf('Loading %d files (single pass)...\n', numFiles);
    frames(numFiles) = struct('X', [], 'Y', [], 'Z', [], 'time', NaN, 'hasTime', false, ...
                              'topo_x', [], 'topo_y', [], 'fileName', '', 'valid', false);
    
    xMinArr = inf(numFiles, 1); xMaxArr = -inf(numFiles, 1);
    yMinArr = inf(numFiles, 1); yMaxArr = -inf(numFiles, 1);
    zMinArr = inf(numFiles, 1); zMaxArr = -inf(numFiles, 1);
    
    % Pre-compute spatial crop box (with small padding if zoomed)
    hasZoomX = ~isempty(opts.zoomx);
    hasZoomY = ~isempty(opts.zoomy);
    if hasZoomX
        xPad = 0.02 * (opts.zoomx(2) - opts.zoomx(1));
        xCrop = [opts.zoomx(1) - xPad, opts.zoomx(2) + xPad];
    else
        xCrop = [-inf, inf];
    end
    if hasZoomY
        yPad = 0.02 * (opts.zoomy(2) - opts.zoomy(1));
        yCrop = [opts.zoomy(1) - yPad, opts.zoomy(2) + yPad];
    else
        yCrop = [-inf, inf];
    end
    
    if opts.useParallel
        parfor k = 1:numFiles
            [frames(k), xMinArr(k), xMaxArr(k), yMinArr(k), yMaxArr(k), zMinArr(k), zMaxArr(k)] = ...
                loadSingleFrame(targetDir, matFiles(k).name, varsToLoad, opts, zVar, hasZoomX, hasZoomY, xCrop, yCrop);
        end
    else
        for k = 1:numFiles
            [frames(k), xMinArr(k), xMaxArr(k), yMinArr(k), yMaxArr(k), zMinArr(k), zMaxArr(k)] = ...
                loadSingleFrame(targetDir, matFiles(k).name, varsToLoad, opts, zVar, hasZoomX, hasZoomY, xCrop, yCrop);
        end
    end
    
    xMin = min(xMinArr); xMax = max(xMaxArr);
    yMin = min(yMinArr); yMax = max(yMaxArr);
    zMin = min(zMinArr); zMax = max(zMaxArr);
    
    if hasZoomX, xLims = opts.zoomx; else, xLims = [xMin, xMax]; end
    if hasZoomY, yLims = opts.zoomy; else, yLims = [yMin, yMax]; end
    if ~isempty(opts.cLimit), cLims = opts.cLimit; else, cLims = [zMin, zMax]; end
    
    % --- Fix for uniform variables or flat spatial dimensions ---
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
    % ------------------------------------------------------------
    
    % 7. SUB-PIXEL MARKER DEDUPLICATION (in-memory, before rendering)
    if opts.deduplicate
        % Map directly to 1x figure pixel grid so markers fill every pixel without exceeding WebGL caps
        nPixX = max(200, round(opts.figWidth));
        nPixY = max(200, round(opts.figHeight));
        
        % Keep total grid cells under ~600k to prevent SwiftShader WebGL export crashes
        maxCells = 600000;
        if (nPixX * nPixY) > maxCells
            scale = sqrt(maxCells / (nPixX * nPixY));
            nPixX = max(200, round(nPixX * scale));
            nPixY = max(200, round(nPixY * scale));
        end
        
        dxPix = (xLims(2) - xLims(1)) / nPixX;
        dyPix = (yLims(2) - yLims(1)) / nPixY;
        
        rawCount = 0;
        keptCount = 0;
        for k = 1:numFiles
            if ~frames(k).valid || isempty(frames(k).X), continue; end
            rawCount = rawCount + numel(frames(k).X);
            
            ix = floor((frames(k).X - xLims(1)) / dxPix);
            iy = floor((frames(k).Y - yLims(1)) / dyPix);
            % Combine 2D sub-pixel bin into a single integer key
            pixKey = int64(ix) * int64(nPixY + 10) + int64(iy);
            [~, keepIdx] = unique(pixKey, 'last');
            keepIdx = sort(keepIdx); % Preserve original painter's order
            
            frames(k).X = frames(k).X(keepIdx);
            frames(k).Y = frames(k).Y(keepIdx);
            frames(k).Z = frames(k).Z(keepIdx);
            keptCount = keptCount + numel(keepIdx);
        end
        if rawCount > 0
            fprintf('Deduplicated markers at sub-pixel resolution: %d -> %d (%.1f%% reduction).\n', ...
                    round(rawCount/numFiles), round(keptCount/numFiles), 100*(1 - keptCount/rawCount));
        end
    end
    
    fprintf('Limits locked (X: [%.2f, %.2f] km, Y: [%.2f, %.2f] km). Rendering...\n', xLims(1), xLims(2), yLims(1), yLims(2));
    
    % 8. PLOTTING LOOP (Parallel vs Sequential with reusable graphics handles)
    if opts.useParallel
        parfor k = 1:numFiles
            if ~frames(k).valid, continue; end
            fig = figure('Visible', 'off', 'Position', [100, 100, opts.figWidth, opts.figHeight], 'Color', opts.bgColor);
            [hScat, hTopo, hTitle] = initFrameGraphics(fig, frames(k), opts, zVar, plotTitleVar, xLims, yLims, cLims);
            updateAndExportFrame(fig, hScat, hTopo, hTitle, frames(k), opts, plotTitleVar, outDir, k);
            close(fig);
        end
    else
        if opts.showFigure, vis = 'on'; else, vis = 'off'; end
        fig = figure('Visible', vis, 'Position', [100, 100, opts.figWidth, opts.figHeight], 'Color', opts.bgColor);
        
        firstValid = find([frames.valid], 1, 'first');
        if ~isempty(firstValid)
            [hScat, hTopo, hTitle] = initFrameGraphics(fig, frames(firstValid), opts, zVar, plotTitleVar, xLims, yLims, cLims);
            for k = 1:numFiles
                if ~frames(k).valid, continue; end
                updateAndExportFrame(fig, hScat, hTopo, hTitle, frames(k), opts, plotTitleVar, outDir, k);
            end
        end
        close(fig);
    end
    
    fprintf('Finished saving %d frames to %s\n', numFiles, outDir);
end

% =========================================================================
% LOCAL HELPER 1: Single-pass .mat load, crop, and limit extraction
% =========================================================================
function [fData, xMin, xMax, yMin, yMax, zMin, zMax] = loadSingleFrame(targetDir, fileName, varsToLoad, opts, zVar, hasZoomX, hasZoomY, xCrop, yCrop)
    fData = struct('X', [], 'Y', [], 'Z', [], 'time', NaN, 'hasTime', false, ...
                   'topo_x', [], 'topo_y', [], 'fileName', fileName, 'valid', false);
    xMin = inf; xMax = -inf; yMin = inf; yMax = -inf; zMin = inf; zMax = -inf;
    
    fullPath = fullfile(targetDir, fileName);
    try
        data = load(fullPath, varsToLoad{:});
    catch
        warning('Could not load %s. Skipping.', fileName);
        return;
    end
    
    if ~isfield(data, opts.xVar) || ~isfield(data, opts.yVar) || ~isfield(data, zVar)
        return;
    end
    
    X = data.(opts.xVar)(:);
    Y = data.(opts.yVar)(:);
    Z = data.(zVar)(:);
    if strcmp(opts.xVar, 'xm'), X = X / 1e3; end
    if strcmp(opts.yVar, 'ym'), Y = Y / 1e3; end
    
    mask = true(size(X));
    if opts.filterAir && isfield(data, 'im')
        mask = mask & (data.im(:) > 1);
    end
    
    % Spatial crop mask
    if hasZoomX
        mask = mask & (X >= xCrop(1)) & (X <= xCrop(2));
    end
    if hasZoomY
        mask = mask & (Y >= yCrop(1)) & (Y <= yCrop(2));
    end
    
    X = X(mask); Y = Y(mask); Z = Z(mask);
    if opts.logZ, Z = log10(Z); end
    
    % Compute limits using strictly the unpadded zoom window if zoomed
    if ~isempty(X)
        limMask = true(size(X));
        if hasZoomX
            limMask = limMask & (X >= opts.zoomx(1)) & (X <= opts.zoomx(2));
        end
        if hasZoomY
            limMask = limMask & (Y >= opts.zoomy(1)) & (Y <= opts.zoomy(2));
        end
        if any(limMask)
            xMin = min(X(limMask)); xMax = max(X(limMask));
            yMin = min(Y(limMask)); yMax = max(Y(limMask));
            zMin = min(Z(limMask)); zMax = max(Z(limMask));
        end
    end
    
    fData.X = X;
    fData.Y = Y;
    fData.Z = Z;
    if isfield(data, 'time')
        fData.time = data.time;
        fData.hasTime = true;
    end
    if opts.plotTopo && isfield(data, 'topo_x') && isfield(data, 'topo_y')
        fData.topo_x = data.topo_x / 1e3;
        fData.topo_y = data.topo_y / 1e3;
    end
    fData.valid = true;
end

% =========================================================================
% LOCAL HELPER 2: Initialize persistent axes, scatter, topo, and colorbar
% =========================================================================
function [hScat, hTopo, hTitle] = initFrameGraphics(fig, fData, opts, zVar, plotTitleVar, xLims, yLims, cLims)
    if isequal(opts.bgColor, 'k') || isequal(opts.bgColor, [0 0 0]) || isequal(opts.bgColor, 'black')
        txtColor = 'w';
    else
        txtColor = 'k';
    end
    
    figure(fig);
    clf(fig);
    ax = axes(fig);
    hScat = scatter(ax, fData.X, fData.Y, opts.markerSize, fData.Z, 'filled');
    
    hTopo = [];
    if opts.plotTopo
        if isempty(opts.topoColor)
            tColor = txtColor;
        else
            tColor = opts.topoColor;
        end
        hold(ax, 'on');
        hTopo = plot(ax, NaN, NaN, '-', 'Color', tColor, 'LineWidth', opts.topoWidth);
        hold(ax, 'off');
    end
    
    hTitle = title(ax, '', 'FontSize', 14, 'Color', txtColor);
    xlabel(ax, [strrep(opts.xVar, '_', '\_') ' (km)'], 'FontSize', 12, 'Color', txtColor);
    ylabel(ax, [strrep(opts.yVar, '_', '\_') ' (km)'], 'FontSize', 12, 'Color', txtColor);
    
    axis(ax, 'equal');
    xlim(ax, xLims);
    ylim(ax, yLims);
    box(ax, 'on');
    set(ax, 'YDir', 'reverse', 'FontSize', 12, 'Color', opts.bgColor, ...
        'XColor', txtColor, 'YColor', txtColor, ...
        'Clipping', 'on', 'ClippingStyle', 'rectangle');
    
    if opts.grid
        grid(ax, 'on');
        set(ax, 'Layer', 'top');
    else
        grid(ax, 'off');
    end
    
    if strcmp(zVar, 'im')
        minP = round(cLims(1));
        maxP = round(cLims(2));
        numP = max(1, maxP - minP + 1);
        
        baseCmap = feval(opts.colormap, numP);
        colormap(ax, baseCmap);
        clim(ax, [minP - 0.5, maxP + 0.5]);
        
        cb = colorbar(ax, 'Color', txtColor);
        cb.Ticks = minP:maxP;
    else
        colormap(ax, opts.colormap);
        cb = colorbar(ax, 'Color', txtColor);
        clim(ax, cLims);
    end
    ylabel(cb, plotTitleVar, 'FontSize', 12, 'Color', txtColor);
end

% =========================================================================
% LOCAL HELPER 3: Update data handles in-place and export cropped frame
% =========================================================================
function updateAndExportFrame(fig, hScat, hTopo, hTitle, fData, opts, plotTitleVar, outDir, k)
    set(hScat, 'XData', fData.X, 'YData', fData.Y, 'CData', fData.Z);
    
    if ~isempty(hTopo)
        if ~isempty(fData.topo_x)
            set(hTopo, 'XData', fData.topo_x, 'YData', fData.topo_y);
        else
            set(hTopo, 'XData', NaN, 'YData', NaN);
        end
    end
    
    if fData.hasTime
        secPerYr = 365.25 * 24 * 3600;
        timeYrs = fData.time / secPerYr;
        
        if timeYrs < 1e3
            set(hTitle, 'String', sprintf('%s | Time: %.2f yrs (File: %s)', plotTitleVar, timeYrs, fData.fileName));
        elseif timeYrs < 1e5
            timeKyrs = timeYrs / 1e3;
            set(hTitle, 'String', sprintf('%s | Time: %.4f kyrs (File: %s)', plotTitleVar, timeKyrs, fData.fileName));
        else
            timeMyrs = timeYrs / 1e6;
            set(hTitle, 'String', sprintf('%s | Time: %.4f Myrs (File: %s)', plotTitleVar, timeMyrs, fData.fileName));
        end
    else
        set(hTitle, 'String', sprintf('%s | File: %s', plotTitleVar, fData.fileName));
    end
    
    drawnow limitrate;
    if ~isfolder(outDir)
        mkdir(outDir);
    end
    imgName = fullfile(outDir, sprintf('frame_%04d.%s', k, opts.imgFormat));
    try
        exportgraphics(fig, imgName, 'Resolution', opts.dpi, 'BackgroundColor', opts.bgColor);
    catch
        pause(0.2);
        try
            exportgraphics(fig, imgName, 'Resolution', opts.dpi, 'BackgroundColor', opts.bgColor);
        catch
            set(fig, 'PaperPositionMode', 'auto', 'InvertHardcopy', 'off');
            print(fig, imgName, '-dpng', sprintf('-r%d', opts.dpi));
        end
    end
end