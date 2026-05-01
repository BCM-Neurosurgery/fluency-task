%
% fluency_main.m
%
% Consolidated Fluency Task — semantic fluency and number fluency.
% All runs and blocks execute in a single session controlled by fluency_config.m.
%
% Experimenter keys (all handled at every point in the task):
%   W      – advance / confirm
%   P      – pause (timer freezes; screen shows PAUSED; W resumes)
%   Escape – kill task immediately (sends TaskComment kill)
%
% "Press W" instructions are shown only in the terminal, never on screen.
%

%% ── Initialisation ───────────────────────────────────────────────────────
clc; clear;

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

assert(numel(cfg.run_rest_duration) == cfg.num_runs - 1, ...
    'cfg.run_rest_duration must have %d entries (num_runs - 1).', cfg.num_runs - 1);

%% ── Timestamped output directory ─────────────────────────────────────────
timestamp   = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
sessionName = sprintf('fluency_%s', timestamp);
subjDir     = fullfile(cfg.data_dir, sub_id, 'fluency', sessionName);
matDir      = fullfile(subjDir, 'mat');
if ~exist(matDir, 'dir'); mkdir(matDir); end
fprintf('Session data → %s\n', subjDir);

%% ── PTB initialisation ───────────────────────────────────────────────────
ptb = ptb_init(cfg);

%% ── Sounds ───────────────────────────────────────────────────────────────
stim = make_sounds(cfg);

%% ── NSP handle initialised before try block ─────────────────────────────
cfg.onlineNSP = [];

