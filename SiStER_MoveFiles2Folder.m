function varargout = SiStER_MoveFiles2Folder(folderName, inpFil)
% SiStER_MoveFiles2Folder Moves all .mat files in current directory to target folder
% and copies the corresponding input file (.m) into that folder.
%
% Usage:
%   SiStER_MoveFiles2Folder('OTF6')
%   SiStER_MoveFiles2Folder('OTF6', 'SiStER_Input_File_OTF6')
%   [successes, failures] = SiStER_MoveFiles2Folder()

% 1. Handle missing or empty folderName input
if nargin < 1 || isempty(folderName)
    folderName = input('Enter target folder name: ', 's');
end

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
else
    % 4. Move .mat files
    successCount = 0;
    failCount = 0;
    fprintf('Moving %d .mat files to ''%s''...\n', numel(matFiles), folderName);

    for k = 1:numel(matFiles)
        sourceFile = matFiles(k).name;
        targetFile = fullfile(folderName, sourceFile);

        [status, msg] = movefile(sourceFile, targetFile);
        if status
            successCount = successCount + 1;
        else
            failCount = failCount + 1;
            warning('Failed to move %s. Reason: %s', sourceFile, msg);
        end
    end
    fprintf('Done moving .mat files. Successfully moved: %d | Failed: %d\n', successCount, failCount);
end

% 5. Determine input file name (from argument or from inside the moved .mat files)
if nargin < 2 || isempty(inpFil)
    inpFil = '';
    movedMats = dir(fullfile(folderName, '*.mat'));
    if ~isempty(movedMats)
        firstMat = fullfile(folderName, movedMats(1).name);
        info = whos('-file', firstMat);
        if ismember('InpFil', {info.name})
            tmp = load(firstMat, 'InpFil');
            inpFil = tmp.InpFil;
        end
    end
end

% 6. Copy the input .m file into the target folder
if ~isempty(inpFil)
    inpFil = strtrim(char(inpFil));
    if ~endsWith(inpFil, '.m')
        inpFileName = [inpFil '.m'];
    else
        inpFileName = inpFil;
    end

    if exist(inpFileName, 'file') == 2
        destInpPath = fullfile(folderName, inpFileName);
        [cStatus, cMsg] = copyfile(inpFileName, destInpPath);
        if cStatus
            fprintf('Copied input file ''%s'' to ''%s''.\n', inpFileName, folderName);
        else
            warning('Failed to copy input file %s. Reason: %s', inpFileName, cMsg);
        end
    else
        warning('Input file "%s" not found in current directory; skipped copying.', inpFileName);
    end
end

% 7. Optional outputs
if nargout > 0
    varargout{1} = successCount;
end
if nargout > 1
    varargout{2} = failCount;
end
end