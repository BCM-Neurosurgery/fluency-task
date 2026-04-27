%
% configuration settings for genN experiment
%
function opt = training_config(flag, subjDir, mainDir)
opt = struct();

%% general settings
opt.subjDir = subjDir;
opt.mainDir = mainDir;
opt.datetime = datetime;

% key to press
opt.waitKey = KbName('w');

%% experiment settings
opt.blockBreakDuration = 4; %s
opt.runBreakDuration = 20;

opt.soundDuration = .5;

opt.blockDuration = 30; % s
opt.nBlocksxRun = 12;
opt.runDuration = opt.nBlocksxRun * (opt.blockDuration + opt.blockBreakDuration);

opt.nRuns = 1;

opt.nBlocks = opt.nBlocksxRun * opt.nRuns;

%% metronome

opt.metronomeFrequency = 0.5;
opt.metronomeTime = 1 ./ opt.metronomeFrequency;
opt.expectedWordsPerBlock = floor(opt.blockDuration ./ opt.metronomeTime);

%% noise patch
opt.nPatches = opt.nBlocks;
if flag.iseyetracking
    opt.noisePatchDeg = .5;
else
    opt.noisePatchDeg = .4;
    warning('using a different noise patch size')
end

% screen
if flag.iseyetracking
    opt.screenSize = [520, 290]; % mm
    opt.screenDistance = 900; % mm
else
    opt.screenSize = [510, 380]; % mm
    opt.screenDistance = 500; % mm
end

%% eye tracker
% eye to track, 0: left, 1: right, 2: both
opt.eyeUsed = 0;
eyeOptions = {'LEFT', 'RIGHT', 'BOTH'};
opt.eyeTracked = eyeOptions{opt.eyeUsed + 1};
opt.simulateEye = flag.simulateEye;

% amount of time that participants need to fixate within the window to
% start the trial
opt.fixationTime = .5; %in seconds
opt.fixWinSizeDeg = [1, 1];
opt.maxFixationTime = 5;
opt.fixDotSizeDeg = 0.4;

opt.stimSizeDeg = 0.5;

%% text
opt.font = 'Courier';

%% screen

%% audio
opt.fs = 48000;

%% colors
% we have implemented contrast modulation by default
opt.colors.background = [128 128 128]; % dark gray
opt.colors.text = [0 0 0]; % white
opt.colors.red = [153 0 0];

end