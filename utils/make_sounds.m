function stim = make_sounds(cfg)
% make_sounds  Generate alert and metronome beep waveforms.
%
% Returns stim struct with fields:
%   alert_sound      – 1×N row vector, 1200 Hz, 150 ms
%   metronome_sound  – 1×N row vector,  800 Hz, 100 ms
%   fs               – sample rate (Hz)

fs   = cfg.fs;
stim.fs = fs;

%% Alert sound: 1200 Hz, 150 ms
stim.alert_sound = make_beep(fs, 1200, 0.15);

%% Metronome beep: 800 Hz, 100 ms
stim.metronome_sound = make_beep(fs, 800, 0.10);

end

% ── helper ────────────────────────────────────────────────────────────────
function wav = make_beep(fs, freq, dur)
N    = round(fs * dur);
t    = (1:N) / fs;
nF   = max(1, round(N / 10));   % fade samples (~10 % each end)
fade = sin(linspace(0, pi/2, nF));
env  = [fade, ones(1, N - 2*nF), fliplr(fade)];
wav  = sin(2*pi*freq*t) .* env;   % 1×N row vector
end
