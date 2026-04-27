%
% fast audio segmentation to give feedback to participants
%

function [isgood, words_difference] = detect_speech(y, fs, expected_words, show_figure, metronome_status)

if nargin < 4
    show_figure = false;
end

tolerance = floor(expected_words * .2);

%[y, fs] = audioread(fname);

% convert to mono
if size(y, 2) > 1
    y = mean(y, 2);
end


% 1) Nine logarithmically spaced frequency bands between 100 and 10,000 Hz
n_freqs = 9;
log_freq = [logspace(log10(100), log10(10000), n_freqs), fs];
wideband = [];
for i_freq = 1 : n_freqs
    % were constructed by bandpass
    % filtering (third-order, Butterworth filters).
    [b,a] = butter(3, [log_freq(i_freq) log_freq(i_freq+1)-1]/fs, 'bandpass');
    y_filt= filter(b,a,y);
    % 2) Then, we computed the amplitude  envelope for each frequency band as
    % the absolute value of the Hilbert transform
    env = abs(hilbert(y_filt));
    % 3) downsampled them to 1200 Hz.
    new_fs = 1200; % hs
    downsampling_factor = fs/ new_fs;
    env_downsample = downsample(env, downsampling_factor);
    %
    wideband = [wideband, env_downsample];
end
% 4) Finally, we averaged them across bands and used the computed wideband
% amplitude envelope for all further analysis.
wideband = mean(wideband,2);

% We used speech envelope signals to extract syllable pronunciation onsets for
% further trial selection steps.
% 6) First, the envelope signal was low-pass filtered at 5 Hz.
%low = lowpass(wideband,5,fs);
b = fir1(5, 5/fs, 'low');
low = filter(b, 1, wideband);
% 7) Then, we computed the first derivative of the signal
d = diff(low);
% 8) followed by z-scoring.
m = mean(d(new_fs:30*new_fs-new_fs));
sd = std(d(new_fs:30*new_fs-new_fs));
z = (d - m) /sd;

% 9) Finally, we detected all the local peaks that have Z-value higher than 2
if strcmpi(metronome_status, 'on')
    audio_threshold = 2;
else
    audio_threshold = 1;
end
mask = find(z > audio_threshold);

% figure; plot(z); hold on; plot(mask, z(mask), '.')

% remove values that are within the first/last second of recording in that
% they likely contain the audio signal
tokeep = mask > new_fs;% & mask < 36000-1200;
mask = mask(tokeep);

%  Group arrays of consecutive numbers
arr = mask / new_fs;
non_silent_intervals = zeros(0, 2);
start = arr(1);
for i = 2:length(arr)
    if arr(i) - arr(i-1) > 0.06
        non_silent_intervals(end+1, :) = [start, arr(i-1)];
        start = arr(i);
    end
end
non_silent_intervals(end+1, :) = [start, arr(end)];

% Remove interval if it starts at 0
non_silent_intervals = non_silent_intervals(non_silent_intervals(:, 1) ~= 0, :);
% remove interval if it ends after 30s
non_silent_intervals = non_silent_intervals(non_silent_intervals(:, 2) <= 30, :);

% Merge intervals if they are less than 0.5 s apart
for i = 2:size(non_silent_intervals, 1)
    if non_silent_intervals(i, 1) - non_silent_intervals(i-1, 2) < 0.6
        non_silent_intervals(i, 1) = non_silent_intervals(i-1, 1);
        non_silent_intervals(i-1, 2) = non_silent_intervals(i, 2);
    end
end

% Remove duplicates
if length(non_silent_intervals)>0
    non_silent_intervals = non_silent_intervals([true; diff(non_silent_intervals(:, 1)) ~= 0], :);

% Remove segments that are less than 0.1 s
    non_silent_intervals = non_silent_intervals(diff(non_silent_intervals, 1, 2) > 0.01, :);
end

n_words_detected = size(non_silent_intervals, 1);
disp(['Found ' num2str(n_words_detected) ' segments']);


if n_words_detected>=expected_words-tolerance && n_words_detected<=expected_words+tolerance
    isgood = true;
    words_difference = expected_words-n_words_detected;
else
    isgood = false;
    words_difference = expected_words-n_words_detected;
end

if show_figure
    figure; plot(times, y); hold on;
    plot(non_silent_intervals(:, 1), 0, 'r*')
    plot(non_silent_intervals(:, 2), 0, 'g*')
end

end


