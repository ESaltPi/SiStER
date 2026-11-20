function SiStER_Plot_Grid(target, varargin)
% SiStER_Plot_Grid Plots and saves the Eulerian grid spacing and 2D cell layout.
% Creates the target folder if it does not exist, locates/copies the matching
% input file, and saves the grid plot inside that folder without opening a window.
%
% Usage:
%   SiStER_Plot_Grid('otf6')  % Creates 'otf6/' if needed, finds matching input file, saves otf6/grid_layout.png
%   SiStER_Plot_Grid('otf6', 'zoomx', [40 60], 'zoomy', [0 15])
%   SiStER_Plot_Grid('SiStER_Input_File_OTF6')  % Uses quickPlot folder if defined in input file, else current dir
%   SiStER_Plot_Grid()        % Prompts to select an input file

% 1. Parse optional arguments
p = inputParser;
addParameter(p, 'zoomx', [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 2 && x(1) < x(2)));
addParameter(p, 'zoomy', [], @(x) isempty(x) || (isnumeric(x) && numel(x) == 2 && x(1) < x(2)));
addParameter(p, 'showStructure', true, @islogical);
addParameter(p, 'showFigure', false, @islogical);
addParameter(p, 'figWidth', 1100, @isnumeric);
addParameter(p, 'figHeight', 700, @isnumeric);
addParameter(p, 'imgFormat', 'png', @ischar);
parse(p, varargin{:});
opts = p.Results;

% 2. Resolve target (folder name, input file name, or menu number)
outDir = '';
inpFilePath = '';
InpFil = '';

if nargin < 1 || isempty(target)
    InpFil = SiStER_Input('');
    inpFilePath = [InpFil '.m'];
else
    if isnumeric(target)
        target = num2str(target);
    end
    target = strtrim(char(target));

    % Case A: Target is already an existing folder
    if isfolder(target)
        outDir = target;
        inpFiles = dir(fullfile(outDir, 'SiStER_Input_*.m'));
        if isempty(inpFiles)
            inpFiles = dir(fullfile(outDir, '*.m'));
        end

        if ~isempty(inpFiles)
            inpFilePath = fullfile(outDir, inpFiles(1).name);
            [~, InpFil, ~] = fileparts(inpFiles(1).name);
        else
            % Check .mat files inside outDir for saved InpFil
            matFiles = dir(fullfile(outDir, '*.mat'));
            if ~isempty(matFiles)
                info = whos('-file', fullfile(outDir, matFiles(1).name));
                if ismember('InpFil', {info.name})
                    tmp = load(fullfile(outDir, matFiles(1).name), 'InpFil');
                    InpFil = tmp.InpFil;
                    inpFilePath = [InpFil '.m'];
                end
            end
        end

    % Case B: Target is a direct .m file or menu number
    elseif endsWith(target, '.m') || exist([target '.m'], 'file') == 2 || ~isnan(str2double(target))
        InpFil = SiStER_Input(target);
        inpFilePath = [InpFil '.m'];

    % Case C: Target is a folder name (e.g., 'otf6') that does not exist yet
    else
        outDir = target;
    end
end

% If we have an outDir (existing or new) but haven't found the input file yet,
% search root SiStER_Input_*.m files by quickPlot value or filename match
if isempty(inpFilePath) && ~isempty(outDir)
    candFiles = dir('SiStER_Input_*.m');
    matchedFile = '';

    % 1) Match by quickPlot variable defined inside the input file
    for k = 1:length(candFiles)
        qpVal = readQuickPlotVar(candFiles(k).name);
        if ~isempty(qpVal) && strcmpi(strtrim(qpVal), outDir)
            matchedFile = candFiles(k).name;
            break;
        end
    end

    % 2) Fallback: match by input filename suffix (e.g., 'otf6' -> 'SiStER_Input_File_OTF6.m')
    if isempty(matchedFile)
        for k = 1:length(candFiles)
            if endsWith(erase(candFiles(k).name, '.m'), outDir, 'IgnoreCase', true)
                matchedFile = candFiles(k).name;
                break;
            end
        end
    end

    if ~isempty(matchedFile)
        inpFilePath = matchedFile;
        [~, InpFil, ~] = fileparts(matchedFile);
    else
        fprintf('Could not auto-match an input file for folder "%s". Select one:\n', outDir);
        InpFil = SiStER_Input('');
        inpFilePath = [InpFil '.m'];
    end
end

if exist(inpFilePath, 'file') ~= 2
    error('Could not find input file: %s', inpFilePath);
end

% 3. Load domain & GRID parameters cleanly via helper function
[xsize, ysize, GRID, PARAMS, quickPlotVal] = loadInputParams(inpFilePath);

if isempty(xsize) || isempty(ysize) || isempty(GRID)
    error('Input file "%s" must define xsize, ysize, and GRID.', inpFilePath);
end

% If outDir wasn't explicitly passed (user passed input file name), use quickPlot if defined
if isempty(outDir)
    if ~isempty(quickPlotVal)
        outDir = strtrim(char(quickPlotVal));
    else
        outDir = '.';
    end
end

% 4. Create target folder if needed & ensure input file is copied into it
if ~strcmp(outDir, '.') && ~isfolder(outDir)
    [status, msg] = mkdir(outDir);
    if ~status
        error('Failed to create directory "%s". Reason: %s', outDir, msg);
    end
    fprintf('Created folder: %s\n', outDir);
end

