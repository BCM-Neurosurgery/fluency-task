function ptb = ptb_init(cfg)
% ptb_init  Initialise Psychtoolbox screen and audio for the Fluency task.
%
% Returns ptb struct used throughout the task.

KbName('UnifyKeyNames');
AssertOpenGL;
KbCheck; WaitSecs(0.05); GetSecs;   % pre-load timing functions

%% ── Audio ────────────────────────────────────────────────────────────────
InitializePsychSound(1);
pahandle = PsychPortAudio('Open', [], 1, 1, cfg.fs, 1);
ptb.pahandle   = pahandle;
ptb.sampleRate = cfg.fs;

%% ── Screen ───────────────────────────────────────────────────────────────
Screen('Preference', 'SkipSyncTests', 1);

screens      = Screen('Screens');
screenNumber = 1;   % use external monitor when available

if cfg.big_screen
    [window, windowRect] = Screen('OpenWindow', screenNumber, cfg.colors.background);
else
    [window, windowRect] = Screen('OpenWindow', screenNumber, cfg.colors.background, ...
        [0 0 800 600]);
end

Screen('TextSize', window, cfg.font_size);
Screen('TextFont', window, cfg.font);

[screenW, screenH] = Screen('WindowSize', window);
ifi                = Screen('GetFlipInterval', window);
[xCenter, yCenter] = RectCenter(windowRect);

%% ── Photodiode rect: bottom-left corner, ~1/8 screen height ─────────────
diodeSize = round(screenH / 8);
ptb.diode = [0, screenH - diodeSize, diodeSize, screenH];

%% ── Visual angle geometry ────────────────────────────────────────────────
h_cm      = cfg.screen_size(2) / 10;   % screen height in cm
d_cm      = cfg.screen_distance / 10;  % viewing distance in cm
degPerPx  = rad2deg(atan2(0.5 * h_cm, d_cm)) / (0.5 * screenH);
patchSizePx = max(1, round(cfg.noise_patch_deg / degPerPx));

%% ── Centre text band (horizontal strip used for instruction overlays) ────
bandH = round(screenH * 0.13);
ptb.center_band = [0, yCenter - bandH, screenW, yCenter + bandH];

%% ── Response keys (store as PTB keycodes) ────────────────────────────────
ptb.wait_key  = KbName(cfg.wait_key);
ptb.pause_key = KbName(cfg.pause_key);
ptb.esc_key   = KbName('ESCAPE');

%% ── Output struct ────────────────────────────────────────────────────────
ptb.window            = window;
ptb.window_rect       = windowRect;
ptb.screen_resolution = [screenW, screenH];
ptb.x_center          = xCenter;
ptb.y_center          = yCenter;
ptb.ifi               = ifi;
ptb.patchSizePx       = patchSizePx;
ptb.degPerPx          = degPerPx;

HideCursor(window);
Priority(MaxPriority(window));

end
