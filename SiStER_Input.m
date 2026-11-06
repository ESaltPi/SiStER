function InpFil = SiStER_Input(filename)
% Reads input filename or number selection.
% If empty, displays available SiStER input files and re-prompts if input is invalid.

% Get list of available input files in the current folder
files = dir('SiStER_Input_*.m');
if isempty(files)
    files = dir('*.m'); % Fallback to all .m files if pattern isn't matched
end

% Loop until a valid file is selected or entered
while true
    inputStr = strtrim(filename);
    
    % If empty, show available files menu
    if isempty(inputStr)
        if isempty(files)
            error('No input files found in the current directory.');
        end
        
        fprintf('\nAvailable Input Files:\n');
        for k = 1:length(files)
            fprintf('  [%d] %s\n', k, files(k).name);
        end
        fprintf('\n');
        
        inputStr = strtrim(input('Select input file number or type name: ', 's'));
    end
    
    % Check 1: Did the user enter a menu number?
    numVal = str2double(inputStr);
    if ~isnan(numVal) && floor(numVal) == numVal && numVal >= 1 && numVal <= length(files)
        InpFil = files(numVal).name;
        break;
    end
    
    % Check 2: Did the user enter a filename? Ensure .m extension for checking exist()
    candidateFile = inputStr;
    if ~endsWith(candidateFile, '.m')
        candidateFile = [candidateFile '.m'];
    end
    
    if exist(candidateFile, 'file') == 2
        InpFil = candidateFile;
        break;
    else
        % Invalid entry or non-existent file: report error and reset filename to force menu display
        fprintf('\n[Error] File or option "%s" does not exist.\n', inputStr);
        filename = ''; 
    end
end

% Strip .m extension for run() compatibility
if endsWith(InpFil, '.m')
    InpFil = InpFil(1:end-2);
end

end