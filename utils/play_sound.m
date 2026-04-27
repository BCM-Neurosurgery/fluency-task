function play_sound(ptb, sound_data)
% play_sound  Play a mono audio vector immediately via PsychPortAudio.
%
% Any currently playing audio is stopped first to avoid overlap.

try
    PsychPortAudio('Stop', ptb.pahandle, 0);
catch
end
PsychPortAudio('FillBuffer', ptb.pahandle, sound_data);
PsychPortAudio('Start',      ptb.pahandle, 1, 0, 0);

end
