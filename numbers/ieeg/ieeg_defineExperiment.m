%
% create or load experiment sequence
%

function stim = ieeg_defineExperiment(sub_id, ses_id, opt, ptb)

% initialize random number generator
seed = RandStream('mt19937ar', 'Seed', 'shuffle');
RandStream.setGlobalStream(seed);

% check if the file alredy exists, otherwise create it
outFname = fullfile(opt.subjDir, 'mat', sprintf('sub-%s_ses-%s_task-genn_exp.mat', sub_id, ses_id));

if exist(outFname, 'file') == 2
    warning('loading precomputed experiment sequence')
    DrawFormattedText(ptb.window, 'loading precomputed experiment sequence...', 'center', 'center', opt.colors.text);
    Screen('Flip', ptb.window); %re-flip to show what you have drawn
    load(outFname, 'stim')
    % check that the order is consistent
    assert(stim.condition.r1_b1.metronomeFrequency == opt.metronomeFrequency)
else
    disp('creating experiment sequence')
    DrawFormattedText(ptb.window, 'L''esperimento sta per iniziare...', 'center', 'center', opt.colors.text);
    Screen('Flip', ptb.window); %re-flip to show what you have drawn
    % initialize output
    stim = struct();
    
    stim.subid = sub_id;
    stim.datetime = datestr(now);
    
    %% create sounds
    
    stim.audio.sf = opt.fs; % sampling frequency
    
    % periodic metronome signal during the eye-tracker recordings
    metronomeFname = fullfile(opt.mainDir, 'stimuli', 'metronomeSound.wav');
    if exist(metronomeFname, 'file') == 2
        [metronomeSound, sf] = audioread(metronomeFname);
        assert(sf==stim.audio.sf)
    else
        % create sine wave
        freq = 800;
        duration = 0.1;
        nSamples = stim.audio.sf * duration;
        times = (1 : nSamples) / stim.audio.sf;
        sine = sin(2 * pi * freq * times);
        % create taper
        fade_duration = duration  / 10;
        nFade = floor(stim.audio.sf * fade_duration);
        taper = sin(linspace(0, pi/2, nFade));
        taper = [taper, ones(1,nSamples - nFade * 2), fliplr(taper)];
        
        metronomeSound = sine .* taper ;
        % save
        audiowrite(metronomeFname, metronomeSound, stim.audio.sf)
    end
    stim.sounds.metronome=metronomeSound';
    
    % alerting sound
    alertFname = fullfile(opt.mainDir, 'stimuli', 'alertSound.wav');
    if exist(alertFname, 'file') == 2
        [alertSound, sf] = audioread(alertFname);
        assert(sf==stim.audio.sf)
    else
        freq = 1200;
        duration = .15;
        nSamples = floor(stim.audio.sf * duration );
        times = (1:nSamples) / stim.audio.sf;
        sine = sin(2 * pi * freq * times);
        fade_duration = duration / 40;
        nFade = floor(stim.audio.sf * fade_duration);
        taper = sin(linspace(0,pi/2, nFade));
        taper = [taper, ones(1,nSamples - nFade * 2), fliplr(taper)];
        
        alertSound = sine .* taper;
        % save
        audiowrite(alertFname, alertSound, stim.audio.sf)
    end
    stim.sounds.alert = alertSound';
    
    
    % create metronome sequence
    
    % define the time axis of this sequence
    times = (1:stim.audio.sf*opt.blockDuration)/stim.audio.sf;
    metronomeTime = opt.metronomeTime;
    nRepetitions = opt.expectedWordsPerBlock-1;
    
    % create an array of zeros covering the trial duration at the sampling
    % rate of the audio
    metronomeSequence = zeros(1, stim.audio.sf*opt.blockDuration);
    % define the times at which the metronome should start
    metronomeOnset = repmat(metronomeTime, [1, nRepetitions]).*(1:nRepetitions);
    % add the metronome sound starting from these indices
    for iTimes = 1 : length(metronomeOnset)
        % find the indices of the onset of the metronome in the times array
        [~, ind] = min(abs(times - metronomeOnset(iTimes)), [], 2);
        metronomeSequence(1, ind-1:ind+length(metronomeSound)-2) = metronomeSound;
    end
    
    % add the alerting sound at the beginning and end of the sequence
    metronomeSequence(1:length(alertSound)) = alertSound;
    metronomeSequence = [metronomeSequence alertSound'];
    
    %plot(metronomeSequence)
    
    % store the sequence
    stim.metronomeSequence = metronomeSequence;
    
    % create the sequence without the metronome, to play the starting
    % end ending sounds
    alertingSequence = zeros(1, stim.audio.sf*opt.blockDuration);
    alertingSequence(1:length(alertSound)) = alertSound;
    alertingSequence = [alertingSequence alertSound'];
    stim.alertingSequence =  alertingSequence;
    
    %% create or load visual noise patches and assign them to different trials
    % based on Sahan 2022
    patchName = fullfile(opt.mainDir, 'stimuli', ...
        sprintf('noisePatches_size%sx%s_%sdeg.mat',...
        num2str(ptb.screen_resolution(1)), num2str(ptb.screen_resolution(2)), ...
        num2str(opt.noisePatchDeg)));
    
    if exist(patchName, 'file')
        load(patchName, 'noisePatches')
    else
        % calculate how many patches of given size are needed
        nPatches = ptb.screen_resolution ./ ptb.noisePatchSizePx;
        % if screen resolution is less than 1000 px we are likely using a
        % small screen, so debugging
        if all(ptb.screen_resolution < 1000)
            nPatches = floor(nPatches);
            warning('rounding number of patches')
        end
        % create them
        noisePatches = [];
        iPatches = 0;
        tic
        while iPatches < opt.nPatches
            % random color for each patch
            noisePatch=squeeze(randi(255, 1, round(nPatches(1)), round(nPatches(2))));
            % check that the average color is the same of the background
            if mean(mean(noisePatch)) == opt.colors.background(1)
                noisePatches(iPatches+1, :, :) = noisePatch;
                iPatches = iPatches+1;
            end
        end
        toc
        
        % check that they are different from each other
        for iPatch = 1 : opt.nPatches
            isSame(iPatch)=all(arrayfun(@(i) all(all(squeeze(noisePatches(i, :, :)) - squeeze(noisePatches(iPatch, :,:)) == 0)), setdiff(1:opt.nPatches, iPatch)));
        end
        assert(~all(isSame))
        
        save(patchName, 'noisePatches')
    end
    
    % randomize the order of the presentation of the blocks
    noisePatches = noisePatches(randperm(opt.nPatches), :, :);
    
    % store in the stim structure the final conditions order
    % storing for each block the id of the run and block within run, followed
    % by metronome frequency and status
    blockArray = repmat(1 :  opt.nBlocksxRun, [1, opt.nRuns]);
    runArray = repmat(1 : opt.nRuns, [1, opt.nBlocksxRun]);
    frequencyArray = repmat(opt.metronomeFrequency, [1, opt.nBlocks]);
    expectedArray = repmat(opt.expectedWordsPerBlock, [1, opt.nBlocks]);
    metronomeStatus = repmat(...
        [repmat({'ON'}, [1, opt.nBlocksON]) , repmat({'OFF'}, [1, opt.nBlocksOFF])], [1, opt.nRuns]);
    
    counter = 1;
    for iRun = 1:opt.nRuns
        for iBlock = 1 : opt.nBlocksxRun
            stim.condition.(sprintf('r%i_b%i', iRun, iBlock)).block = blockArray(counter);
            stim.condition.(sprintf('r%i_b%i', iRun, iBlock)).run = runArray(counter);
            stim.condition.(sprintf('r%i_b%i', iRun, iBlock)).metronomeFrequency = frequencyArray(counter);
            stim.condition.(sprintf('r%i_b%i', iRun, iBlock)).metronomeStatus = metronomeStatus{counter};
            stim.condition.(sprintf('r%i_b%i', iRun, iBlock)).expectedWordsN = expectedArray(counter);
            stim.condition.(sprintf('r%i_b%i', iRun, iBlock)).noisePatches = ...
                kron(squeeze(noisePatches(counter, :, :)), ones(ptb.noisePatchSizePx(1)))';
            %repelem(squeeze(noisePatches(counter, :, :)), ptb.noisePatchSizePx(1), ptb.noisePatchSizePx(2))';
            % replicate to match the size of the screen
            counter = counter+1;
        end
    end
    
    %% create control trials
    trans_lim = opt.n_positions-1;
    A = [-trans_lim:-1 1:trans_lim];
    % in which we present dots at different positions on the screen
    trans_fname = sprintf('%s/stimuli/control_transitions.mat', opt.mainDir);
    if exist(trans_fname, 'file')==2
        load(trans_fname, 'start_pos', 'transitions')
    else
        % generate transitions
        start_pos = [];
        transitions = [];
        k = 1;
        for i_perm = 1 : 10000000
            % randomize transition order
            rand_trans = datasample(A, opt.expectedWordsPerBlock-1, 'Replace', false);
            % get a random starting position
            for rand_start =  1 : opt.n_positions
                % compute the transitions based on the starting position
                seq = cumsum([rand_start rand_trans]);
                % check whether the starting position and the sequence are compatible, ie.
                % they dont exceed the bounds
                if all(seq <= opt.n_positions & seq >= 1)
                    start_pos(k, 1) = rand_start;
                    transitions(k, :) = rand_trans;
                    k = k+1;
                end
            end
        end
        save(trans_fname, 'start_pos', 'transitions')
    end
    
    % randomly select sequences from this list
    while true
        
        % get n_positions random indices, n_starting for each position
        rand_ind = arrayfun(@(x) datasample(find(start_pos==x), opt.n_starting(x, 2)), ...
            1:opt.n_positions, 'UniformOutput', false);
        
        % Concatenate random indices into a single array
        rand_ind = cat(2, rand_ind{:});
        
        % count occurrences of transitions
        trans_counts = histc(transitions(rand_ind, :), A);
        
        % sum over iterations
        trans_counts = sum(trans_counts, 2);
        
        if all(trans_counts >= 5 & trans_counts <= 9)
            break
        end
    end
    
    final_start = start_pos(rand_ind, 1);
    final_trans = transitions(rand_ind, :);
    
    % define the x positions on the screen, to present dots in the control
    x_diff=floor(ptb.screen_resolution(1)/(opt.n_positions+1));
    x_positions=x_diff:x_diff:ptb.screen_resolution(1);
    x_positions = x_positions(1:end-1);
    %assert(x_positions(end)+x_diff==ptb.screen_resolutions(1))
    assert(length(x_positions)==opt.n_positions)
    
    %     %% plot final distribution
%         figure
%         subplot(1,2,1)
%         counts = histcounts(cumsum([final_start, final_trans], 2));
%         bar(1:opt.n_positions, counts)
%         xlabel('Positions')
%         ylabel('Counts')
%         title('Absolute positions distribution')
%     
%         subplot(1,2,2)
%         counts = histcounts(final_trans);
%         % remove zero
%         bar(sort([A 0]), counts)
%         xlabel('Transitions')
%         ylabel('Counts')
%         title('Transitions distribution')
%     
    % assign control transitions to stim structure
    counter = 1;
    for iRun = 1 : opt.nControlRuns
        for iBlock = 1 : opt.nControlBlocksxRun
            stim.condition.(sprintf('r%i_control%i', iRun, iBlock)).block = iRun;
            stim.condition.(sprintf('r%i_control%i', iRun, iBlock)).run = iBlock;
            stim.condition.(sprintf('r%i_control%i', iRun, iBlock)).start_pos = ...
                final_start(counter,1);
            stim.condition.(sprintf('r%i_control%i', iRun, iBlock)).transitions = ...
                final_trans(counter,:);
            
            sequence_ind = cumsum([final_start(counter,1), final_trans(counter,:)]);
            
            stim.condition.(sprintf('r%i_control%i', iRun, iBlock)).sequence_ind = ...
                sequence_ind;
            stim.condition.(sprintf('r%i_control%i', iRun, iBlock)).sequence_pos = ...
                x_positions(sequence_ind);
            stim.condition.(sprintf('r%i_control%i', iRun, iBlock)).jitter = ...
                unifrnd(0, opt.jitter, length(sequence_ind));
            counter = counter+1;
        end
    end
    
    %% save
    save(outFname, 'stim', 'opt', 'ptb')
    
end

% make textures
for iRun = 1 : opt.nRuns
    for iBlock = 1 : opt.nBlocksxRun
        stim.condition.(sprintf('r%i_b%i', iRun, iBlock)).texture = ...
            Screen('MakeTexture', ptb.window, stim.condition.(sprintf('r%i_b%i', iRun, iBlock)).noisePatches);
    end
end

end