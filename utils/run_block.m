function timings = run_block(ptb, cfg, stim, texture, blockDuration, useMetronome)
% run_block  Run one recording block and return timing data.
%
% The block displays the noise texture until blockDuration seconds of
% *active* (non-paused) time have elapsed.
%
% Pause:    press P  →  freeze timer, show pause screen, wait for W
% Kill:     press Escape  →  throw FluencyTask:killed
% Metronome (if useMetronome): beep + photodiode every 1/metronome_frequency s

timings          = struct();
timings.pauses   = {};    % cell array of [pauseStart, pauseEnd] pairs
timings.beats    = [];    % absolute timestamps of each metronome beat
timings.blockStart = NaN;
timings.blockEnd   = NaN;

beatInterval = 1 / cfg.metronome_frequency;

%% ── Initial display ──────────────────────────────────────────────────────
Screen('DrawTexture', ptb.window, texture);
Screen('Flip', ptb.window);

%% ── Alert sound at block start ───────────────────────────────────────────
play_sound(ptb, stim.alert_sound);

blockStart = GetSecs();
timings.blockStart = blockStart;

totalPaused  = 0;
% First metronome beat fires after one full interval (not at t=0, which
% is already marked by the alert sound and the block-start send_event).
nextBeatTime = blockStart + beatInterval;

%% ── Timing loop ──────────────────────────────────────────────────────────
while true

    now             = GetSecs();
    effectiveElapsed = (now - blockStart) - totalPaused;

    if effectiveElapsed >= blockDuration
        break;
    end

    %% Check keyboard
    [kDown, ~, kCode] = KbCheck(-1);

    if kDown
        %% Escape → kill
        if kCode(ptb.esc_key)
            KbReleaseWait(-1);
            error('FluencyTask:killed', 'Task killed by experimenter (Escape).');
        end

        %% P → pause
        if kCode(ptb.pause_key)
            KbReleaseWait(-1);
            pauseEntry = GetSecs();

            % Draw pause screen over noise texture
            Screen('DrawTexture', ptb.window, texture);
            Screen('FillRect',    ptb.window, cfg.colors.background, ptb.center_band);
            DrawFormattedText(ptb.window, 'PAUSED\n\nPress W to resume.', ...
                'center', 'center', cfg.colors.text);
            Screen('Flip', ptb.window);

            send_event(ptb, cfg, 'task_pause');

            % Redraw pause screen (send_event may have cleared it)
            Screen('DrawTexture', ptb.window, texture);
            Screen('FillRect',    ptb.window, cfg.colors.background, ptb.center_band);
            DrawFormattedText(ptb.window, 'PAUSED\n\nPress W to resume.', ...
                'center', 'center', cfg.colors.text);
            Screen('Flip', ptb.window);

            ptb_waitkey(ptb);   % blocks until W (or throws on Escape)

            pauseDur    = GetSecs() - pauseEntry;
            totalPaused = totalPaused + pauseDur;
            nextBeatTime = nextBeatTime + pauseDur;   % shift beat schedule

            timings.pauses{end+1} = [pauseEntry, pauseEntry + pauseDur];

            send_event(ptb, cfg, 'task_resume');

            % Restore noise display after event flash
            Screen('DrawTexture', ptb.window, texture);
            Screen('Flip', ptb.window);
        end
    end

    %% Metronome beat
    if useMetronome && GetSecs() >= nextBeatTime
        play_sound(ptb, stim.metronome_sound);
        timings.beats(end+1) = GetSecs();
        send_event(ptb, cfg, 'metronome_proc', texture);
        % send_event restores texture on OFF frame — no extra flip needed
        nextBeatTime = nextBeatTime + beatInterval;
    end

    WaitSecs(0.001);

end % timing loop

timings.blockEnd = GetSecs();

%% Alert sound at block end
play_sound(ptb, stim.alert_sound);

end
