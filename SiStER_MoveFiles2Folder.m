function varargout = SiStER_MoveFiles2Folder(folderName)
% MOVE_MAT_FILES Moves all .mat files in current directory to target folder.
%
% Usage:
%   move_mat_files('my_output_folder')
%   [successes, failures] = move_mat_files() % Prompts user if no input given

% 1. Handle missing or empty input
if nargin < 1 || isempty(folderName)
    folderName = input('Enter target folder name: ', 's');
end

% Strip whitespace and ensure it's not still empty
folderName = strtrim(folderName);
if isempty(folderName)
    error('Folder name cannot be empty.');
end

% 2. Safely create the target directory
if ~isfolder(folderName)
    [status, msg] = mkdir(folderName);
    if ~status
        error('Failed to create directory "%s". Reason: %s', folderName, msg);
    end
end

% 3. Locate all .mat files
matFiles = dir('*.mat');
if isempty(matFiles)
    fprintf('No .mat files found in the current directory to move.\n');
    successCount = 0;
    failCount = 0;
    return;
end

% 4. Move files with try/catch style robustness
successCount = 0;
failCount = 0;

fprintf('Moving %d .mat files to ''%s''...\n', numel(matFiles), folderName);

for k = 1:numel(matFiles)
    sourceFile = matFiles(k).name;
    targetFile = fullfile(folderName, sourceFile);

    % Move file and catch potential permission/lock errors
    [status, msg] = movefile(sourceFile, targetFile);

    if status
        successCount = successCount + 1;
    else
        failCount = failCount + 1;
        warning('Failed to move %s. Reason: %s', sourceFile, msg);
    end
end

% 5. Summary output
    fprintf('Done. Successfully moved: %d | Failed: %d\n', successCount, failCount);
    
    % Only return output variables if explicitly requested to prevent 'ans =' printing
    if nargout > 0
        varargout{1} = successCount;
    end
    if nargout > 1
        varargout{2} = failCount;
    end
end