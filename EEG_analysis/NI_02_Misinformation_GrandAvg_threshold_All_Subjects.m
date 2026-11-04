% Chinchella Nicola 2026 MRG Group
%{
SCRIPT DESCRIPTION
==================
This script computes conflict-related theta activity for the misinformation
task, focusing on shared misinformation trials.The script computes subject-level time-frequency data internally, but the
saved .mat files and plots are group-level grand averages.

Quickly: 

Grand-average time-frequency power, baseline-corrected in dB, for shared true 
and shared fake trials, across all EEG channels, from 2–20 Hz,
 from -0.5 to 1.5 seconds, separately for each trial-count threshold.

Condition: shared True vs shared Fake
Channels: all channels, not only ROI
Frequency: 2–20 Hz, not only theta
Time window saved: -0.5 to 1.5 s
Baseline: -1 to -0.5 s
Power unit: dB relative to baseline
Level: group grand average
Thresholds: 15, 20, 25, 30, 35 trials

---------------------------------------------------------------------------

The main comparison is:

    shared fake news
    versus
    shared true news

The analysis is repeated for different minimum trial-count thresholds:

    15, 20, 25, 30, 35 trials

For each threshold, the script selects participants who have enough trials,
loads their segmented EEG data, removes bad trials containing NaNs, keeps
only Share trials, separates True and Fake trials, computes time-frequency
power, applies baseline correction, and then computes grand-average
time-frequency representations across subjects.

INPUT DATA
----------
The script loads:

    1. The FieldTrip layout file:
        Params.layout

    2. The trial-count summary file:
        trial_counts_summary.xlsx

    3. One segmented EEG file per participant:
        Misinformation_<subject>_segmented_misinformation.mat

The segmented EEG file must contain the FieldTrip data structure:

        misinformation

TRIAL SELECTION
---------------
First, the script removes trials containing NaNs.
Then it selects only trials where the participant chose a Share response:

        Params.Misinformation.Share

Within Share trials, it separates:

    True shared trials:
        TrueRight
        TrueLeft

    Fake shared trials:
        FalseLeft
        FalseRight

Participants are skipped if they do not have both True and Fake trials after
filtering.

OUTPUT FILES SAVED
------------------
For each threshold, the script saves two .mat files:

    misinformation_share_true_threshold%d67.mat
    misinformation_share_fake_threshold%d67.mat

Note:
The "67" in the filename is currently hard-coded in the script.

PLOTS SAVED
-----------
For each threshold, the script saves several .jpg plots:

    FCz_activity_misinformation_threshold%d67.jpg
        Custom contour plot showing True, Fake, and Fake-minus-True activity
        at FCz.

    Multiplot_threshold%d67.jpg
        Multi-channel FieldTrip time-frequency plot of the Fake-minus-True
        difference.

    Single_plot_TRUE_FCz_threshold%d67.jpg
        Time-frequency plot at FCz for shared true news.

    Single_plot_FAKE_FCz_threshold%d67.jpg
        Time-frequency plot at FCz for shared fake news.

    Single_plot_DIFF_Fake_minus_True_FCz_threshold%d67.jpg
        Time-frequency plot at FCz for Fake-minus-True.

    Topoplot_True_threshold%d67.jpg
        Scalp topography for the True condition.

    Topoplot_FAKE_threshold%d67.jpg
        Scalp topography for the Fake condition.

    Topoplot_DIFF_fake_minus_true_threshold%d67.jpg
        Scalp topography for the Fake-minus-True difference.

ANALYSIS LEVEL
--------------
The script computes subject-level time-frequency data internally, but the
saved .mat files and plots are group-level grand averages.
%}

clear
code='experiment';
analysis='misinformation_theta';

[Path,Params]=NI_00_Setup_analysis(code,analysis);


load(Params.layout)
%Initialize fieldtrip (you can comment these lines if you already called
%fieldtrip at least once in your matlab session)

restoredefaultpath

addpath(Path.fieldtrip)
ft_defaults

