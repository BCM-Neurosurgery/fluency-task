function timings = run_block(ptb, cfg, stim, texture, blockDuration, useMetronome)
% run_block  Run one recording block and return timing data.
%
% The block displays the noise texture until blockDuration seconds of
% *active* (non-paused) time have elapsed.
%
%   P      → freeze timer, show full-screen PAUSED banner, wait for W
%   Escape → throw FluencyTask:killed
%   Metronome (if useMetronome): beep + photodiode every 1/metronome_frequency s

timings            = struct();
timings.pauses     = {};
timings.beats      = [];
timings.blockStart = GetSecs();
timings.blockEnd   = NaN;

beatInterval = 1 / cfg.metronome_frequency;

%% ── Initial display ──────────────────────────────────────────────────────
Screen('DrawTexture', ptb.window, texture);
Screen('Flip', ptb.window);

%% ── Alert sound at block start ───────────────────────────────────────────
play_sound(ptb, stim.alert_sound);

blockStart = timings.blockStart;
% timings.blockStart = blockStart;
totalPaused  = 0;
nextBeatTime = blockStart + beatInterval;

%% ── Timing loop ──────────────────────────────────────────────────────────
while true

    now              = GetSecs();
    effectiveElapsed = (now - blockStart) - totalPaused;

    if effectiveElapsed >= blockDuration
        break;
    end

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

            % Full-screen black PAUSED banner (no "Press W" on screen)
            Screen('FillRect',    ptb.window, cfg.colors.banner);
            DrawFormattedText(ptb.window, 'PAUSED', 'center', 'center', cfg.colors.text);
            Screen('Flip', ptb.window);

            send_event(ptb, cfg, 'task_pause');

            Screen('FillRect',    ptb.window, cfg.colors.banner);
            DrawFormattedText(ptb.window, 'PAUSED', 'center', 'center', cfg.colors.text);
            Screen('Flip', ptb.window);

            fprintf('TASK PAUSED. Press W to resume.\n');
            ptb_waitkey(ptb);

            pauseDur    = GetSecs() - pauseEntry;
            totalPaused = totalPaused + pauseDur;
            nextBeatTime = nextBeatTime + pauseDur;

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
        nextBeatTime = nextBeatTime + beatInterval;
    end

    WaitSecs(0.001);

end % timing loop

timings.blockEnd = GetSecs();

%% ── Alert sound at block end ─────────────────────────────────────────────
play_sound(ptb, stim.alert_sound);

end