if ~strcmp(outDir, '.')
    [~, baseName, ext] = fileparts(inpFilePath);
    destInpPath = fullfile(outDir, [baseName ext]);
    if exist(destInpPath, 'file') ~= 2
        copyfile(inpFilePath, destInpPath);
        fprintf('Copied input file ''%s'' to ''%s''.\n', [baseName ext], outDir);
    end
end

% Construct staggered grid coordinates
[X, Y, x, y, ~, ~, dx, dy, Nx, Ny] = SiStER_initialize_grid(xsize, ysize, GRID);

% 5. Create Figure (hidden by default)
if opts.showFigure
    vis = 'on';
else
    vis = 'off';
end

titleLabel = strrep(InpFil, '_', '\_');
fig = figure('Visible', vis, 'Position', [100, 100, opts.figWidth, opts.figHeight], 'Color', 'w');

% --- Top-Left: Horizontal Cell Width dx(x) ---
subplot(2, 2, 1);
stairs(x(1:end-1)/1e3, dx, 'LineWidth', 2, 'Color', [0.1 0.45 0.8]);
xlabel('Horizontal Distance x (km)', 'FontSize', 11);
ylabel('Cell Width \Delta x (m)', 'FontSize', 11);
title(sprintf('Horizontal Resolution (%d cells, Nx = %d)', Nx-1, Nx), 'FontSize', 12);
if ~isempty(opts.zoomx), xlim(opts.zoomx); else, xlim([0, xsize/1e3]); end
ylim([0, max(dx)*1.15]);
grid on;

% --- Top-Right: Vertical Cell Height dy(y) ---
subplot(2, 2, 2);
stairs(dy, y(1:end-1)/1e3, 'LineWidth', 2, 'Color', [0.85 0.3 0.1]);
set(gca, 'YDir', 'reverse');
xlabel('Cell Height \Delta y (m)', 'FontSize', 11);
ylabel('Depth y (km)', 'FontSize', 11);
title(sprintf('Vertical Resolution (%d cells, Ny = %d)', Ny-1, Ny), 'FontSize', 12);
xlim([0, max(dy)*1.15]);
if ~isempty(opts.zoomy), ylim(opts.zoomy); else, ylim([0, ysize/1e3]); end
grid on;

% --- Bottom: 2D Eulerian Grid Mesh ---
subplot(2, 2, [3, 4]);
hold on;

plot(X/1e3, Y/1e3, 'Color', [0.25 0.25 0.25], 'LineWidth', 0.4);
plot(X'/1e3, Y'/1e3, 'Color', [0.25 0.25 0.25], 'LineWidth', 0.4);

% Optionally overlay bathymetry/topography & Moho if present in PARAMS
legendHandles = [];
legendLabels = {};
if opts.showStructure && ~isempty(PARAMS)
    if isfield(PARAMS, 'x_data') && isfield(PARAMS, 'y_data')
        hTopo = plot(PARAMS.x_data/1e3, PARAMS.y_data/1e3, 'b-', 'LineWidth', 1.8);
        legendHandles(end+1) = hTopo;
        legendLabels{end+1} = 'Seafloor / Topography';
    end
    if isfield(PARAMS, 'moho_depth')
        hMoho = yline(PARAMS.moho_depth/1e3, 'r--', 'LineWidth', 1.5);
        legendHandles(end+1) = hMoho;
        legendLabels{end+1} = sprintf('Moho (%.1f km)', PARAMS.moho_depth/1e3);
    end
end

set(gca, 'YDir', 'reverse', 'FontSize', 11);
axis equal;
if ~isempty(opts.zoomx), xlim(opts.zoomx); else, xlim([0, xsize/1e3]); end
if ~isempty(opts.zoomy), ylim(opts.zoomy); else, ylim([0, ysize/1e3]); end
box on;

xlabel('Horizontal Distance x (km)', 'FontSize', 11);
ylabel('Depth y (km)', 'FontSize', 11);
title(sprintf('2D Eulerian Cell Mesh: %s (min \\Delta x = %g m, min \\Delta y = %g m)', ...
      titleLabel, min(dx), min(dy)), 'FontSize', 12);

if ~isempty(legendHandles)
    legend(legendHandles, legendLabels, 'Location', 'southeast');
end

% 6. Save directly to the target folder and close figure if hidden
fileName = 'grid_layout';
if ~isempty(opts.zoomx) || ~isempty(opts.zoomy)
    fileName = [fileName '_zoom'];
    if ~isempty(opts.zoomx)
        fileName = sprintf('%s_x%gto%g', fileName, opts.zoomx(1), opts.zoomx(2));
    end
    if ~isempty(opts.zoomy)
        fileName = sprintf('%s_y%gto%g', fileName, opts.zoomy(1), opts.zoomy(2));
    end
end

outPath = fullfile(outDir, sprintf('%s.%s', fileName, opts.imgFormat));
exportgraphics(fig, outPath, 'Resolution', 300, 'BackgroundColor', 'w');
fprintf('Saved grid layout plot to: %s\n', outPath);

if ~opts.showFigure
    close(fig);
end

end

% =========================================================================
% LOCAL HELPER: Safely evaluate input script in an isolated workspace
% =========================================================================
function [xsize, ysize, GRID, PARAMS, quickPlotVal] = loadInputParams(inpFilePath)
    xsize = [];
    ysize = [];
    GRID = [];
    PARAMS = [];
    quickPlot = '';
    run(inpFilePath);
    quickPlotVal = quickPlot;
end

% =========================================================================
% LOCAL HELPER: Quickly check quickPlot inside an input file without full run
% =========================================================================
function qp = readQuickPlotVar(filePath)
    qp = '';
    try
        [~, ~, ~, ~, qp] = loadInputParams(filePath);
    catch
    end
end