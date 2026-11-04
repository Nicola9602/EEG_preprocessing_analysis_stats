% Chinchella Nicola 2026 MRG Group
% 3-channel version: Fz, FCz, Cz

%{
SCRIPT DESCRIPTION
==================
This script extracts trial-level theta power for all subjects in the
misinformation task.

----------------------------------------------
One theta power value per trial
Time window: 0.3–0.75 s
Frequency: 4–8 Hz
Channels: separate values for Fz, FCz, Cz
Baseline: -1 to -0.5 s, dB corrected
Level: trial-level
Output: CSV table
-----------------------------------------------

Each row of the final output corresponds to one trial from one participant.

The script computes time-frequency power separately for three frontal/midline
channels:

    Fz
    FCz
    Cz

It does not average across channels.

The final CSV contains one power value per trial for each channel.

OUTPUT TABLE
------------
The script creates a table called AllTrials with the following columns:

    Subject
    Trial_type
    Response
    Feedback
    RT
    Power_Fz
    Power_FCz
    Power_Cz

FILES SAVED
-----------
The script saves:

    AllSubjects_misinformation_trials_3Channels4_8_03_075_5Morlet_focusedNaNs.csv
    NaN_removal_comparison_3Channels4_8_03_075_5Morlet.csv
    AllSubjects_misinformation_trials_3Channels_info4_8_03_075_5MorletfocusedNaNs.mat
    channels.txt

ANALYSIS LEVEL
--------------
Trial-level output.

This script does not save grand averages and does not average across channels.
%}

clear

code = 'experiment';
analysis = 'misinformation_theta';

addpath(genpath('C:\Users\nicola.chinchella2\Desktop\PHD BOLOGNA\Study\MRG\EEG preprocessing and analysis\Misinformation'))

[Path, Params] = NI_00_Setup_analysis(code, analysis);

load(Params.layout)

%% Initialize FieldTrip

try
    ft_defaults;
catch
    addpath(Path.fieldtrip);
    ft_defaults;
end

%% NaN rejection strategy

% 'general' = reject trial if any NaN exists anywhere in the trial
% 'focused' = reject trial only if NaNs are in required channels/time windows
nan_rejection_mode = 'focused';  % options: 'general' or 'focused'

% Required post-stimulus theta window
theta_windows = [0.0, 0.75; 0.0 0.5; 0.5, 0.75; 0.4, 0.75];
 

morlet_widths = [4];

%% Channels of interest: 3-channel version

channels_of_interest = {'Fz', 'FCz', 'Cz'};


subject = select_subject(Path.raw_eeg, 'multiple');
%% Loop over windows and morlet widths 

for tw = 1:size(theta_windows, 1)

    theta_latency = theta_windows(tw, :);
    theta_codes = arrayfun(@(x) strrep(sprintf('%.3g', x), '.', ''), ...
                       theta_latency, ...
                       'UniformOutput', false);

for mw = 1:length(morlet_widths)
    morlet_width = morlet_widths(mw);

%% Initialize logs

missing_segmented_files = {};
failed_subjects = {};
missing_channel_subjects = {};




%% Create empty output table

AllTrials = table('Size', [0 8], ...
    'VariableTypes', ["string", "double", "double", "double", "double", ...
                      "double", "double", "double"], ...
    'VariableNames', {'Subject', 'Trial_type', 'Response', 'Feedback', 'RT', ...
                      'Power_Fz', 'Power_FCz', 'Power_Cz'});

%% Table for NaN-removal comparison

NaNComparison = table('Size', [0 5], ...
    'VariableTypes', ["string", "string", "double", "double", "double"], ...
    'VariableNames', {'Subject', 'NaN_Mode', ...
                      'N_Total_Trials', 'N_General_Removed', 'N_Focused_Removed'});

%% Waitbar

numSubj = length(subject);
wb = waitbar(0, sprintf('0/%d subjects', numSubj), 'Name', 'Processing subjects');

