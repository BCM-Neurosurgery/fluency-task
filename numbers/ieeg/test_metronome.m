% initialize psychtoolbox
if exist('Screen', 'file') == 0
    run 'C:\toolbox\Psychtoolbox\SetupPsychtoolbox.m'
end


% read the metronome sound
[y, fs]=audioread('C:\Users\milano2\Desktop\genn\ieeg\code\exp\stimuli\metronomeSound.wav');
y=y';

device=1;
pahandle = PsychPortAudio('Open', device, 2, 1, fs, 1);
%PsychPortAudio ('Volume', pahandle, volume);

% get sampling rate
s = PsychPortAudio('GetStatus', pahandle);
% Preallocate an internal audio recording buffer with a capacity of 50 seconds
PsychPortAudio('GetAudioData', pahandle, 50);
% Open the variable for the recorded audio
recordedAudio = [];
% Start audio capture immediately and wait for the capture to start.
% We set the number of 'repetitions' to zero,
% i.e. record until recording is manually stopped.
PsychPortAudio('Start', pahandle, 0, 0, 1);

% present audio
for i = 1 : 14
    sound(y, fs);
    WaitSecs(2 - 1e-2);
end

% stop recording and save
% Stop Audio recording and collect samples
PsychPortAudio('Stop',pahandle);
recordedAudio = transpose(PsychPortAudio('GetAudioData', pahandle));
% save audio file
psychwavwrite(recordedAudio,fs, 'test_metronome.wav');

% plot
figure; hold on
plot(recordedAudio(1, :))
plot(recordedAudio(2, :))