addpath(Path.functions)
addpath(Path.tools)


%{
try
    ft_defaults;
   
catch
    addpath(Path.fieldtrip);
    ft_defaults;
end
%}

% Use costum function to filter participants for the threshold of number of
% trials we want 

T = readtable(fullfile(Path.ERP, "trial_counts_summary.xlsx"));

% Set a threshold for the number of trials we want to include 
threshold = 1;
%threshold = [20 25 30 35 40];
width_values = [4];
skipped = {};  

for w_idx = 1:length(width_values)
    current_width = width_values(w_idx);

for t = 1:length(threshold)

    [desiredIDs_atLeastOneCondition, desiredIDs_bothConditions, summary_table] = filter_participants_by_trials_nuanced(T, threshold(t));
    
    N = length( desiredIDs_bothConditions);

    subject = select_subject_multiple(Path.raw_eeg,  desiredIDs_bothConditions);
% subject=select_subject(Path.raw_eeg,'multiple');

    % Add a waitbar 
    numSubj = length(subject);
    Misinformation_share_true = cell(1, numSubj);
    Misinformation_share_fake = cell(1, numSubj);
    skipped = {};


    wb = waitbar(0, ...
    sprintf('Threshold %d | Width %d: 0/%d subjects', threshold(t), current_width, numSubj), ...
    'Name', 'Processing subjects');

    
    %for sj=1:length(subject)
       %load(fullfile(Path.segmented,[Params.experiment_name subject{sj} '_segmented_misinformation.mat']),'misinformation');
    
    for sj=1:length(subject)
       load(fullfile(Path.segmented,[Params.experiment_name subject{sj} '_segmented_misinformation.mat']),'misinformation'); % for ITI baseline


%Detect trials with nan
select_trial=true(length(misinformation.trial),1);
for trl=1:length(misinformation.trial)
       if any(isnan(misinformation.trial{trl}(:)))
           select_trial(trl)=false;
       end
end

%Now select only trials without NaNs and with share only

cfg=[];
cfg.trials=find(select_trial & (ismember(misinformation.trialinfo(:,2), Params.Misinformation.Share)));
misinformation_share=ft_selectdata(cfg,misinformation);

% If no Share trials remain, skip subject
if isempty(misinformation_share.trial)
    skipped{end+1} = subject{sj};
    warning('Subject %s: no Share trials after filtering. Skipping.', subject{sj});
    continue
end

% Calculate pad given the trials 
trl_lengths = cellfun(@(x) size(x,2), misinformation_share.trial);  
fs = misinformation_share.fsample;
required_pad = max(trl_lengths) / fs;

% --- Find trials for each condition (within Share-only data)
true_idx = find(ismember(misinformation_share.trialinfo(:,1), ...
    [Params.Misinformation.TrueRight, Params.Misinformation.TrueLeft]));
fake_idx = find(ismember(misinformation_share.trialinfo(:,1), ...
    [Params.Misinformation.FalseLeft, Params.Misinformation.FalseRight]));

% If either condition is missing, skip this subject BEFORE ft_freqanalysis
if isempty(true_idx) || isempty(fake_idx)
    skipped{end+1} = subject{sj};
    warning('Subject %s: missing trials (True=%d, Fake=%d). Skipping.', ...
        subject{sj}, numel(true_idx), numel(fake_idx));
    continue
end



% Calculate power 
cfg=[];
cfg.method='wavelet';
cfg.output='pow';
cfg.width=current_width;
cfg.gwidth = Params.Misinformation.gwidth;
cfg.foi=Params.Misinformation.Freq;
cfg.toi=-1:0.02:2; 
%cfg.toi = -1:0.02:4; % For baseline in the ITI
cfg.pad=required_pad + 0.1;
%cfg.pad = 20;
cfg.trials = find(ismember(misinformation_share.trialinfo(:,1), [Params.Misinformation.TrueRight, Params.Misinformation.TrueLeft]));
misinformation_share_true = ft_freqanalysis(cfg, misinformation_share);
cfg.trials = find(ismember(misinformation_share.trialinfo(:,1), [Params.Misinformation.FalseLeft, Params.Misinformation.FalseRight]));
misinformation_share_fake = ft_freqanalysis(cfg, misinformation_share);

