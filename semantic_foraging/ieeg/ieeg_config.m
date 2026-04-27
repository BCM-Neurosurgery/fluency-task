%
% configuration settings for genN experiment
%

function opt = ieeg_config(flag, subjDir, mainDir)
opt = struct();

%% general settings
opt.subjDir = subjDir;
opt.mainDir = mainDir;
opt.datetime = datestr(now);

% key to press
opt.waitKey = KbName('w');

%% experiment settings
opt.blockBreakDuration = 4; %s

opt.soundDuration = .5;

opt.blockDuration = 90; % s
opt.nBlocks = 12;

opt.nBlocksON = 2;
opt.nBlocksOFF = 10;

opt.categories = {'animali', 'professioni'};

%% metronome
opt.metronomeFrequency = 0.5;
opt.metronomeTime = 1 ./ opt.metronomeFrequency;
opt.expectedWordsPerBlock = floor(opt.blockDuration ./ opt.metronomeTime )-1;

%% noise patch
opt.nPatches = opt.nBlocks;
opt.noisePatchDeg = 0.51;

% screen
opt.screenSize = [520, 330]; % mm
opt.screenDistance = 910; % mm


%% eye tracker
% eye to track, 0: left, 1: right, 2: both
opt.eyeUsed = 0;
eyeOptions = {'LEFT', 'RIGHT', 'BOTH'};
opt.eyeTracked = eyeOptions{opt.eyeUsed + 1};
opt.simulateEye = flag.simulateEye;

% amount of time that participants need to fixate within the window to
% start the trial
opt.fixationTime = .5; %in seconds
opt.fixWinSizeDeg = [2, 2];
opt.maxFixationTime = 4;
opt.fixDotSizeDeg = 0.5;

%% text
opt.font = 'Courier';

%% audio
% datapixx
opt.audioSource = 1;
opt.fs = 48000;

%% colors
% we have implemented contrast modulation by default
opt.colors.background = [128 128 128]; % dark gray
opt.colors.text = [0 0 0]; % white
opt.colors.red = [153 0 0];

end