%% ── Run experiment ───────────────────────────────────────────────────────
killed = false;
try

    %% Task start — open Blackrock, capture NSP handles once
    if cfg.use_blackrock
        try
            cfg.onlineNSP = TaskComment('start', sprintf('sub%s_fluency', sub_id));
        catch brErr
            warning('fluency:blackrock', '%s', brErr.message);
        end
    end
    fprintf('[Fluency Task]  Subject: %s   Session: %s\n', sub_id, sessionName);

    %% Welcome screen
    Screen('FillRect', ptb.window, cfg.colors.banner);
    DrawFormattedText(ptb.window, ...
        ['Welcome!\n\n' ...
         'You will be asked to name as many items\n' ...
         'from a given category as possible.\n\n' ...
         'Speak clearly and continuously.'], ...
        'center', 'center', cfg.colors.text);
    Screen('Flip', ptb.window);
    send_event(ptb, cfg, 'task_start');
    Screen('FillRect', ptb.window, cfg.colors.banner);
    DrawFormattedText(ptb.window, ...
        ['Welcome!\n\n' ...
         'You will be asked to name as many items\n' ...
         'from a given category as possible.\n\n' ...
         'Speak clearly and continuously.'], ...
        'center', 'center', cfg.colors.text);
    Screen('Flip', ptb.window);
    fprintf('Press W to begin.\n');
    ptb_waitkey(ptb);

    %% ── Main run loop ────────────────────────────────────────────────────
    semantic_idx = 0;

    for iRun = 1 : cfg.num_runs

        runType  = cfg.run_types{iRun};
        blockDur = cfg.block_duration(iRun);
        restDur  = cfg.rest_duration(iRun);

        if strcmp(runType, 'semantic')
            semantic_idx = semantic_idx + 1;
            category     = cfg.semantic_prompts{semantic_idx};
        else
            category = '';
        end

        %% Run start screen — always requires W (between every run)
        if strcmp(runType, 'semantic')
            runInstrMsg = sprintf( ...
                ['Run %d of %d\n\nCategory:  %s\n\n' ...
                 'Name as many items as you can.\n' ...
                 'Try to keep pace with the metronome when it plays.'], ...
                iRun, cfg.num_runs, upper(category));
        else
            runInstrMsg = sprintf( ...
                ['Run %d of %d\n\nNumber Task\n\n' ...
                 'Randomly say numbers between 1 and 20\n' ...
                 'at the same pace as the metronome.\n' ...
                 'Avoid repeating the same number twice in a row.'], ...
                iRun, cfg.num_runs);
        end

        Screen('FillRect', ptb.window, cfg.colors.banner);
        DrawFormattedText(ptb.window, runInstrMsg, 'center', 'center', cfg.colors.text);
        Screen('Flip', ptb.window);
        fprintf('\n[Run %d/%d %s]  Press W to begin.\n', iRun, cfg.num_runs, runType);
        ptb_waitkey(ptb);

        if strcmp(runType, 'semantic')
            runComment = sprintf('run_start_r%d_semantic_%s', iRun, strrep(category, ' ', '_'));
        else
            runComment = sprintf('run_start_r%d_numbers', iRun);
        end
        send_event(ptb, cfg, runComment);

        %% ── Block loop ───────────────────────────────────────────────────
        for iBlock = 1 : cfg.num_blocks(iRun)

            useMetronome = cfg.use_metronome{iRun}(iBlock);
            texture      = make_noise_texture(ptb, cfg);

            if cfg.require_key_between_blocks
                %% Block info screen (no "Press W" text) — wait for W
                metroLine = '';
                if useMetronome; metroLine = '\nFollow the metronome rhythm.'; end

                if strcmp(runType, 'semantic')
                    blockMsg = sprintf( ...
                        ['Block %d of %d\n\nCategory:  %s\n\n' ...
                         'Name as many items as you can.%s'], ...
                        iBlock, cfg.num_blocks(iRun), upper(category), metroLine);
                else
                    blockMsg = sprintf( ...
                        ['Block %d of %d\n\nNumber Task\n\n' ...
                         'Say random numbers 1-20 at the metronome pace.%s'], ...
                        iBlock, cfg.num_blocks(iRun), metroLine);
                end

                Screen('DrawTexture', ptb.window, texture);
                Screen('FillRect',    ptb.window, cfg.colors.banner, ptb.center_band);
                DrawFormattedText(ptb.window, blockMsg, 'center', 'center', cfg.colors.text);
                Screen('Flip', ptb.window);
                fprintf('  [Block %d/%d]  Press W to begin.\n', iBlock, cfg.num_blocks(iRun));
                ptb_waitkey(ptb);

            else
                %% Automatic start — show noise texture and go
                Screen('DrawTexture', ptb.window, texture);
                Screen('Flip', ptb.window);
                fprintf('  [Block %d/%d]  Starting...\n', iBlock, cfg.num_blocks(iRun));
            end

            %% Block-start event
            if strcmp(runType, 'semantic')
                blockComment = sprintf('block_start_r%d_b%d_%s', ...
                    iRun, iBlock, strrep(category, ' ', '_'));
            else
                blockComment = sprintf('block_start_r%d_b%d_numbers', iRun, iBlock);
            end
            send_event(ptb, cfg, blockComment, texture);

            %% Run the block
            timings               = run_block(ptb, cfg, stim, texture, blockDur, useMetronome);
            timings.run           = iRun;
            timings.block         = iBlock;
            timings.run_type      = runType;
            timings.category      = category;
            timings.use_metronome = useMetronome;
            timings.sub_id        = sub_id;
            timings.session       = sessionName;

            %% Block-end event + save (all IO after block, none during)
            send_event(ptb, cfg, sprintf('block_end_r%d_b%d', iRun, iBlock), texture);
            outFname = fullfile(matDir, ...
                sprintf('sub-%s_task-fluency_run-%02d_block-%02d_%s_timings.mat', ...
                sub_id, iRun, iBlock, runType));
            save(outFname, 'timings');

            %% Rest between blocks — interruptible, skip after last block
            if iBlock < cfg.num_blocks(iRun)
                show_rest_screen(ptb, cfg, texture, restDur, iRun, iBlock);
            end

            Screen('Close', texture);

        end % iBlock

        %% Run-end event
        send_event(ptb, cfg, sprintf('run_end_r%d', iRun));

        %% Inter-run rest — noise + instructions, interruptible
        if iRun < cfg.num_runs
            thisRunRest = cfg.run_rest_duration(iRun);
            restMsg     = sprintf('Run %d of %d complete  —  %d s rest\n\n%s', ...
                iRun, cfg.num_runs, thisRunRest, rest_instructions());

            % Generate a fresh noise texture for the inter-run rest
            restTexture = make_noise_texture(ptb, cfg);

            Screen('DrawTexture', ptb.window, restTexture);
            Screen('FillRect',    ptb.window, cfg.colors.banner, ptb.center_band);
            DrawFormattedText(ptb.window, restMsg, 'center', 'center', cfg.colors.text);
            Screen('Flip', ptb.window);
            send_event(ptb, cfg, sprintf('run_rest_r%d', iRun), restTexture);
            Screen('DrawTexture', ptb.window, restTexture);
            Screen('FillRect',    ptb.window, cfg.colors.banner, ptb.center_band);
            DrawFormattedText(ptb.window, restMsg, 'center', 'center', cfg.colors.text);
            Screen('Flip', ptb.window);

            % Text phase: first 5 s (pause → restores noise + text)
            wait_interruptible(ptb, cfg, min(5, thisRunRest), restTexture, restMsg);

            % Static phase: remainder (pause → restores just noise)
            if thisRunRest > 5
                Screen('DrawTexture', ptb.window, restTexture);
                Screen('Flip', ptb.window);
                wait_interruptible(ptb, cfg, thisRunRest - 5, restTexture);
            end

            Screen('Close', restTexture);
        end

    end % iRun

    %% ── End screen ───────────────────────────────────────────────────────
    Screen('FillRect', ptb.window, cfg.colors.banner);
    DrawFormattedText(ptb.window, ...
        'The experiment is complete!\n\nThank you for your participation.', ...
        'center', 'center', cfg.colors.text);
    Screen('Flip', ptb.window);

    if cfg.use_blackrock
        try; TaskComment('stop', sprintf('sub%s_fluency', sub_id)); catch; end
    end
    send_event(ptb, cfg, 'task_complete');
    Screen('FillRect', ptb.window, cfg.colors.banner);
    DrawFormattedText(ptb.window, ...
        'The experiment is complete!\n\nThank you for your participation.', ...
        'center', 'center', cfg.colors.text);
    Screen('Flip', ptb.window);
    fprintf('Task complete. Press W to exit.\n');
    ptb_waitkey(ptb);

