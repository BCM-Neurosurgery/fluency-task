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

opt.blockDuration = 30; % s
opt.nBlocksxRun = 13;
opt.runDuration = opt.nBlocksxRun * (opt.blockDuration + opt.blockBreakDuration);

opt.nRuns = 5;

opt.nBlocks = opt.nBlocksxRun * opt.nRuns;

opt.nBlocksON = 1;
opt.nBlocksOFF = 12;

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

%% control
opt.n_positions = 12;
opt.trans_lim = opt.n_positions-1;
opt.nControlRuns = 1;
opt.nControlBlocksxRun = 12;
opt.nControlBlocks = opt.nControlBlocksxRun * opt.nControlRuns;
if mod(opt.nControlBlocks, opt.n_positions)==0
    opt.n_starting = [1:opt.n_positions; repmat(opt.nControlBlocks / opt.n_positions, [1, opt.n_positions])]';
else
    opt.n_starting = [1:opt.n_positions; ones(1, opt.n_positions)]';
    rand_ind = datasample(1:opt.n_positions, mod(opt.nControlBlocks, opt.n_positions), 'Replace', false);
    opt.n_starting(rand_ind, 2) = opt.n_starting(rand_ind,2)+1;
end
    
opt.jitter = 1;

opt.stimSizeDeg = 0.5;

%% colors
% we have implemented contrast modulation by default
opt.colors.background = [128 128 128]; % dark gray
opt.colors.text = [0 0 0]; % white
opt.colors.red = [153 0 0];

end