%{
% Manual Baseline calculation
%Create a baseline time window for each condition and average it over time
cfg=[];
cfg.latency=Params.Misinformation.Baseline;
cfg.avgovertime='yes';
bsC=ft_selectdata(cfg,misinformation_share_true);
bsI=ft_selectdata(cfg,misinformation_share_fake);

% Convert raw power into decibels (dB) relative to baseline 
misinformation_share_true.powspctrm=10*log10(misinformation_share_true.powspctrm./repmat(bsC.powspctrm,1,1,length(misinformation_share_true.time)));
misinformation_share_fake.powspctrm=10*log10(misinformation_share_fake.powspctrm./repmat(bsI.powspctrm,1,1,length(misinformation_share_fake.time)));
%}


% Baseline  Fieldtrip 
cfg = [];
cfg.baseline     = Params.Misinformation.Baseline;   
cfg.baselinetype = 'db';             
misinformation_share_true   = ft_freqbaseline(cfg, misinformation_share_true);
misinformation_share_fake = ft_freqbaseline(cfg, misinformation_share_fake);


% Select an analysis window
cfg=[];
cfg.latency=[-0.8 1.5];
Misinformation_share_true{1,sj}=ft_selectdata(cfg,misinformation_share_true);
Misinformation_share_fake{1,sj}=ft_selectdata(cfg,misinformation_share_fake);



    % update waitbar and force GUI refresh
    if ishandle(wb)
        waitbar(sj/numSubj, wb, ...
    sprintf('Threshold %d | Width %d: %d/%d', threshold(t), current_width, sj, numSubj));
        drawnow;
    end

end
close(wb);

% Skipping participants created empty entries. Let's fix that 
% --- Drop empty entries (skipped subjects) before grandaverage
isEmptyTrue = cellfun(@isempty, Misinformation_share_true);
isEmptyFake = cellfun(@isempty, Misinformation_share_fake);

% keep only indices where BOTH are present
keepIdx = ~(isEmptyTrue | isEmptyFake);

Misinformation_share_true = Misinformation_share_true(keepIdx);
Misinformation_share_fake = Misinformation_share_fake(keepIdx);

% Safety check
if isempty(Misinformation_share_true) || isempty(Misinformation_share_fake)
    warning('No valid subjects for threshold %d and width %d. Skipping.', ...
        threshold(t), current_width);
    continue
end

%{
% =========================================================
% KEEP SUBJECT-LEVEL CONDITION AVERAGES
% Resulting dimord should be:
% subj_chan_freq_time
% =========================================================

cfg_ind = [];
cfg_ind.parameter = 'powspctrm';
cfg_ind.keepindividual = 'yes';

misinformation_share_true_subjects = ...
    ft_freqgrandaverage(cfg_ind, Misinformation_share_true{:});

misinformation_share_fake_subjects = ...
    ft_freqgrandaverage(cfg_ind, Misinformation_share_fake{:});
%}

% =========================================================
% ORDINARY GROUP GRAND AVERAGES FOR PLOTTING
% =========================================================

cfg=[];
misinformation_share_true=ft_freqgrandaverage(cfg,Misinformation_share_true{:});
misinformation_share_fake=ft_freqgrandaverage(cfg,Misinformation_share_fake{:});

save(fullfile(Path.TF_Bolo, sprintf('8040misinformation_share_true_5_8threshold%d_width%d_Morlet_db_baselineine.mat', threshold(t), current_width)), "misinformation_share_true", '-v7.3');
save(fullfile(Path.TF_Bolo, sprintf('8040misinformation_share_fake_5_8threshold%d_width%d_Morlet_db_baselineine.mat', threshold(t), current_width)), "misinformation_share_fake", '-v7.3');

end
end
