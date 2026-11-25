function SiStER_ExportCodebase(outputFile, rootDir)
% SiStER_ExportCodebase Bundles the directory tree and all code/script files
% into a single plain-text file (default: 'sister_codebase.txt').
%
% Usage:
%   SiStER_ExportCodebase()
%   SiStER_ExportCodebase('sister_codebase.txt')
%   SiStER_ExportCodebase('sister_codebase.txt', pwd)

if nargin < 1 || isempty(outputFile)
    outputFile = 'sister_codebase.txt';
end
if nargin < 2 || isempty(rootDir)
    rootDir = pwd;
end

% File extensions to include in full-text dump
textExts = {'.m', '.sh', '.py', '.txt', '.md', '.csv', '.json', '.yaml', '.yml', '.gitignore'};

% Folders to skip (hidden/git folders and binary output run folders if needed)
skipDirs = {'.git', '.svn', '.hg', '__pycache__'};

% Recursively gather all files
allEntries = dir(fullfile(rootDir, '**', '*'));
fileList = {};

for k = 1:numel(allEntries)
    if allEntries(k).isdir
        continue;
    end

    fullPath = fullfile(allEntries(k).folder, allEntries(k).name);
    relPath = strrep(fullPath, [rootDir filesep], '');
    relPath = strrep(relPath, '\', '/'); % Normalize slashes

    % Skip output file itself
    if strcmpi(allEntries(k).name, outputFile) || strcmpi(relPath, outputFile)
        continue;
    end

    % Skip hidden/version-control directories
    parts = strsplit(relPath, '/');
    if any(ismember(parts(1:end-1), skipDirs)) || any(startsWith(parts, '.'))
        % Allow .gitignore explicitly
        if ~strcmp(allEntries(k).name, '.gitignore')
            continue;
        end
    end

    fileList{end+1} = relPath; %#ok<AGROW>
end

fileList = sort(fileList);

% Open output text file
fid = fopen(outputFile, 'w', 'n', 'UTF-8');
if fid == -1
    error('Could not open "%s" for writing.', outputFile);
end
cleanupObj = onCleanup(@() fclose(fid));

% 1. Write Directory Tree
fprintf(fid, '=== DIRECTORY TREE ===\n');
for k = 1:numel(fileList)
    fprintf(fid, './%s\n', fileList{k});
end

% 2. Write File Contents
fprintf(fid, '\n=== FILE CONTENTS ===\n');
exportedCount = 0;

for k = 1:numel(fileList)
    relPath = fileList{k};
    fullPath = fullfile(rootDir, strrep(relPath, '/', filesep));
    [~, ~, ext] = fileparts(relPath);

    % Include files matching allowed text/code extensions (or .gitignore)
    if any(strcmpi(ext, textExts)) || strcmpi(relPath, '.gitignore')
        content = fileread(fullPath);
        fprintf(fid, '\n==================== %s ====================\n', relPath);
        fprintf(fid, '%s\n', content);
        exportedCount = exportedCount + 1;
    end
end

fprintf('Exported %d code/text files (out of %d total files) to "%s".\n', ...
    exportedCount, numel(fileList), outputFile);
end