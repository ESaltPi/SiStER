function SiStER_FramesToVideo(imgDir, outVideoName, varargin)
% SiStER_FramesToVideo Compiles a directory of image frames into a video.
%
% Usage:
%   % 1. Interactive Batch Mode
%   SiStER_FramesToVideo('Delamination') % Will prompt for variable
%
%   % 2. Shortcut Batch Mode (Will auto-plot if missing!)
%   SiStER_FramesToVideo('Delamination', 3)       % Compiles 'Tm'
%   SiStER_FramesToVideo('Delamination', 'Tm')    % Compiles 'Tm'
%   SiStER_FramesToVideo('Delamination', 10)      % Compiles all 
%   SiStER_FramesToVideo('Delamination', 'all')   % Compiles all 
%
%   % 3. Single Folder Mode
%   SiStER_FramesToVideo('Delamination/im_plots', 'Im_Animation.mp4')
%
% NOTE: if failing on linux, you need to install required codecs:
%   sudo apt update && sudo apt install ffmpeg
%   sudo apt-get install gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav

%% 1. Interactive & Shortcut Batch Processing Mode
% Check if this is the root directory (Assume it is if it doesn't end in '_plots')
if ~endsWith(imgDir, '_plots', 'IgnoreCase', true)
    isBatch = false;
    choiceVar = '';
    passArgs = {};
    
    if nargin == 1
        isBatch = true;
    elseif nargin >= 2
        if isnumeric(outVideoName)
            isBatch = true;
            choiceVar = num2str(outVideoName);
            passArgs = varargin;
        elseif ischar(outVideoName) || isstring(outVideoName)
            if any(strcmpi(outVideoName, {'frameRate', 'imgFormat', 'videoProfile', 'quality', 'deletePlots'}))
                isBatch = true;
                passArgs = [{outVideoName}, varargin];
            else
                isBatch = true;
                choiceVar = strtrim(char(outVideoName));
                passArgs = varargin;
            end
        end
    end
    
    if isBatch
        % If no shortcut was provided, show the interactive menu
        if isempty(choiceVar)
            fprintf('\n--- Available Variables to Animate ---\n');
            fprintf('  1) epsIIm - 2nd invariant of strain rate (1/s)\n');
            fprintf('  2) etam   - Viscosity (Pa.s)\n');
            fprintf('  3) Tm     - Temperature\n');
            fprintf('  4) rhom   - Density (kg/m^3)\n');
            fprintf('  5) im     - Material Phase (rock type index)\n');
            fprintf('  6) ep     - Accumulated Plastic Strain\n');
            fprintf('  7) sxxm   - Normal Deviatoric Stress (Pa)\n');
            fprintf('  8) sxym   - Shear Deviatoric Stress (Pa)\n');
            fprintf('  9) idm    - Unique marker ID numbers\n');
            fprintf(' 10) all    - Process all currently available _plots folders\n');
            
            choiceVar = input('\nEnter a number (1-10), an exact variable name, or "all": ', 's');
        end
        
        % Map the number choices to variable strings
        switch strtrim(choiceVar)
            case '1', choiceVar = 'epsIIm';
            case '2', choiceVar = 'etam';
            case '3', choiceVar = 'Tm';
            case '4', choiceVar = 'rhom';
            case '5', choiceVar = 'im';
            case '6', choiceVar = 'ep';
            case '7', choiceVar = 'sxxm';
            case '8', choiceVar = 'sxym';
            case '9', choiceVar = 'idm';
            case '10', choiceVar = 'all';
            otherwise
                choiceVar = strtrim(choiceVar); 
                validVars = {'epsIIm', 'etam', 'Tm', 'rhom', 'im', 'ep', 'sxxm', 'sxym', 'idm', 'all'};
                % Validate that the input is actually a recognized variable
                if ~any(strcmpi(choiceVar, validVars))
                    error('Invalid variable requested: "%s". Must be a valid variable name or number (1-10).', choiceVar);
                end
                % Ensure exact casing for consistency
                matchIdx = find(strcmpi(choiceVar, validVars));
                choiceVar = validVars{matchIdx};
        end
        
        % Route the choice to the correct folders
        if strcmpi(choiceVar, 'all')
            allVars = {'epsIIm', 'etam', 'Tm', 'rhom', 'im', 'ep', 'sxxm', 'sxym', 'idm'};
            fprintf('\n======================================================\n');
            fprintf('Batch processing ALL 9 variables in: %s\n', imgDir);
            fprintf('======================================================\n');
            
            for v = 1:length(allVars)
                fprintf('\n>>> Video %d/9: %s <<<\n', v, allVars{v});
                % Recursively call this function for each variable.
                % Because we pass the specific variable name, it will 
                % automatically trigger SiStER_Plot_ScatterFrames if the images are missing!
                SiStER_FramesToVideo(imgDir, allVars{v}, passArgs{:});
            end
            fprintf('\n=== Finished batch video rendering for all variables ===\n');
            return;
            
        else
            % Single variable requested - Check if we need to auto-plot!
            expectedFolder = sprintf('%s_plots', choiceVar);
            fullFolderPath = fullfile(imgDir, expectedFolder);
            
            if ~isfolder(fullFolderPath)
                fprintf('\n>>> Folder "%s" not found. Automatically generating plots...\n', expectedFolder);
                try
                    % Call the companion plotting script
                    SiStER_Plot_ScatterFrames(imgDir, choiceVar);
                catch ME
                    error('Failed to generate plots for "%s". Error: %s', choiceVar, ME.message);
                end
            end
            
            foldersToProcess = {expectedFolder};
            prefsToProcess = {choiceVar};
        end
        
        % Process the chosen folders
        for k = 1:length(foldersToProcess)
            autoVidName = sprintf('%s_Animation.mp4', prefsToProcess{k});
            fprintf('\n======================================================\n');
            fprintf('Processing folder: %s\n', foldersToProcess{k});
            fprintf('======================================================\n');
            % Recursively call this function for the specific subfolder
            SiStER_FramesToVideo(fullfile(imgDir, foldersToProcess{k}), autoVidName, passArgs{:});
        end
        
        return; % Exit out of the main function once batch processing is done
    end
end

%% 2. Validate Inputs for Single-Folder Mode
if nargin < 2
    error('Both image directory and output video name must be provided.');
end
if ~isfolder(imgDir)
    error('Directory "%s" does not exist.', imgDir);
end

%% 3. Parse optional arguments
p = inputParser;
addParameter(p, 'frameRate', 10, @isnumeric);      
addParameter(p, 'imgFormat', 'png', @ischar);      
addParameter(p, 'videoProfile', 'Motion JPEG AVI', @ischar); 
addParameter(p, 'quality', 100, @isnumeric); 
addParameter(p, 'deletePlots', false, @islogical);
parse(p, varargin{:});
opts = p.Results;

[~, baseName, ~] = fileparts(outVideoName);
if strcmp(opts.videoProfile, 'MPEG-4')
    outVideoName = [baseName '.mp4'];
elseif strcmp(opts.videoProfile, 'Motion JPEG AVI')
    outVideoName = [baseName '.avi'];
    finalMP4Name = [baseName '.mp4'];
end

%% 4. Gather and sort image files
filePattern = fullfile(imgDir, sprintf('*.%s', opts.imgFormat));
imgFiles = dir(filePattern);
if isempty(imgFiles)
    error('No %s files found in %s', opts.imgFormat, imgDir);
end

[~, sortIdx] = sort({imgFiles.name});
imgFiles = imgFiles(sortIdx);
numFrames = length(imgFiles);

%% 5. Initialize VideoWriter
vidPath = fullfile(imgDir, outVideoName);
v = VideoWriter(vidPath, opts.videoProfile);
v.FrameRate = opts.frameRate;
if strcmp(opts.videoProfile, 'MPEG-4') || strcmp(opts.videoProfile, 'Motion JPEG AVI')
    v.Quality = opts.quality;
end
open(v);
fprintf('Found %d frames. Compiling video to %s at %d FPS...\n', numFrames, vidPath, opts.frameRate);

%% 6. Read frames and write to video (With Auto-Resize Fix)
firstImg = imread(fullfile(imgDir, imgFiles(1).name));
[targetH, targetW, ~] = size(firstImg);

for i = 1:numFrames
    imgPath = fullfile(imgDir, imgFiles(i).name);
    try
        img = imread(imgPath);
        
        if size(img, 1) ~= targetH || size(img, 2) ~= targetW
            img = imresize(img, [targetH, targetW]);
        end
        
        writeVideo(v, img);
    catch ME
        warning('Failed to read or write frame %s: %s', imgFiles(i).name, ME.message);
    end
    
    if mod(i, 50) == 0 || i == numFrames
        fprintf('Processed %d/%d frames...\n', i, numFrames);
    end
end

close(v);
fprintf('Success! Video saved to: %s\n', vidPath);

%% 7. Convert to MP4 via FFmpeg (With Divisible-by-2 Fix)
success = true;
if strcmp(opts.videoProfile, 'Motion JPEG AVI')
    finalMP4Path = fullfile(imgDir, finalMP4Name);
    fprintf('Converting %s to MP4 via FFmpeg...\n', outVideoName);
    
    ffmpeg_cmd = sprintf('ffmpeg -hide_banner -loglevel error -y -i "%s" -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -crf 23 -preset fast "%s"', vidPath, finalMP4Path);
    status = system(ffmpeg_cmd);
    
    if status == 0
        fprintf('MP4 conversion successful! File saved as: %s\n', finalMP4Path);
        delete(vidPath); % Clean up the temporary AVI
    else
        success = false;
        warning('FFmpeg conversion failed. Check if FFmpeg is installed via: sudo apt install ffmpeg');
        fprintf('Your video is still available as an AVI at: %s\n', vidPath);
    end
end

%% 8. Cleanup Option
if success && opts.deletePlots
    % Move the MP4 up one directory so it isn't deleted
    [parentDir, currentFolder, ~] = fileparts(imgDir);
    targetMP4Path = fullfile(parentDir, finalMP4Name);
    
    fprintf('Moving MP4 to parent directory: %s\n', targetMP4Path);
    movefile(finalMP4Path, targetMP4Path);
    
    fprintf('Deleting image folder: %s\n', imgDir);
    rmdir(imgDir, 's'); 
end

end