%
% script for the ieeg GenN experiment
%


% GG: 
% for the first subject (26/02/26) we will run:
% - training 
% - 2 runs of range 1-12
% - 2 runs of range 11-22
% - 2 runs of range 1-12
% - 2 runs of range 11-22
% - 1 run of control task

%% ------------------------- INITIALIZATION ---------------------------- %%
% move to the folder in which the script is
tmp = matlab.desktop.editor.getActive;
cd(fileparts(tmp.Filename));

% clean up everything
clc;
clear;

setPath();

%% ----------------- DEFINE VARIABLES FOR DEBUGGING -------------------- %%
flag.bigscreen = 1;
flag.isieeg = 0;
flag.iseyetracking = 0;
flag.recordaudio = 0;
flag.simulateEye = 0;

%% ---------------------------- COLLECT INPUT -------------------------- %%
commandwindow
sub_id = input('Subject ID (birthday (YYYYMMDD), 1st and 3rd letter of mother''s name and surname): ', 's');
ses_id = input('Session ID (12, 22, 12training, 22training): ', 's');
iRun = str2double(input('Run number: ', 's'));


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
flist = dir(fullfile(subjDir, 'mat', sprintf('sub-%s_ses-%s_task-genn_run-%02d_desc-b*-f%d-m*_timings.mat', ...
sub_id, ses_id, iRun, 0.5)));

assert(isempty(flist), sprintf('%d file(s) of this run already exist.', length(flist)))

%% ------------------ DEFINE EXPERIMENTAL SETTINGS --------------------- %%
%
if contains(ses_id, "training")
    opt = training_config(flag, subjDir, mainDir);
    instructions = training_instructions(ses_id);
else
    opt = ieeg_config(flag, subjDir, mainDir);
    instructions = ieeg_instructions(ses_id);
end

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
if contains(ses_id, "training")
    stim = training_defineExperiment(sub_id, ses_id, opt, ptb);
else
    stim = ieeg_defineExperiment(sub_id, ses_id, opt, ptb);
end

%% -------------------- EXECUTE MAIN EXPERIMENT ------------------------ %%

%for iRun = 1 : opt.nRuns

% give instructions
if iRun == 1
    DrawFormattedText(ptb.window, instructions{1}, ...
        'center', 'center', opt.colors.text);    
else
    DrawFormattedText(ptb.window, sprintf(instructions{2}), ...
        'center', 'center', opt.colors.text);
end

Screen('Flip', ptb.window); %re-flip to show what you have drawn
% wait user presses the stopkey
ptb_waitkey(opt);

% run calibration of the eye tracker with the settings defined in eye_init
if flag.iseyetracking
    EyelinkDoTrackerSetup(eye.el);
else
    % wait user presses the stopkey
    ptb_waitkey(opt);
end

% Sync us and get a time stamp
vbl = Screen('Flip', ptb.window);

for iBlock = 1 : opt.nBlocksxRun
    
    % get info about this block
    thisBlockInfo = stim.condition.(sprintf('r%i_b%i', iRun, iBlock));
    % initialize output structure, this will contain timings
    timings = struct();
    % define output files names
    outFname = sprintf('sub-%s_ses-%s_task-genn_run-%02d_desc-b%02d-f%d-m%s', ...
        sub_id, ses_id, iRun, iBlock, thisBlockInfo.metronomeFrequency*100, ...
        thisBlockInfo.metronomeStatus);
    
    fprintf('\nRun %i Block %i: Metronome %s', iRun, iBlock, ...
        thisBlockInfo.metronomeStatus)
    
    % inform about progress in the experiment
    Screen('DrawTexture', ptb.window, thisBlockInfo.texture);
    Screen('FillRect', ptb.window, opt.colors.background,  ...
        [ptb.window_rect(1) ptb.screen_resolution(2)/2-ptb.window_rect(4)*.10 ...
        ptb.window_rect(3) ptb.screen_resolution(2)/2+ptb.window_rect(4)*.10])
    DrawFormattedText(ptb.window, sprintf('Inizio prova %d/%d', iBlock, opt.nBlocksxRun), ...
        'center', 'center', opt.colors.text);
    %ptb_drawDiode(ptb, false, [0,0,0]);
    Screen('Flip', ptb.window); %re-flip to show what you have drawn
    WaitSecs(1);
    
    % check fixation. this is a while loop going on until fixation is
    % obtained
    if flag.iseyetracking
        % within this function we flip to the screen a black diode with
        % the noise pattern
        eye_beginTrialFixation(eye, ptb, opt, thisBlockInfo.texture);
        % start recording eye tracker
        edfFname = eye_startRecording(opt, ptb, iRun, iBlock);
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
    
    % inter-trial interval
    if iBlock == round(opt.nBlocksxRun/2) && flag.iseyetracking
        % do a final check of calibration using driftcorrection
        EyelinkDoDriftCorrection(eye.el);
    elseif iBlock ~= opt.nBlocksxRun
        WaitSecs(opt.blockBreakDuration);
    end
    
    % remove text, to let participant know we are starting again
    % draw noise pattern
    Screen('DrawTexture', ptb.window, thisBlockInfo.texture);
    Screen('Flip', ptb.window); %re-flip to show what you have drawn
    WaitSecs(.25);
    
end % block
%
% insert here the breaks
if iRun == opt.nRuns
    DrawFormattedText(ptb.window, instructions{4}, ...
        'center', 'center', opt.colors.text);
    Screen('Flip', ptb.window); %re-flip to show what you have drawn
    ptb_waitkey(opt);
else
    DrawFormattedText(ptb.window, 'Questo blocco sperimentale è finito.\nPuoi prendere una pausa.', ...
        'center', 'center', opt.colors.text);
    Screen('Flip', ptb.window); %re-flip to show what you have drawn
end
WaitSecs(2);

%end % runs

%% close all
sca
clear;
clc;
ptb_close;
