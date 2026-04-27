%
% fluency_main.m
%
% Consolidated Fluency Task — semantic fluency and number fluency.
% All runs and blocks execute in a single session controlled by fluency_config.m.
%
% Keys during the task:
%   W      – advance (confirm screen / resume from pause)
%   P      – pause current block
%   Escape – kill task (sends TaskComment kill if use_blackrock is true)
%

%% ── Initialisation ───────────────────────────────────────────────────────
clc; clear;

% Navigate to the directory containing this file
try
    tmp = matlab.desktop.editor.getActive;
    cd(fileparts(tmp.Filename));
catch
end

mainDir = pwd;
addpath(genpath(mainDir));

%% ── Subject ID ───────────────────────────────────────────────────────────
commandwindow;
sub_id = input('Subject ID: ', 's');
if isempty(sub_id)
    error('No subject ID entered.');
end

%% ── Configuration ────────────────────────────────────────────────────────
cfg = fluency_config();

%% ── Output directory ─────────────────────────────────────────────────────
[subjDir, stopExp] = utils_createSubjDir(sub_id, mainDir);
if stopExp; return; end
cfg.subjDir = subjDir;

%% ── PTB initialisation ───────────────────────────────────────────────────
ptb = ptb_init(cfg);

%% ── Sounds ───────────────────────────────────────────────────────────────
stim = make_sounds(cfg);