catch ME

    %% ── Error / kill handling ────────────────────────────────────────────
    if strcmp(ME.identifier, 'FluencyTask:killed')
        killed = true;
        fprintf('\n*** Task killed by experimenter. ***\n');
        if cfg.use_blackrock
            try; TaskComment('kill', sprintf('sub%s_fluency', sub_id)); catch; end
        end
        try; send_event(ptb, cfg, 'task_kill'); catch; end
    else
        fprintf('\n*** Task error: %s ***\n', ME.message);
        if cfg.use_blackrock
            try; TaskComment('error', sprintf('sub%s_fluency', sub_id)); catch; end
        end
        try; send_event(ptb, cfg, 'task_error'); catch; end
    end

end

%% ── Cleanup ──────────────────────────────────────────────────────────────
ptb_close();
fprintf('Session saved to: %s\n', subjDir);


%% ── Local helpers ────────────────────────────────────────────────────────
function show_rest_screen(ptb, cfg, texture, restDur, iRun, iBlock)
% Display rest screen: text banner for 5 s then pure noise static.
% Fully interruptible at all times (P = pause, Escape = kill).
restMsg = sprintf('Block %d of %d complete  —  %d s rest\n\n%s', ...
    iBlock, cfg.num_blocks(iRun), restDur, rest_instructions());

Screen('DrawTexture', ptb.window, texture);
Screen('FillRect',    ptb.window, cfg.colors.banner, ptb.center_band);
DrawFormattedText(ptb.window, restMsg, 'center', 'center', cfg.colors.text);
Screen('Flip', ptb.window);

send_event(ptb, cfg, sprintf('rest_start_r%d_b%d', iRun, iBlock), texture);

Screen('DrawTexture', ptb.window, texture);
Screen('FillRect',    ptb.window, cfg.colors.banner, ptb.center_band);
DrawFormattedText(ptb.window, restMsg, 'center', 'center', cfg.colors.text);
Screen('Flip', ptb.window);

% Text phase: first 5 s (pause → restores noise + text)
wait_interruptible(ptb, cfg, min(5, restDur), texture, restMsg);

% Static phase: remainder (pause → restores just noise)
if restDur > 5
    Screen('DrawTexture', ptb.window, texture);
    Screen('Flip', ptb.window);
    wait_interruptible(ptb, cfg, restDur - 5, texture);
end
end

function msg = rest_instructions()
msg = ['Please stay still\n' ...
       'Keep your eyes on the screen\n' ...
       'and try not to speak'];
end
