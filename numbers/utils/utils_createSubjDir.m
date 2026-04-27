%
% deal with folders
%

function [subjDir, endFlag] = utils_createSubjDir(subid, ses_id, mainDir)
%% define subject specific directory
% folder containing all the data

behDir = fullfile(mainDir, 'beh');

if exist(behDir, 'dir') == 0
    mkdir(behDir )
end

addpath(behDir)

% make a full string of data directory and subject folder
subjDir = fullfile(behDir, ['sub-' subid], ['ses-' ses_id]);

% add slash at the end
subjDir(end+1) = filesep;

% check whether folder exists. if not create a new one, if yes promt the
% operator whether the exp should continue

if  exist(subjDir, 'dir') == 0
    mkdir(subjDir); % create the directory with all the files of this subject
    addpath(subjDir)% add the directory to the path
    % create subdirectories
    mkdir(fullfile(subjDir, 'audio'))
    mkdir(fullfile(subjDir, 'eye'))
    mkdir(fullfile(subjDir, 'mat'))
    endFlag = false;
else
    disp('----------------------------------------------------------')
    prompt = 'Subject directory already exists. Do you want to continue? [Y/N]';
    s = input(prompt, 's');
    if strcmpi(s,'y')
        disp(' ')
        disp('OK, continuing')
        endFlag = false;
    else % if the operator presses anything other than y stop the function here
        disp(' ')
        disp('Stopping experiment')
        endFlag = true;
        return
    end
end