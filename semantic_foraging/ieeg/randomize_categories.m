function trial_order = randomize_categories(opt)
%
% randomize category order
%

assert(length(opt.categories)==2)

nOFF = opt.nBlocksOFF;
time = (1:opt.nBlocks)';
categoriesOFF = [zeros(1,nOFF /2), ones(1,nOFF/2)];
categoriesON = [0, 1]; 

best_score = inf;
best_seq = [];
best_r = NaN;
best_alternations = 0;

for i = 1:1000
    % generate a random sequence based on the metronomeOFF trials
    seq = categoriesOFF(randperm(nOFF ));
    % add the two metronome ON trials
    seq = [categoriesON(randperm(opt.nBlocksON)), seq];
    
    r = corr(time, seq');
    alternations = sum(diff(seq) ~= 0);

    if alternations >= 8
        score = abs(r);

        if score < best_score
            best_score = score;
            best_seq = seq;
            best_r = r;
            best_alternations = alternations;
        end
    end
end

trial_order = best_seq + 1;
trial_order = opt.categories(trial_order);
