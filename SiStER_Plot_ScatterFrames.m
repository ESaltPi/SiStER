function SiStER_Plot_ScatterFrames(targetDir, zVar, varargin)
% SiStER_Plot_ScatterFrames Animates and saves scatter plots of SiStER output.
%
% Usage:
%   SiStER_Plot_ScatterFrames('Wedge_default') % Will prompt for variable
%   SiStER_Plot_ScatterFrames('Wedge_default', 'Tm', 'markerSize', 15, 'figWidth', 1200) 
%   SiStER_Plot_ScatterFrames('Wedge_default', 'Tm', 'markerSize', 20, 'figWidth', 1920, 'figHeight', 1080)

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
    addParameter(p, 'markerSize', 10, @isnumeric);   % Increased default marker size
    addParameter(p, 'figWidth', 1000, @isnumeric);   % Default figure width in pixels
    addParameter(p, 'figHeight', 600, @isnumeric);   % Default figure height in pixels
    addParameter(p, 'cLimit', [], @isnumeric);      
    addParameter(p, 'pauseTime', 0.1, @isnumeric);  
    addParameter(p, 'imgFormat', 'png', @ischar); 
    
    parse(p, varargin{:});
    opts = p.Results;
    
    if isempty(opts.logZ)
        opts.logZ = any(strcmp(zVar, {'epsIIm', 'etam'}));
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
    
    % 5. Create the output image directory
    outDir = fullfile(targetDir, sprintf('%s_plots', zVar));
    if ~isfolder(outDir)
        mkdir(outDir);
    end
    fprintf('Plots will be saved as .%s in: %s\n', opts.imgFormat, outDir);
    
    % 6. Set up the figure with FIXED DIMENSIONS
    fig = figure('Name', 'SiStER Plotter', 'Color', 'w', ...
                 'Position', [100, 100, opts.figWidth, opts.figHeight]);
    
    varsToLoad = unique({opts.xVar, opts.yVar, zVar, 'time', 'im'}); 
    
    % 7. Loop through and plot/save
    for k = 1:length(matFiles)
        fileName = matFiles(k).name;
        fullPath = fullfile(targetDir, fileName);

        try
            data = load(fullPath, varsToLoad{:});
        catch
            warning('Could not load %s. Skipping.', fileName);
            continue;
        end

        if ~isfield(data, opts.xVar) || ~isfield(data, opts.yVar) || ~isfield(data, zVar)
            warning('Required variables not found in %s. Skipping.', fileName);
            continue;
        end

        X = data.(opts.xVar);
        Y = data.(opts.yVar);
        Z = data.(zVar);

        if strcmp(opts.xVar, 'xm'), X = X / 1e3; end
        if strcmp(opts.yVar, 'ym'), Y = Y / 1e3; end

        if opts.filterAir && isfield(data, 'im')
            mask = data.im > 1;
            X = X(mask);
            Y = Y(mask);
            Z = Z(mask);
        end

        if opts.logZ
            Z = log10(Z);
            plotTitleVar = ['log_{10}(' strrep(zVar, '_', '\_') ')'];
        else
            plotTitleVar = strrep(zVar, '_', '\_');
        end

        cla;
        fastscatter(X, Y, Z, 'markersize', opts.markerSize);

        % --- UPDATE 1: Age to an extra decimal place (%.3f) & Lock Font Sizes ---
        if isfield(data, 'time')
            timeMyrs = data.time / (365.25 * 24 * 3600 * 1e6);
            title(sprintf('%s | Time: %.3f Myrs (File: %s)', plotTitleVar, timeMyrs, fileName), 'FontSize', 14);
        else
            title(sprintf('%s | File: %s', plotTitleVar, fileName), 'FontSize', 14);
        end

        xlabel([strrep(opts.xVar, '_', '\_') ' (km)'], 'FontSize', 12);
        ylabel([strrep(opts.yVar, '_', '\_') ' (km)'], 'FontSize', 12);

        % --- UPDATE 2: Lock Data Limits ---
        axis equal; 
        if k == 1
            axis tight;
            % Capture the exact coordinate limits from the first frame
            xLims = xlim;
            yLims = ylim;
        else
            % Force all subsequent frames to use the first frame's limits
            xlim(xLims);
            ylim(yLims);
        end

        set(gca, 'YDir', 'reverse', 'FontSize', 12);
        colormap('parula');
        cb = colorbar;
        ylabel(cb, plotTitleVar, 'FontSize', 12);

        if ~isempty(opts.cLimit)
            clim(opts.cLimit); 
        end

        % --- UPDATE 3: Lock Axes and Colorbar Dimensions ---
        if k == 1
            % Capture the physical layout dimensions after the first frame renders
            drawnow; 
            axPos = get(gca, 'Position');
            cbPos = get(cb, 'Position');
        else
            % Force the layout box to stay exactly the same
            set(gca, 'Position', axPos);
            set(cb, 'Position', cbPos);
        end

        drawnow;
        pause(opts.pauseTime);

        imgName = fullfile(outDir, sprintf('frame_%04d.%s', k, opts.imgFormat));
        exportgraphics(fig, imgName, 'Resolution', 300);
    end
    
    fprintf('Finished saving %d frames to %s\n', length(matFiles), outDir);
end