%% ── Run experiment inside try-catch for safe shutdown ────────────────────
killed = false;
try

    %% Task start marker
    if cfg.use_blackrock
        TaskComment('start', 'fluency');
    end
    fprintf('\n[Fluency Task]  Subject: %s\n', sub_id);

    %% Welcome screen
    DrawFormattedText(ptb.window, ...
        ['Welcome!\n\n' ...
         'You will be asked to name as many items\n' ...
         'from a given category as possible.\n\n' ...
         'Speak clearly and continuously.\n\n' ...
         'Press W to continue.'], ...
        'center', 'center', cfg.colors.text);
    Screen('Flip', ptb.window);
    send_event(ptb, cfg, 'task_start');
    % Redraw after diode flash
    DrawFormattedText(ptb.window, ...
        ['Welcome!\n\n' ...
         'You will be asked to name as many items\n' ...
         'from a given category as possible.\n\n' ...
         'Speak clearly and continuously.\n\n' ...
         'Press W to continue.'], ...
        'center', 'center', cfg.colors.text);
    Screen('Flip', ptb.window);
    ptb_waitkey(ptb);

    %% ── Main run loop ────────────────────────────────────────────────────
    semantic_idx = 0;   % index into cfg.semantic_prompts

    for iRun = 1 : cfg.num_runs

        runType   = cfg.run_types{iRun};
        blockDur  = cfg.block_duration(iRun);
        restDur   = cfg.rest_duration(iRun);

        if strcmp(runType, 'semantic')
            semantic_idx = semantic_idx + 1;
            category     = cfg.semantic_prompts{semantic_idx};
        else
            category = '';
        end

        %% Run start instructions
        if strcmp(runType, 'semantic')
            instrMsg = sprintf( ...
                ['Run %d of %d\n\nCategory:  %s\n\n' ...
                 'Name as many items as you can.\n\n' ...
                 'Press W to begin.'], ...
                iRun, cfg.num_runs, upper(category));
        else
            instrMsg = sprintf( ...
                ['Run %d of %d\n\nNumber Task\n\n' ...
                 'Count from 1 upward, repeat when you reach the end.\n\n' ...
                 'Press W to begin.'], ...
                iRun, cfg.num_runs);
        end

        DrawFormattedText(ptb.window, instrMsg, 'center', 'center', cfg.colors.text);
        Screen('Flip', ptb.window);
        ptb_waitkey(ptb);

        % Run-start event (after key press, before first block)
        if strcmp(runType, 'semantic')
            runComment = sprintf('run_start_r%d_semantic_%s', ...
                iRun, strrep(category, ' ', '_'));
        else
            runComment = sprintf('run_start_r%d_numbers', iRun);
        end
        send_event(ptb, cfg, runComment);
        fprintf('\n  [Run %d/%d] %s', iRun, cfg.num_runs, runType);

        %% ── Block loop ───────────────────────────────────────────────────
        for iBlock = 1 : cfg.num_blocks(iRun)

            useMetronome = cfg.use_metronome{iRun}(iBlock);

            % Fresh noise texture for this block
            texture = make_noise_texture(ptb, cfg);

            %% Block-start instruction screen
            Screen('DrawTexture', ptb.window, texture);
            Screen('FillRect',    ptb.window, cfg.colors.background, ptb.center_band);

            metroLine = '';
            if useMetronome; metroLine = 'Follow the rhythm.'; end
            if strcmp(runType, 'semantic')
                blockMsg = sprintf('Block %d of %d\n\nCategory:  %s\n\n%s', ...
                    iBlock, cfg.num_blocks(iRun), upper(category), metroLine);
            else
                blockMsg = sprintf('Block %d of %d\n\nCount from 1 upward\n\n%s', ...
                    iBlock, cfg.num_blocks(iRun), metroLine);
            end

            DrawFormattedText(ptb.window, blockMsg, 'center', 'center', cfg.colors.text);
            Screen('Flip', ptb.window);
            WaitSecs(3);

            %% Block-start event
            if strcmp(runType, 'semantic')
                blockComment = sprintf('block_start_r%d_b%d_%s', ...
                    iRun, iBlock, strrep(category, ' ', '_'));
            else
                blockComment = sprintf('block_start_r%d_b%d_numbers', iRun, iBlock);
            end
            send_event(ptb, cfg, blockComment, texture);
            fprintf('\n    [Block %d/%d]  metronome=%d', ...
                iBlock, cfg.num_blocks(iRun), useMetronome);

            %% Run the block
            timings              = run_block(ptb, cfg, stim, texture, blockDur, useMetronome);
            timings.run          = iRun;
            timings.block        = iBlock;
            timings.run_type     = runType;
            timings.category     = category;
            timings.use_metronome = useMetronome;
            timings.sub_id       = sub_id;

            %% Block-end event
            send_event(ptb, cfg, sprintf('block_end_r%d_b%d', iRun, iBlock), texture);

            %% Save timings
            outFname = fullfile(subjDir, 'mat', ...
                sprintf('sub-%s_task-fluency_run-%02d_block-%02d_%s_timings.mat', ...
                sub_id, iRun, iBlock, runType));
            save(outFname, 'timings');

            %% Rest between blocks (skip after last block of a run)
            if iBlock < cfg.num_blocks(iRun)
                restMsg = sprintf('Rest\n\n%d seconds', restDur);

                Screen('DrawTexture', ptb.window, texture);
                Screen('FillRect',    ptb.window, cfg.colors.background, ptb.center_band);
                DrawFormattedText(ptb.window, restMsg, 'center', 'center', cfg.colors.text);
                Screen('Flip', ptb.window);

                send_event(ptb, cfg, sprintf('rest_start_r%d_b%d', iRun, iBlock));

                % Redraw rest screen after diode flash
                Screen('DrawTexture', ptb.window, texture);
                Screen('FillRect',    ptb.window, cfg.colors.background, ptb.center_band);
                DrawFormattedText(ptb.window, restMsg, 'center', 'center', cfg.colors.text);
                Screen('Flip', ptb.window);

                WaitSecs(restDur);
            end

            Screen('Close', texture);

        end % iBlock

        %% Run-end event
        send_event(ptb, cfg, sprintf('run_end_r%d', iRun));

        %% Inter-run rest (skip after last run)
        if iRun < cfg.num_runs
            runRestMsg = sprintf( ...
                'Run %d complete.\n\nPlease rest for %d seconds.\n\nThe next run will begin automatically.', ...
                iRun, cfg.run_rest_duration);

            DrawFormattedText(ptb.window, runRestMsg, 'center', 'center', cfg.colors.text);
            Screen('Flip', ptb.window);
            send_event(ptb, cfg, sprintf('run_rest_r%d', iRun));

            DrawFormattedText(ptb.window, runRestMsg, 'center', 'center', cfg.colors.text);
            Screen('Flip', ptb.window);
            WaitSecs(cfg.run_rest_duration);
        end

    end % iRun

    %% ── End screen ───────────────────────────────────────────────────────
    endMsg = 'The experiment is complete!\n\nThank you for your participation.\n\nPress W to exit.';
    DrawFormattedText(ptb.window, endMsg, 'center', 'center', cfg.colors.text);
    Screen('Flip', ptb.window);

    if cfg.use_blackrock
        TaskComment('stop', 'fluency');
    end
    send_event(ptb, cfg, 'task_complete');

    DrawFormattedText(ptb.window, endMsg, 'center', 'center', cfg.colors.text);
    Screen('Flip', ptb.window);
    ptb_waitkey(ptb);

catch ME

    %% ── Error / kill handling ────────────────────────────────────────────
    if strcmp(ME.identifier, 'FluencyTask:killed')
        killed = true;
        fprintf('\n*** Task killed by experimenter. ***\n');
        if cfg.use_blackrock
            try; TaskComment('kill', 'fluency'); catch; end
        end
        try; send_event(ptb, cfg, 'task_kill'); catch; end
    else
        fprintf('\n*** Task error: %s ***\n', ME.message);
        if cfg.use_blackrock
            try; TaskComment('err', 'fluency'); catch; end
        end
        try; send_event(ptb, cfg, 'task_error'); catch; end
    end

end

%% ── Cleanup ──────────────────────────────────────────────────────────────
ptb_close();
if ~killed
    fprintf('\n[Fluency Task]  Session complete.  Data saved to:\n  %s\n', subjDir);
end
