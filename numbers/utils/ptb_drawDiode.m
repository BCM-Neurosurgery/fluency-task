%
% draw photodiode square
%

function ptb_drawDiode(ptb, flip, color)

% draw white diode, so there will be a bigger constrast when
% the trial starts
Screen('FillRect', ptb.window, color, ptb.diode);

if flip
    Screen('Flip', ptb.window); %re-flip to show what you have drawn
end

end