for sj = 1:length(subject)

    if ishandle(wb)
        waitbar(sj / numSubj, wb, sprintf('%d/%d subjects', sj, numSubj));
        drawnow;
    end

    subjID = subject{sj};

    %% Load segmented misinformation data

    try
        load(fullfile(Path.segmented, ...
            [Params.experiment_name subject{sj} '_segmented_misinformation.mat']), ...
            'misinformation');
    catch ME
        fprintf('Could not load subject %s: %s\n', subjID, ME.message);
        missing_segmented_files{end+1} = subjID;
        continue
    end

    try
        %% Check whether requested channels exist

        missing_channels = setdiff(channels_of_interest, misinformation.label);

        if ~isempty(missing_channels)
            fprintf('Subject %s is missing channel(s): %s. Skipping subject.\n', ...
                subjID, strjoin(missing_channels, ', '));

            missing_channel_subjects{end+1, 1} = subjID;
            missing_channel_subjects{end, 2} = strjoin(missing_channels, ', ');

            continue
        end

        %% Detect trials with NaNs

        select_trial = true(length(misinformation.trial), 1);

        switch lower(nan_rejection_mode)

            case 'general'

                % Strict/general criterion:
                % reject a trial if there is any NaN anywhere

                for trl = 1:length(misinformation.trial)
                    if any(isnan(misinformation.trial{trl}(:)))
                        select_trial(trl) = false;
                    end
                end

            case 'focused'

                % Focused criterion:
                % reject only if NaNs are in required channels and required time windows

                chan_idx = find(ismember(misinformation.label, channels_of_interest));

                select_trial = true(length(misinformation.trial), 1);

                % Optional general criterion for logging/comparison
                strict_select_trial = true(length(misinformation.trial), 1);

                for trl = 1:length(misinformation.trial)

                    % General criterion, only for comparison/logging
                    if any(isnan(misinformation.trial{trl}(:)))
                        strict_select_trial(trl) = false;
                    end

                    t = misinformation.time{trl};

                    % Add +/- 0.5 buffer so that NaNs close to the relevant windows
                    % are also considered.
                    nan_time_buffer = 0.75;

                    baseline_idx = ...
                        t >= (Params.Misinformation.Baseline(1) - nan_time_buffer) & ...
                        t <= (Params.Misinformation.Baseline(2) + nan_time_buffer);

                    theta_idx = ...
                        t >= (theta_latency(1) - nan_time_buffer) & ...
                        t <= (theta_latency(2) + nan_time_buffer);

                    time_idx = baseline_idx | theta_idx;

                    % If this trial does not contain the required time samples, reject it
                    if ~any(baseline_idx) || ~any(theta_idx)
                        select_trial(trl) = false;
                        continue
                    end

                    % Check NaNs only in required channels and required time windows
                    trial_data_to_check = misinformation.trial{trl}(chan_idx, time_idx);

                    if any(isnan(trial_data_to_check(:)))
                        select_trial(trl) = false;
                    end
                end

            otherwise

                error('Unknown nan_rejection_mode: %s', nan_rejection_mode);
        end

        %% Save NaN-removal numbers

        N_Total_Trials = length(misinformation.trial);

        switch lower(nan_rejection_mode)

            case 'general'
                N_General_Removed = sum(~select_trial);
                N_Focused_Removed = NaN;

            case 'focused'
                N_General_Removed = sum(~strict_select_trial);
                N_Focused_Removed = sum(~select_trial);
        end

        Tnan = table(string(subjID), string(nan_rejection_mode), ...
            N_Total_Trials, N_General_Removed, N_Focused_Removed, ...
            'VariableNames', {'Subject', 'NaN_Mode', ...
                              'N_Total_Trials', 'N_General_Removed', 'N_Focused_Removed'});

        NaNComparison = [NaNComparison; Tnan];

        %% Skip subject if all trials are rejected

        if sum(select_trial) == 0
            fprintf('Subject %s has no valid trials after NaN removal. Skipping.\n', subjID);
            failed_subjects{end+1} = subjID;
            continue
        end

        %% Select only trials without NaNs

        cfg = [];
        cfg.trials = find(select_trial);
        misinformation = ft_selectdata(cfg, misinformation);

        %% Calculate time-frequency power

        cfg = [];
        cfg.method = 'wavelet';
        cfg.output = 'pow';
        cfg.width = morlet_width;
        cfg.gwidth = Params.Misinformation.gwidth;
        cfg.foi = Params.Misinformation.FOI;
        cfg.channel = channels_of_interest;
        cfg.toi = -1:0.02:2;
        cfg.keeptrials = 'yes';

        misinformation_tf = ft_freqanalysis(cfg, misinformation);

        %% Baseline correction

        cfg = [];
        cfg.baseline = Params.Misinformation.Baseline;
        cfg.baselinetype = 'db';

        misinformation_tf = ft_freqbaseline(cfg, misinformation_tf);

        %% Select post-stimulus theta window

        cfg = [];
        cfg.channel = channels_of_interest;

        % Do not average over channels
        cfg.avgoverchan = 'no';

        % Post-stimulus theta window
        cfg.latency = theta_latency;
        cfg.avgovertime = 'yes';

        % Theta frequency range
        cfg.frequency = [4 8];
        cfg.avgoverfreq = 'yes';

        % Do not average over trials
        cfg.avgoverrpt = 'no';

        misinformation_stim = ft_selectdata(cfg, misinformation_tf);

        %% Extract power values

        pow = squeeze(misinformation_stim.powspctrm);
        nTr = size(misinformation_stim.trialinfo, 1);

        % Make sure pow is trials x channels
        if size(pow, 1) ~= nTr && size(pow, 2) == nTr
            pow = pow';
        end

        idx_Fz  = find(strcmp(misinformation_stim.label, 'Fz'));
        idx_FCz = find(strcmp(misinformation_stim.label, 'FCz'));
        idx_Cz  = find(strcmp(misinformation_stim.label, 'Cz'));

        if isempty(idx_Fz) || isempty(idx_FCz) || isempty(idx_Cz)

            fprintf('One or more requested channels are missing after TF for subject %s. Skipping.\n', subjID);

            missing_channel_subjects{end+1, 1} = subjID;
            missing_channel_subjects{end, 2} = 'Missing after TF/selectdata';

            continue
        end

        Power_Fz  = pow(:, idx_Fz);
        Power_FCz = pow(:, idx_FCz);
        Power_Cz  = pow(:, idx_Cz);

        %% Get trial info

        Subject = repmat(string(subjID), nTr, 1);

        Trial_type = misinformation_stim.trialinfo(:, 1);
        Response   = misinformation_stim.trialinfo(:, 2);
        Feedback   = misinformation_stim.trialinfo(:, 3);
        RT         = misinformation_stim.trialinfo(:, 4);

        %% Create subject-level table

        Tsub = table(Subject, Trial_type, Response, Feedback, RT, ...
            Power_Fz, Power_FCz, Power_Cz);

        %% Append to full table

        AllTrials = [AllTrials; Tsub];

    catch ME_analysis

        fprintf('Analysis failed for subject %s: %s\n', subjID, ME_analysis.message);
        failed_subjects{end+1} = subjID;
        continue

    end
