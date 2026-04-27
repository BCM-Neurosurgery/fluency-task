function send_event(ptb, cfg, comment, texture)
% send_event  Send a Blackrock comment and/or flash the photodiode.
%
%   send_event(ptb, cfg, comment)           – on text / rest screens
%   send_event(ptb, cfg, comment, texture)  – during noise-background blocks
%
% Blackrock: calls cbmex('comment', ...) directly on each online NSP using
% the handle stored in cfg.onlineNSP (populated by TaskComment('start')
% in fluency_main).  This avoids re-opening the cbmex connection on every
% comment, which would add significant latency.  TaskComment calls are left
% intact and unchanged.
%
% Photodiode: two flips — ON frame (white square) then OFF frame (bg square).
% After returning, the screen shows the noise texture (or plain background).
% Callers on text screens must redraw their text after calling this.

%% ── Blackrock comment via direct cbmex ───────────────────────────────────
if cfg.use_blackrock && isfield(cfg, 'onlineNSP') && ~isempty(cfg.onlineNSP)
    for n = 1 : numel(cfg.onlineNSP)
        try
            cbmex('comment', 16777215, 0, comment, 'instance', cfg.onlineNSP(n) - 1);
        catch brErr
            warning('send_event:cbmex', '%s', brErr.message);
        end
    end
end

%% ── Photodiode flash ─────────────────────────────────────────────────────
if ~cfg.use_photodiode
    return;
end

hasTexture = (nargin >= 4) && ~isempty(texture);

% ON frame: texture (if any) + white diode square
if hasTexture
    Screen('DrawTexture', ptb.window, texture);
end
Screen('FillRect', ptb.window, cfg.colors.diode_on, ptb.diode);
Screen('Flip', ptb.window);

% OFF frame: texture (if any) + background-coloured diode square
if hasTexture
    Screen('DrawTexture', ptb.window, texture);
end
Screen('FillRect', ptb.window, cfg.colors.background, ptb.diode);
Screen('Flip', ptb.window);

end
