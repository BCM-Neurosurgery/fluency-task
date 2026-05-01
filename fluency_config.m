function cfg = fluency_config()
% fluency_config  Master configuration for the Fluency Task.
%
% Edit this file to change task parameters.  fluency_main.m reads this
% struct at startup; no other file needs editing for routine changes.

%% ── Hardware flags ───────────────────────────────────────────────────────
cfg.use_blackrock  = false;    % send TaskComment / cbmex comments to Blackrock
cfg.use_photodiode = true;    % flash white square at every event marker

%% ── Data output ──────────────────────────────────────────────────────────
% Sessions are saved to:
%   data_dir / {subject_id} / fluency / fluency_{timestamp} / mat /
cfg.data_dir = 'C:\Users\EMU - Behavior\Documents\MATLAB\PatientData';

%% ── Display ──────────────────────────────────────────────────────────────
cfg.big_screen      = true;   % false → 800×600 window (for debugging)
cfg.screen_number   = 1;      % PTB screen index (0 = primary, 1 = external)
cfg.screen_size     = [520, 330];  % physical screen [width, height] in mm
cfg.screen_distance = 910;         % eye-to-screen distance in mm

%% ── Colors ───────────────────────────────────────────────────────────────
cfg.colors.background = [128, 128, 128];  % grey noise / blank screen
cfg.colors.banner     = [  0,   0,   0];  % black background for text overlays
cfg.colors.text       = [255, 255, 255];  % white text on banners
cfg.colors.diode_on   = [255, 255, 255];  % photodiode ON (white)

%% ── Font ─────────────────────────────────────────────────────────────────
cfg.font      = 'Courier';
cfg.font_size = 42;

%% ── Response keys ────────────────────────────────────────────────────────
cfg.wait_key  = 'w';        % advance / confirm key
cfg.pause_key = 'p';        % pause mid-block or mid-rest
% Press Escape at any time to kill the task (sends TaskComment kill)

%% ── Flow control ─────────────────────────────────────────────────────────
% true  → show block info screen and wait for W before every block
% false → advance automatically after the rest period, no key needed
% Between runs: always requires W regardless of this flag.
cfg.require_key_between_blocks = true;

%% ── Audio ────────────────────────────────────────────────────────────────
cfg.fs = 48000;             % audio sample rate (Hz)

%% ── Visual noise patch ───────────────────────────────────────────────────
cfg.noise_patch_deg = 0.51; % visual angle of each noise tile (degrees)

%% ── Metronome ────────────────────────────────────────────────────────────
cfg.metronome_frequency = 0.5;   % Hz  →  one beat every 2 s

%% ── Run structure ────────────────────────────────────────────────────────
% run_types: 'semantic' or 'numbers'
cfg.num_runs  = 4;
cfg.run_types = {'semantic', 'semantic', 'numbers', 'semantic'};

% Prompts for semantic runs, assigned in order of appearance
cfg.semantic_prompts = {
    'animals', ...
    'professions', ...
    'things that are easier said than done'
};

%% ── Per-run parameters ───────────────────────────────────────────────────
% All arrays are indexed by run number (length must equal cfg.num_runs).

cfg.num_blocks = [2, 6, 6, 6];   % blocks per run

% Block recording duration (seconds) — defaults by type:
%   semantic → 90 s,  numbers → 30 s
cfg.block_duration = [10, 90, 30, 90];

% Rest between blocks within a run (seconds)
%   semantic → 60 s,  numbers → 10 s
cfg.rest_duration = [10, 60, 30, 60];

% Rest between runs (seconds) — length must equal cfg.num_runs - 1.
% Entry i is the rest between run i and run i+1.
cfg.run_rest_duration = [60, 60, 30];

%% ── Metronome schedule ───────────────────────────────────────────────────
% cfg.use_metronome{r}(b) = true/false for run r, block b.
% Default: first block of every run plays the metronome; rest do not.
cfg.use_metronome = cell(1, cfg.num_runs);
for r = 1 : cfg.num_runs
    cfg.use_metronome{r} = [true, false(1, cfg.num_blocks(r) - 1)];
end

end
