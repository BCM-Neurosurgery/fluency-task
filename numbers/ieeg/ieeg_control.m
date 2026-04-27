%
% script for the ieeg control experiment
%

%% ------------------------- INITIALIZATION ---------------------------- %%
% move to the folder in which the script is
tmp = matlab.desktop.editor.getActive;
cd(fileparts(tmp.Filename));

% clean up everything
clc;
clear;

% check if Screen exists else run it

addpath('C:\Program Files\MATLAB\R2020a\toolbox\fastportIO')
if exist('Screen', 'file') == 0  
    run 'C:\toolbox\Psychtoolbox\SetupPsychtoolbox.m'
end

%% ----------------- DEFINE VARIABLES FOR DEBUGGING -------------------- %%
flag.bigscreen = 1;
flag.isieeg = 1;
flag.iseyetracking = 1;
flag.simulateEye = 0;

%% ---------------------------- COLLECT INPUT -------------------------- %%
commandwindow
sub_id = input('Subject ID (birthday (YYYYMMDD), 1st and 3rd letter of mother''s name and surname): ', 's');
ses_id = input('Session ID (12, 22): ', 's');
iRun = str2double(input('Run number: ', 's'));
assert(iRun == 1)

%% -------------------------- DEAL WITH FOLDERS ------------------------ %%
% main directory should go here as all the following scripts that will be
% called depend on this
mainDir = fileparts(pwd);

if exist(mainDir, 'dir') == 0
    mkdir(mainDir)
end

% add the script directory and its subfolder to the path
addpath(genpath(mainDir))

% define and create directory of the experiment and of the current participant
[subjDir, stopExp] = utils_createSubjDir(sub_id, ses_id, mainDir);

% this is to stop execution if subject name is already in the main folder
% should go here because we want to stop the main script
if stopExp
    return
end

% check that there is no file with the same name; this may happen if by
% mistake the same run number is entered twice
flist = dir(fullfile(subjDir, 'mat', sprintf('sub-%s_ses-%s_task-control_run-%02d_desc-b*_timings.mat', ...
    sub_id, ses_id, iRun)));

assert(isempty(flist), sprintf('%d file(s) of this run already exist.', length(flist)))

%% ------------------ DEFINE EXPERIMENTAL SETTINGS --------------------- %%
%
opt = ieeg_config(flag, subjDir, mainDir);
instructions = ieeg_instructions(ses_id);

%% ---------------- SET UP AND INITIALIZE PSYCHTOOLBOX ----------------- %%
% initialize psychtoolbox
ptb = ptb_init(flag, opt);

%% ------------------------- INITIALIZE EYELINK ------------------------ %%

if flag.iseyetracking
    % init the eye-tracker
    eye = eye_init(ptb.window, opt);
end

%% -------------- CALCULATE EXPERIMENTAL RELATED SETTINGS -------------- %%
% define stimuli presentation
stim = ieeg_defineExperiment(sub_id, ses_id, opt, ptb);

%% ------------------- EXECUTE CONTROL EXPERIMENT ---------------------- %%

% give instructions
if iRun == 1
    DrawFormattedText(ptb.window, instructions{3}, ...
        'center', 'center', opt.colors.text);
    Screen('Flip', ptb.window);
    % wait user presses the stopkey
    ptb_waitkey(opt);
end

% run calibration of the eye tracker with the settings defined in eye_init
if flag.iseyetracking
    EyelinkDoTrackerSetup(eye.el);
else
    % wait user presses the stopkey
    ptb_waitkey(opt);
end

% Sync us and get a time stamp
vbl = Screen('Flip', ptb.window);

for iBlock = 1 : opt.nControlBlocksxRun
    
    % get info about this block
    thisBlockInfo = stim.condition.(sprintf('r%i_control%i', iRun, iBlock));
    % initialize output structure, this will contain timings
    timings = struct();
    % define output files names
    outFname = sprintf('sub-%s_ses-%s_task-control_run-%02d_desc-b%02d', ...
        sub_id, ses_id, iRun, iBlock);
    
    fprintf('\nRun %i Block %i', iRun, iBlock)
    
    % inform about progress in the experiment
    Screen('FillRect', ptb.window, opt.colors.background,  ...
        [ptb.window_rect(1) ptb.screen_resolution(2)/2-ptb.window_rect(4)*.10 ...
        ptb.window_rect(3) ptb.screen_resolution(2)/2+ptb.window_rect(4)*.10])
    DrawFormattedText(ptb.window, sprintf('Inizio prova %d/%d', iBlock, opt.nControlBlocksxRun), ...
        'center', 'center', opt.colors.text);
    %ptb_drawDiode(ptb, false, [0,0,0]);
    Screen('Flip', ptb.window); %re-flip to show what you have drawn
    WaitSecs(1);
    
    % check fixation. this is a while loop going on until fixation is
    % obtained
    if flag.iseyetracking
        eye_beginTrialFixation(eye, ptb, opt, []);
        % start recording eye tracker
        edfFname = eye_startRecording(opt, ptb, iRun, iBlock);
        timings.startEyeRecording = GetSecs;
    end
    
    % send trigger to eye tracker
    if flag.iseyetracking
        Eyelink('Message', 'Start');
    end
    
    % flip to the screen
    timings.blockStart = GetSecs;
    
    %
    % present dots
    %
    for i_pos = 1 : length(thisBlockInfo.sequence_pos)
        % get the x position of this dot
        dot_x = thisBlockInfo.sequence_pos(i_pos);
        
        if flag.isieeg
            trigger_ieeg_send([], .005)
        end
        
        % Draw dot
        Screen('FillOval', ptb.window, [0 0 0],...
            [(dot_x-ptb.stimSizePx(1)/2) (ptb.y_center-ptb.stimSizePx(2)/2) ...
            (dot_x+ptb.stimSizePx(1)/2) (ptb.y_center+ptb.stimSizePx(2)/2)], []);
        Screen('Flip', ptb.window);
        timings.dot(i_pos) = GetSecs;
        WaitSecs(opt.metronomeTime + thisBlockInfo.jitter(i_pos));
        
    end
    
    % send trigger to eye tracker
    if flag.iseyetracking
        Eyelink('Message', 'End');
        timings.endEyeTrigger = GetSecs;
        eye_stopRecording(edfFname, outFname, opt);
        timings.stopEyeRecording(iBlock) = GetSecs;
    end
    
    % prompt participant with the break
    DrawFormattedText(ptb.window, 'PAUSA', 'center', 'center', opt.colors.text);
    Screen('Flip', ptb.window); %re-flip to show what you have drawn
    
    % save timings variable
    save(fullfile(opt.subjDir, 'mat', sprintf('%s_timings.mat', outFname)), 'timings')
    
    % inter-trial interval
    if iBlock == 6 && flag.iseyetracking
        % do a final check of calibration using driftcorrection
        EyelinkDoDriftCorrection(eye.el);
    elseif iBlock ~= opt.nControlBlocksxRun
        WaitSecs(opt.blockBreakDuration);
    end
    
    % remove text, to let participant know we are starting again
    % draw noise pattern
    Screen('Flip', ptb.window); %re-flip to show what you have drawn
    WaitSecs(.25);
    
end % block


DrawFormattedText(ptb.window, 'Questo blocco sperimentale è finito.\nPuoi prendere una pausa.', ...
    'center', 'center', opt.colors.text);
Screen('Flip', ptb.window); %re-flip to show what you have drawn
WaitSecs(2);

%% close all
sca
clear;
clc;
ptb_close;