end

if ishandle(wb)
    close(wb);
end

%% Create output folder if needed

% Preferred output path:
% Path.TF_results_SingleSubject_3Channels

if ~isfield(Path, 'TF_results_SingleSubject_3Channels')

    if isfield(Path, 'TF_results')
        Path.TF_results_SingleSubject_3Channels = fullfile(Path.TF_results, 'SingleSubject_3Channels');

    elseif isfield(Path, 'results')
        Path.TF_results_SingleSubject_3Channels = fullfile(Path.results, 'SingleSubject_3Channels');

    else
        % Fallback: save relative to current folder
        Path.TF_results_SingleSubject_3Channels = fullfile(pwd, 'SingleSubject_3Channels');
    end
end

if ~exist(Path.TF_results_SingleSubject_3Channels, 'dir')
    mkdir(Path.TF_results_SingleSubject_3Channels)
end

%% Save CSV

outname = fullfile(Path.TF_results_SingleSubject_3Channels, ...
    sprintf('Items8040AllSubjects_misinformation_trials_3Channels5_8_%s_%s_%dMorlet_%sNaNs.csv',theta_codes{1}, theta_codes{2}, morlet_width, nan_rejection_mode));

writetable(AllTrials, outname);

%% Save NaN comparison

nan_comparison_outname = fullfile(Path.TF_results_SingleSubject_3Channels, ...
    sprintf('Items8040NaN_removal_comparison_3Channels5_8_%s_%s_%dMorlet%s.csv', theta_codes{1}, theta_codes{2}, morlet_width, nan_rejection_mode));

writetable(NaNComparison, nan_comparison_outname);

%% Save channel info as txt

channels_outname = fullfile(Path.TF_results_SingleSubject_3Channels, ...
    'channels.txt');

fid = fopen(channels_outname, 'w');
fprintf(fid, '%s\n', strjoin(channels_of_interest, '_'));
fclose(fid);

%% Save info about skipped subjects

info_outname = fullfile(Path.TF_results_SingleSubject_3Channels, ...
    sprintf('Items8040AllSubjects_misinformation_trials_3Channels_info5_8_%s_%s_%dMorlet%sNaNs.mat', theta_codes{1}, theta_codes{2}, morlet_width, nan_rejection_mode));

save(info_outname, ...
    'missing_segmented_files', ...
    'failed_subjects', ...
    'missing_channel_subjects', ...
    'subject', ...
    'channels_of_interest', ...
    'morlet_width');

fprintf('Saved trial-level table to:\n%s\n', outname);
fprintf('Saved NaN comparison to:\n%s\n', nan_comparison_outname);
fprintf('Saved channels file to:\n%s\n', channels_outname);

end
end