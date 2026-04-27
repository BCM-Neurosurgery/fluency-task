%
% set up psychtoolbox
%

function psychtb = ptb_init(flag, opt)
% general settings
% Here we call some default settings for setting up Psychtoolbox
% PsychDefaultSetup(2);

% make keyboard comparable across systems
KbName('UnifyKeyNames')

% check for OpenGL compatibility, abort otherwise:
AssertOpenGL;

% Do dummy calls to GetSecs, WaitSecs, KbCheck to make sure
% they are loaded and ready when we need them - without delays
% in the wrong moment:
KbCheck;
WaitSecs(0.05);
GetSecs;

%don't echo keypresses to Matlab window
% ListenChar(2);

%% audio settings
% Perform basic initialization of the sound driver:
InitializePsychSound;

    %initialize audio
    % check the audio devices using PsychPortAudio('GetDevices')
    deviceList = PsychPortAudio('GetDevices');
    for i = 1:length(deviceList)
        if contains(deviceList(i).DeviceName, 'Speakers (Realtek(R) Audio)')
            device = deviceList(i).DeviceIndex;
            channels = deviceList(i).NrInputChannels;
            break
        end
    end
    volume = 1;
    pahandle =  PsychPortAudio('Open', [] , [], 1, opt.fs, 1);
    % pahandle = PsychPortAudio('Open', device, 2, 1, opt.fs, channels);
    %PsychPortAudio ('Volume', pahandle, volume);
    
    % get sampling rate
    s = PsychPortAudio('GetStatus', pahandle);
    
    % audio
    psychtb.pahandle = pahandle;
    psychtb.volume = volume;
    psychtb.sampleRate = s.SampleRate;


%% Screen settings
Screen('Preference', 'SkipSyncTests',1);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
    screenNumber = 1;

% Open an on screen window
if flag.bigscreen
    [window, windowRect] = Screen('OpenWindow', screenNumber, opt.colors.background);
else % if you want smaller windows
    [window, windowRect] = Screen('OpenWindow', screenNumber, opt.colors.background, ...
        [0 0 800 600]);
end

% set text size
if ispc
    Screen('TextSize', window, 20); % this is because of weird 2012b
else
    Screen('TextSize', window, 20);
end

% set font to courier, given monospaced
Screen('TextFont', window, opt.font);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% diode position
diode = [0 0 30 30];

% hide mouse pointer
if flag.isieeg || flag.iseyetracking
    HideCursor(window)
end

% Set priority for script execution to realtime priority:
priorityLevel=MaxPriority(window);
Priority(priorityLevel);

% compute visual angles for this specific computer
% this is based on
% https://osdoc.cogsci.nl/3.3/visualangle/
h = opt.screenSize(2) / 10;
d = opt.screenDistance / 10;
r = screenYpixels;
% compute the degree per pixel
degPerPx = rad2deg(atan2(.5 * h, d)) / (.5 * r);

% compute noise patch size based on visual angle and size of the screen
noisePatchSizePx = [round(opt.noisePatchDeg / degPerPx), round(opt.noisePatchDeg / degPerPx)];
% check that the degrees match the screen dimensions
%if flag.bigscreen
%    assert(all(floor([screenXpixels, screenYpixels] ./ noisePatchSizePx) == [screenXpixels, screenYpixels] ./ noisePatchSizePx))
%end

% compute the fixation window size in pixels
fixWinSizePx = round(opt.fixWinSizeDeg / degPerPx);

% compute the fixation dot size in pixels
fixDotSizePx = round(opt.fixDotSizeDeg / degPerPx);

%% organize everything in a structure for ease of output
% window
psychtb.window = window;
psychtb.screen_resolution = [screenXpixels, screenYpixels];
psychtb.window_rect = windowRect;
psychtb.degPerPx = degPerPx;
psychtb.noisePatchSizePx = noisePatchSizePx;
psychtb.fixWinSizePx = fixWinSizePx;
psychtb.fixDotSizePx = fixDotSizePx;
% circle
psychtb.x_center = xCenter;
psychtb.y_center = yCenter;
psychtb.innercolor = [125 255 125]; % color of the fixation window
% stimuli
psychtb.diode = diode;
% letters
psychtb.defaultfontsize = Screen('TextSize', window);
% timing
psychtb.wait_frames = 1;
psychtb.ifi = ifi;

end