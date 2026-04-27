%
% script for the ieeg semantic foraging experiment with eye tracking
%
% TODO:
% x metronome at 0.5 hz for the first two blocks as practice
% - counterbalance between genn and sem. foraging
% x 2 categories: animali, professioni
% x visual noise
% x 1.30 min blocks
% x 12 blocks, 6 per category, randomized and make sure the randomization is not 

%% ------------------------- INITIALIZATION ---------------------------- %%
% move to the folder in which the script is
tmp = matlab.desktop.editor.getActive;
cd(fileparts(tmp.Filename));

% clean up everything
clc;
clear;

%% ----------------- DEFINE VARIABLES FOR DEBUGGING -------------------- %%
flag.bigscreen = 1;
flag.isieeg = 0;
flag.iseyetracking = 0;
flag.recordaudio = 0;
flag.simulateEye = 0;

%% ---------------------------- COLLECT INPUT -------------------------- %%
commandwindow
sub_id = input('Subject ID (birthday (YYYYMMDD), 1st and 3rd letter of mother''s name and surname): ', 's');
iBlock = str2double(input('Block number: ', 's'));


%% -------------------------- DEAL WITH FOLDERS ------------------------ %%
if flag.isieeg
    setPath()
end

% main directory should go here as all the following scripts that will be
% called depend on this
mainDir = fileparts(pwd);

if exist(mainDir, 'dir') == 0
    mkdir(mainDir)
end

% add the script directory and its subfolder to the path
addpath(genpath(mainDir))

% define and create directory of the experiment and of the current participant
[subjDir, stopExp] = utils_createSubjDir(sub_id, mainDir);

% this is to stop execution if subject name is already in the main folder
% should go here because we want to stop the main script
if stopExp
    return
end

% check that there is no file with the same name; this may happen if by
% mistake the same run number is entered twice
flist = dir(fullfile(subjDir, 'mat', sprintf('sub-%s_task-foraging_desc-b%02d-*_timings.mat', ...
    sub_id, iBlock)));

assert(isempty(flist), sprintf('The file of this block already exist.'))

%% ------------------ DEFINE EXPERIMENTAL SETTINGS --------------------- %%
%
opt = ieeg_config(flag, subjDir, mainDir);
instructions = ieeg_instructions();


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
stim = ieeg_defineExperiment(sub_id, opt, ptb);

%% -------------------- EXECUTE MAIN EXPERIMENT ------------------------ %%

% give instructions
if iBlock == 1
    DrawFormattedText(ptb.window, instructions{1}, ...
        'center', 'center', opt.colors.text);
    Screen('Flip', ptb.window); %re-flip to show what you have drawn
    % wait user presses the stopkey
    ptb_waitkey(opt);
end

% run calibration of the eye tracker with the settings defined in eye_init
if flag.iseyetracking
    EyelinkDoTrackerSetup(eye.el);
end

% get info about this block
thisBlockInfo = stim.condition.(sprintf('b%i', iBlock));
% initialize output structure, this will contain timings
timings = struct();
% define output files names
outFname = sprintf('sub-%s_task-foraging_desc-b%02d-m%s-%s', ...
    sub_id, iBlock, thisBlockInfo.metronomeStatus, thisBlockInfo.category{1});

fprintf('\nBlock %i', iBlock)

% inform about progress in the experiment
Screen('DrawTexture', ptb.window, thisBlockInfo.texture);
Screen('FillRect', ptb.window, opt.colors.background,  ...
    [ptb.window_rect(1) ptb.screen_resolution(2)/2-ptb.window_rect(4)*.10 ...
    ptb.window_rect(3) ptb.screen_resolution(2)/2+ptb.window_rect(4)*.10])
% give instructions for this block
DrawFormattedText(ptb.window, sprintf(instructions{2},upper(thisBlockInfo.category{1})), ...
    'center', 'center', opt.colors.text);

% Sync us and get a time stamp
vbl = Screen('Flip', ptb.window);
%ptb_drawDiode(ptb, false, [0,0,0]);
WaitSecs(4);

