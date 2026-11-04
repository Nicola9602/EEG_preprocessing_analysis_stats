% Chinchella Nicola MRG 2025 
% This code generates a csv with a trial count summary table per subject
% whre its informations about - Share/No Share by Fake/True are saved. 
% This is needed to afterwards select subjects for further processing.
%
% !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% % IMPORTANT = this code always OVERWRITES the output file, so if you
% process only one participant the output file will hold only one
% participant. Always batch process all participants here!!
% 
% 
%% Set up
code = 'experiment';
[Path, Params, Triggers] = MI_00_Setup(code);

% Initialize fieldtrip
try
    ft_defaults;
catch
    addpath(Path.fieldtrip);
    ft_defaults;
end

subject = select_subject(Path.raw_eeg, 'multiple');

% Counting trials
% Counting empty trials
empty_trials = {};
% counting non empty trials 
non_empty_trials = {};

%% Count trials for each subject and condition
for sj = 1:length(subject)
    try
        load(fullfile(Path.segmented, [Params.experiment_name, subject{sj}, '_segmented_misinformation.mat']), 'misinformation');
        
        % Separate trials by fake/true and share/no share
        % Column 1: fake (100, 200) vs true (300, 400)
        % Column 2: no share (100) vs share (not 100)
        
        % Share with fake: fake news (100 or 200) AND share (not 100)
        share_with_fake_idx = find(ismember(misinformation.trialinfo(:, 1), [100, 200]) & ...
                                    misinformation.trialinfo(:, 2) ~= 100);
        
        % No share with fake: fake news (100 or 200) AND no share (100)
        no_share_with_fake_idx = find(ismember(misinformation.trialinfo(:, 1), [100, 200]) & ...
                                       misinformation.trialinfo(:, 2) == 100);
        
        % Share with true: true news (300 or 400) AND share (not 100)
        share_with_true_idx = find(ismember(misinformation.trialinfo(:, 1), [300, 400]) & ...
                                    misinformation.trialinfo(:, 2) ~= 100);
        
        % No share with true: true news (300 or 400) AND no share (100)
        no_share_with_true_idx = find(ismember(misinformation.trialinfo(:, 1), [300, 400]) & ...
                                       misinformation.trialinfo(:, 2) == 100);
        
        % Print trial counts for quality check
        %fprintf('Subject %s:\n', subject{sj});
        %fprintf('  Share with fake: %d trials\n', length(share_with_fake_idx));
        %fprintf('  No share with fake: %d trials\n', length(no_share_with_fake_idx));
        %fprintf('  Share with true: %d trials\n', length(share_with_true_idx));
        %fprintf('  No share with true: %d trials\n', length(no_share_with_true_idx));
        
        % Record trial counts
        % Share with fake
        if ~isempty(share_with_fake_idx)
            non_empty_trials(end+1, :) = {subject{sj}, 'share_with_fake', length(share_with_fake_idx)};
        else
            empty_trials(end+1, :) = {subject{sj}, 'share_with_fake'};
        end
        
        % No share with fake
        if ~isempty(no_share_with_fake_idx)
            non_empty_trials(end+1, :) = {subject{sj}, 'no_share_with_fake', length(no_share_with_fake_idx)};
        else
            empty_trials(end+1, :) = {subject{sj}, 'no_share_with_fake'};
        end
        
        % Share with true
        if ~isempty(share_with_true_idx)
            non_empty_trials(end+1, :) = {subject{sj}, 'share_with_true', length(share_with_true_idx)};
        else
            empty_trials(end+1, :) = {subject{sj}, 'share_with_true'};
        end
        
        % No share with true
        if ~isempty(no_share_with_true_idx)
            non_empty_trials(end+1, :) = {subject{sj}, 'no_share_with_true', length(no_share_with_true_idx)};
        else
            empty_trials(end+1, :) = {subject{sj}, 'no_share_with_true'};
        end
        
    catch ME
        fprintf('Error processing participant %s: %s\n', subject{sj}, ME.message);
        continue;
    end
end

%% Print summary and create table
% Print summary of non-empty trials
fprintf('\n========== NON-EMPTY TRIALS SUMMARY ==========\n');
if ~isempty(non_empty_trials)
    fprintf('Subject ID\t\tCondition\t\t\tTrial Count\n');
    fprintf('-----------------------------------------------------------\n');
    for i = 1:size(non_empty_trials, 1)
        fprintf('%s\t\t%s\t\t%d\n', non_empty_trials{i, 1}, non_empty_trials{i, 2}, non_empty_trials{i, 3});
    end
    
    % Convert to table format with conditions as columns
    % Get unique subjects
    unique_subjects = unique(non_empty_trials(:, 1));
    
    % Initialize columns
    share_with_fake = nan(length(unique_subjects), 1);
    no_share_with_fake = nan(length(unique_subjects), 1);
    share_with_true = nan(length(unique_subjects), 1);
    no_share_with_true = nan(length(unique_subjects), 1);
    
    % Fill in trial counts for each subject and condition
    for i = 1:size(non_empty_trials, 1)
        subj_idx = find(strcmp(unique_subjects, non_empty_trials{i, 1}));
        condition = non_empty_trials{i, 2};
        count = non_empty_trials{i, 3};
        
        switch condition
            case 'share_with_fake'
                share_with_fake(subj_idx) = count;
            case 'no_share_with_fake'
                no_share_with_fake(subj_idx) = count;
            case 'share_with_true'
                share_with_true(subj_idx) = count;
            case 'no_share_with_true'
                no_share_with_true(subj_idx) = count;
        end
    end
    
    % Create table
    trial_count_table = table(unique_subjects, share_with_fake, no_share_with_fake, ...
                              share_with_true, no_share_with_true, ...
                              'VariableNames', {'Subject_ID', 'Share_Fake', 'NoShare_Fake', ...
                                                'Share_True', 'NoShare_True'});
    
    % Save to Excel
    excel_filename = fullfile(Path.ERP, 'trial_counts_summary.xlsx');
    writetable(trial_count_table, excel_filename, 'WriteMode', 'overwrite');
    fprintf('\nTrial counts exported to: %s\n', excel_filename);
    
else
    fprintf('No valid trials found across all participants.\n');
end
fprintf('==============================================\n\n');

% Print empty trials summary if any
if ~isempty(empty_trials)
    fprintf('\n========== EMPTY TRIALS SUMMARY ==========\n');
    fprintf('Subject ID\t\tCondition\n');
    fprintf('-------------------------------------------\n');
    for i = 1:size(empty_trials, 1)
        fprintf('%s\t\t%s\n', empty_trials{i, 1}, empty_trials{i, 2});
    end
    fprintf('==========================================\n\n');
end
