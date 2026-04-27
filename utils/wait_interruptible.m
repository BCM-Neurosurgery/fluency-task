function wait_interruptible(ptb, cfg, duration, texture, msg)
% wait_interruptible  Timed wait with pause (P) and kill (Escape) support.
%
% wait_interruptible(ptb, cfg, duration)
%   Waits on a plain grey screen.
%
% wait_interruptible(ptb, cfg, duration, texture, msg)
%   Waits showing noise texture + black center-band + msg text.
%   Pass texture=[] to use a full-screen black banner instead of noise.
%   Pass msg=''  to skip text (just grey or just texture).
%
% On pause (P): shows PAUSED banner, freezes timer, waits for W,
%               then restores whatever screen was showing before the pause.
% On kill (Escape): throws FluencyTask:killed.

if nargin < 4; texture = []; end
if nargin < 5; msg = ''; end

if duration <= 0
    return;
end

t0          = GetSecs();
totalPaused = 0;

while (GetSecs() - t0 - totalPaused) < duration

    [kDown, ~, kCode] = KbCheck(-1);

    if kDown
        %% Kill
        if kCode(ptb.esc_key)
            KbReleaseWait(-1);
            error('FluencyTask:killed', 'Task killed by experimenter (Escape).');
        end

        %% Pause
        if kCode(ptb.pause_key)
            KbReleaseWait(-1);
            pEntry = GetSecs();

            Screen('FillRect', ptb.window, cfg.colors.banner);
            DrawFormattedText(ptb.window, 'PAUSED', 'center', 'center', cfg.colors.text);
            Screen('Flip', ptb.window);

            send_event(ptb, cfg, 'task_pause');

            Screen('FillRect', ptb.window, cfg.colors.banner);
            DrawFormattedText(ptb.window, 'PAUSED', 'center', 'center', cfg.colors.text);
            Screen('Flip', ptb.window);

            fprintf('TASK PAUSED. Press W to resume.\n');
            ptb_waitkey(ptb);

            totalPaused = totalPaused + (GetSecs() - pEntry);
            send_event(ptb, cfg, 'task_resume');

            %% Restore the screen that was showing before the pause
            restore_screen(ptb, cfg, texture, msg);
        end
    end

    WaitSecs(0.005);
end

end

% ── helper ────────────────────────────────────────────────────────────────
function restore_screen(ptb, cfg, texture, msg)
% Redraws the appropriate background after a pause/resume.
hasTexture = ~isempty(texture);
hasMsg     = ~isempty(msg);

if hasTexture
    Screen('DrawTexture', ptb.window, texture);
    if hasMsg
        Screen('FillRect',    ptb.window, cfg.colors.banner, ptb.center_band);
        DrawFormattedText(ptb.window, msg, 'center', 'center', cfg.colors.text);
    end
elseif hasMsg
    Screen('FillRect', ptb.window, cfg.colors.banner);
    DrawFormattedText(ptb.window, msg, 'center', 'center', cfg.colors.text);
else
    Screen('FillRect', ptb.window, cfg.colors.background);
end
Screen('Flip', ptb.window);
end