% check fixation. this is a while loop going on until fixation is
% obtained
if flag.iseyetracking
    % within this function we flip to the screen a black diode with
    % the noise pattern
    %eye_beginTrialFixation(eye, ptb, opt, thisBlockInfo.texture);
    % start recording eye tracker
    edfFname = eye_startRecording(opt, ptb, 1, iBlock);
    timings.startEyeRecording = GetSecs;
end

% draw noise pattern
Screen('DrawTexture', ptb.window, thisBlockInfo.texture);

if flag.recordaudio
    % Preallocate an internal audio recording buffer with a capacity of 60 seconds
    PsychPortAudio('GetAudioData', ptb.pahandle, 60);
    % Start audio capture immediately and wait for the capture to start.
    % We set the number of 'repetitions' to zero,
    % i.e. record until recording is manually stopped.
    PsychPortAudio('Start', ptb.pahandle, 0, 0, 1);
end

% set photodiode to white
%ptb_drawDiode(ptb, false, [255, 255, 255]);
% send trigger to meg and draw photodiode
if flag.isieeg
    trigger_ieeg_send([], .005)
end
% send trigger to eye tracker
if flag.iseyetracking
    Eyelink('Message', 'Start');
end

% use datapixx to record audio
% flip to the screen
blockStart = Screen('Flip', ptb.window); %re-flip to show what you have drawn
timings.blockStart = blockStart;

% play audio to signal start of recording block followed by the metronome
if strcmp(thisBlockInfo.metronomeStatus, 'ON')
    sound(stim.metronomeSequence, stim.audio.sf);
elseif strcmp(thisBlockInfo.metronomeStatus, 'OFF')
    sound(stim.alertingSequence, stim.audio.sf);
end
timings.metronomeStart = GetSecs;

% wait until the end of the block duration
WaitSecs(opt.blockDuration);

timings.blockEnd  = GetSecs;
fprintf('\nend block')

% send trigger to eye tracker
if flag.iseyetracking
    Eyelink('Message', 'End');
    timings.endEyeTrigger = GetSecs;
end

timings.metronomeEnd = GetSecs;

% prompt participant with the break
Screen('DrawTexture', ptb.window, thisBlockInfo.texture);
Screen('FillRect', ptb.window, opt.colors.background,  ...
    [ptb.window_rect(1) ptb.screen_resolution(2)/2-ptb.window_rect(4)*.10 ...
    ptb.window_rect(3) ptb.screen_resolution(2)/2+ptb.window_rect(4)*.10])
DrawFormattedText(ptb.window, 'PAUSA', 'center', 'center', opt.colors.text);
Screen('Flip', ptb.window); %re-flip to show what you have drawn

% wait a few seconds to collect some more data
WaitSecs(.5);

% stop eye tracker recording
if flag.iseyetracking
    eye_stopRecording(edfFname, outFname, opt);
    timings.stopEyeRecording(iBlock) = GetSecs;
end

if flag.recordaudio
    timings.endAudioRecording = GetSecs;
    % Stop Audio recording and collect samples
    PsychPortAudio('Stop', ptb.pahandle);
    recordedAudio = PsychPortAudio('GetAudioData', ptb.pahandle);
    % save audio file
    audiowrite(fullfile(opt.subjDir, 'audio', sprintf('%s_audio.wav', outFname)), ...
        transpose(recordedAudio), opt.fs);
    
end

% save timings variable
save(fullfile(opt.subjDir, 'mat', sprintf('%s_timings.mat', outFname)), 'timings')

% remove text, to let participant know we are starting again
% draw noise pattern
Screen('DrawTexture', ptb.window, thisBlockInfo.texture);
Screen('Flip', ptb.window); %re-flip to show what you have drawn
WaitSecs(.25);

%
% insert here the breaks
if iBlock == opt.nBlocks
    DrawFormattedText(ptb.window, instructions{4}, ...
        'center', 'center', opt.colors.text);
    Screen('Flip', ptb.window); %re-flip to show what you have drawn
    ptb_waitkey(opt);
else
    DrawFormattedText(ptb.window, 'Questo blocco sperimentale è finito.\nPuoi fare una pausa.', ...
        'center', 'center', opt.colors.text);
    Screen('Flip', ptb.window); %re-flip to show what you have drawn
end
WaitSecs(2);


%% close all
sca
clear;
clc;
ptb_close;
