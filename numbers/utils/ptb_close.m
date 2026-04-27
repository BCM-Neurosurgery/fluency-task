%
% close psychtoolbox
%

function ptb_close

Screen('CloseAll');
IOPort('CloseAll');
ShowCursor;
fclose('all');
Priority(0);
ListenChar(0);

end