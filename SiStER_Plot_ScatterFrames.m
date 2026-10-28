function SiStER_Plot_ScatterFrames(targetDir, zVar, varargin)
% SiStER_Plot_ScatterFrames Animates and saves scatter plots of SiStER output.
%
% Usage:
%   SiStER_Plot_ScatterFrames('Wedge_default') % Will prompt for variable
%   SiStER_Plot_ScatterFrames('Wedge_default', 'Tm') 
%   SiStER_Plot_ScatterFrames('Wedge_default', 'epsIIm', 'imgFormat', 'pdf')

    % 1. Enforce required directory input
    if nargin < 1 || isempty(targetDir)
        error('A target directory must be provided. Example: SiStER_Plot_ScatterFrames(''Wedge_default'')');
    end
    if ~isfolder(targetDir)
        error('Directory "%s" does not exist.', targetDir);
    end

    % 2. Handle zVar input or Interactive prompt
    if nargin >= 2 && isnumeric(zVar)
        % If user typed SiStER_Plot_ScatterFrames('Wedge_default', 1)
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
    
    % Map numbers (either from direct input or prompt) to strings
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
        otherwise, zVar = strtrim(zVar); % Assume user typed custom name like 'epNH'
    end

    % 3. Parse optional arguments

    % 3. Parse optional arguments
    p = inputParser;
    addParameter(p, 'xVar', 'xm', @ischar);
    addParameter(p, 'yVar', 'ym', @ischar);
    addParameter(p, 'logZ', [], @(x) islogical(x) || isempty(x)); 
    addParameter(p, 'filterAir', true, @islogical);
    addParameter(p, 'markerSize', 2, @isnumeric);
    addParameter(p, 'cLimit', [], @isnumeric);      
    addParameter(p, 'pauseTime', 0.1, @isnumeric);  
    addParameter(p, 'imgFormat', 'png', @ischar); % 'png', 'jpg', or 'pdf'
    
    parse(p, varargin{:});
    opts = p.Results;
    
    % Auto-log values that span many orders of magnitude
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

    % 6. Set up the figure
    fig = figure('Name', 'SiStER Plotter', 'Color', 'w');
    
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
        
        % Filter air phase
        if opts.filterAir && isfield(data, 'im')
            mask = data.im > 1;
            X = X(mask);
            Y = Y(mask);
            Z = Z(mask);
        end
        
        % Log scale
        if opts.logZ
            Z = log10(Z);
            plotTitleVar = ['log_{10}(' strrep(zVar, '_', '\_') ')'];
        else
            plotTitleVar = strrep(zVar, '_', '\_');
        end
        
        % Plotting
        cla;
        fastscatter(X, Y, Z, 'markersize', opts.markerSize);
        
        % Title & Labels
        if isfield(data, 'time')
            timeMyrs = data.time / (365.25 * 24 * 3600 * 1e6);
            title(sprintf('%s | Time: %.2f Myrs (File: %s)', plotTitleVar, timeMyrs, fileName));
        else
            title(sprintf('%s | File: %s', plotTitleVar, fileName));
        end
        
        xlabel([strrep(opts.xVar, '_', '\_') ' (km)']);
        ylabel([strrep(opts.yVar, '_', '\_') ' (km)']);
        
        axis equal; axis tight;
        set(gca, 'YDir', 'reverse');
        colormap('parula');
        cb = colorbar;
        ylabel(cb, plotTitleVar);
        
        if ~isempty(opts.cLimit)
            clim(opts.cLimit); 
        end
        
        drawnow;
        pause(opts.pauseTime);
        
        % Save the image using exportgraphics (High Res)
        imgName = fullfile(outDir, sprintf('frame_%04d.%s', k, opts.imgFormat));
        exportgraphics(fig, imgName, 'Resolution', 300);
    end
    
    fprintf('Finished saving %d frames to %s\n', length(matFiles), outDir);
end