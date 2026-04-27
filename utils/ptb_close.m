function ptb_close()
% ptb_close  Clean up all Psychtoolbox and audio resources.

try; Screen('CloseAll');         catch; end
try; PsychPortAudio('Close');    catch; end
try; ShowCursor;                 catch; end
try; Priority(0);                catch; end
try; ListenChar(0);              catch; end
try; fclose('all');              catch; end

end
