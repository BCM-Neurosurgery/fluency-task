function send_event(ptb, cfg, comment, texture)
% send_event  Send a Blackrock comment and/or flash the photodiode.
%
%   send_event(ptb, cfg, comment)           – text / rest screens
%   send_event(ptb, cfg, comment, texture)  – during noise-background blocks
%
% When cfg.use_photodiode is true the function performs two flips:
%   1. ON  frame: texture (if given) + white diode square
%   2. OFF frame: texture (if given) + background-coloured diode square
% After returning, the screen shows the noise texture (or plain background).
% Callers on text screens should redraw their text after calling this.

%% Blackrock comment
if cfg.use_blackrock
    try
        SendComment(comment);
    catch ME
        warning('send_event:blackrock', '%s', ME.message);
    end
end

%% Photodiode flash
if ~cfg.use_photodiode
    return;
end

hasTexture = (nargin >= 4) && ~isempty(texture);

% ── ON frame ─────────────────────────────────────────────────────────────
if hasTexture
    Screen('DrawTexture', ptb.window, texture);
end
Screen('FillRect', ptb.window, cfg.colors.diode_on, ptb.diode);
Screen('Flip', ptb.window);

% ── OFF frame ────────────────────────────────────────────────────────────
if hasTexture
    Screen('DrawTexture', ptb.window, texture);
end
Screen('FillRect', ptb.window, cfg.colors.background, ptb.diode);
Screen('Flip', ptb.window);

end
