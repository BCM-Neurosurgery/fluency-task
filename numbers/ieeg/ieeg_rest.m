%
% script to record resting state 
%

%% ------------------------- INITIALIZATION ---------------------------- %%
% move to the folder in which the script is
tmp = matlab.desktop.editor.getActive;
cd(fileparts(tmp.Filename));

% clean up everything
clc;
clear;

% check if Screen exists else run it
warning('add ptb path')
if exist('Screen', 'file') == 0
    run 'C:\Users\auditory_vo\Desktop\eyetrackerPsychtoolbox\Psychtoolbox_32\SetupPsychtoolbox.m'
end

%% ----------------- DEFINE VARIABLES FOR DEBUGGING -------------------- %%
flag.bigscreen = 1;
flag.isieeg = 1;
flag.iseyetracking = 1;
flag.recordaudio = 1;
flag.simulateEye = 0;

%% ---------------------------- COLLECT INPUT -------------------------- %%
commandwindow
sub_id = input('Subject ID (birthday (YYYYMMDD), 1st and 3rd letter of mother''s name and surname): ', 's');
ses_id = input('Session ID (12, 22): ', 's');


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

%% -------------------------- resting state ---------------------------- %%
DrawFormattedText(ptb.window, instructions{6}, ...
            'center', 'center', opt.colors.text);
Screen('Flip', ptb.window);
% wait user presses the stopkey
ptb_waitkey(opt);

if flag.isieeg
   trigger_ieeg_send([], .005)
end
    
if flag.iseyetracking
   EyelinkDoTrackerSetup(eye.el);
   edfFname = eye_startRecording(opt, ptb,0 ,0);
end
         
Screen('Flip', ptb.window); %re-flip to show what you have drawn
WaitSecs(300);


if flag.isieeg
   trigger_ieeg_send([], .005)
end
    
if flag.iseyetracking                        
     outFname = sprintf('sub-%s_ses-22_task-rest',subid);
     eye_stopRecording(edfFname, outFname, opt);  
end  

DrawFormattedText(ptb.window, instructions{5}, ...
    'center', 'center', opt.colors.text);
Screen('Flip', ptb.window); %re-flip to show what you have drawn
WaitSecs(5);


%% close all
sca
clear;
clc;
ptb_close;