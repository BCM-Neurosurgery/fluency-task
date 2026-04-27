function [subjDir, stopExp] = utils_createSubjDir(subid, mainDir)
% utils_createSubjDir  Create (or verify) the subject output directory.
%
% Directory layout:  mainDir/beh/sub-<subid>/mat/

behDir  = fullfile(mainDir, 'beh');
if ~exist(behDir, 'dir'); mkdir(behDir); end

subjDir = fullfile(behDir, ['sub-' subid], filesep);

if ~exist(subjDir, 'dir')
    mkdir(subjDir);
    mkdir(fullfile(subjDir, 'mat'));
    stopExp = false;
else
    disp('----------------------------------------------------------');
    s = input('Subject directory already exists. Continue? [Y/N]: ', 's');
    if strcmpi(s, 'y')
        disp('Continuing.');
        stopExp = false;
    else
        disp('Stopping.');
        stopExp = true;
    end
end

end
