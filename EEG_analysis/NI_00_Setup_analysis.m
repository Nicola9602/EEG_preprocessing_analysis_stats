%{
Chinchella Nicola MRG Group 2026
SCRIPT DESCRIPTION
==================
This function initializes the paths and analysis parameters used by the
misinformation EEG analysis pipeline.

It is not an analysis script by itself. Its role is to return two structures:

    Path
    Params

These structures are then used by the other scripts to know where files are
stored, where outputs should be saved, and which trigger codes / frequency
parameters should be used.

INPUTS
------
The function requires two input arguments:

    code
        Defines whether the analysis is run on pilot data or experiment data.
        Expected values:
            'pilot'
            'experiment'

    analysis
        Defines which analysis-specific parameters should be loaded.
        Expected values:
            'stroop_theta'
            'misinformation_theta'

WHAT IT DEFINES
---------------
The function defines paths for:

    - FieldTrip
    - custom functions
    - tool/layout files
    - segmented EEG data
    - log files
    - raw EEG data
    - ERP outputs
    - time-frequency outputs
    - plots
    - CSV/statistical output folders

It also defines experiment-specific filenames, for example:

    Params.experiment_name = 'Misinformation_'
    Params.log_name        = 'Misinformation_log_'

For the misinformation theta analysis, it defines:

    - trigger codes for false and true news
    - response/share codes
    - feedback codes
    - theta frequency of interest
    - region of interest
    - full frequency range
    - wavelet width
    - baseline window
    - baseline correction type

OUTPUTS
-------
The function outputs:

    Path
        Structure containing all relevant folders.

    Params
        Structure containing task codes, analysis parameters, and filenames.
%}


function [Path,Params]=NI_00_Setup_analysis(code,analysis)


root = 'YOUR_PROJECT_PATH';

Path.spm12_path = 'YOUR_SPM12_PATH';
Path.fieldtrip ='YOUR_FIELDTRIP_PATH';
Path.functions=fullfile(pwd,'01_Functions');
Path.tools=fullfile(root,'01_Tools');
Path.figure=fullfile(root, '04_Analysis','02_Plots');


switch code
    case 'pilot'
        folder='Pilot';
    case 'experiment'
        folder='Experiment';
end

Path.segmented=fullfile(root,'02_Data','04_Segmented',folder);
Path.log=fullfile(root,'02_Data','01_Log_files',folder);

Path.raw_eeg=fullfile(root,'02_Data','02_Raw_data',folder);

Path.ERP = fullfile(root, '02_Data', '05_ERP', folder);
Path.TF = fullfile(root, '02_Data','06_TF', folder, 'Grandaverages_TF');
Path.TF_Bolo = fullfile(root, '02_Data','06_TF', folder, 'Bolo', 'Grandaverages_TF');
Path.TF_SingSubj = fullfile(root, '02_Data','06_TF', folder, 'SingleSubject_TF');
Path.Plots = fullfile(root, '04_Analysis', '02_Plots', 'TF_Figures', 'TF_clean_data_threshold');
Path.Plots_Bolo = fullfile(root, '04_Analysis', '02_Plots', 'Bolo', 'TF_Figures');
Path.Plots_all_subj = fullfile(root, '04_Analysis', '02_Plots', 'TF_Figures', 'TF_clean_all_subjects');
Path.Corr_Plots_TF = fullfile(root, '04_Analysis', '02_Plots', 'TF_Figures');
Path.TF_results =  fullfile(root, '04_Analysis', '03_Outputs', folder, 'TF_results');
Path.TF_results_SingleSubject_3Channels =  fullfile(root, 'EEG_statistics', 'WSingleSubj_FCz_Fz_Cz');
Path.TF_results_SingleSubject_2ChannelsAlpha =  fullfile(root, '04_Analysis', '03_Outputs', folder, 'TF_results', 'Alpha_AFz_Fz');
Path.TF_results_SingleSubject_6Channels =  fullfile(root, '04_Analysis', '03_Outputs', folder, 'TF_results', 'WSingleSubj_F1_FCz_Fz_Cz_FC1_C1');
Path.TF_results_SingleSubject_6ChannelsAlpha =  fullfile(root, '04_Analysis', '03_Outputs', folder, 'TF_results', 'Alpha_F1_FCz_Fz_Cz_FC1_C1');

Path.ClusterPerm = fullfile(root, '02_Data', '06_TF', folder, 'Bolo', 'Grandaverages_TF', 'ClusterPermutation_Misinformation');



addpath(Path.functions);
addpath(Path.tools);

switch code
    case 'pilot'
        Params.experiment_name='MisinformationPilot_';
        Params.log_name='MisinformationPilot_log_';
    case 'experiment'
        Params.experiment_name='Misinformation_';
        Params.log_name='Misinformation_log_';
        %error('You need to input experiment and log name first!')
end

Params.elecfile=fullfile(Path.tools,'Misinformation_electrodes.ced');
Params.layout=fullfile(Path.tools,'Misinformation_layout_elec_neighbours.mat');

switch analysis
    case 'stroop_theta'
%Codes for trial

Params.Stroop.Congruent=10;
Params.Stroop.Incongruent=20;
Params.Stroop.Correct=10;
Params.Stroop.Incorrect=20;
Params.Stroop.Timeout=30;

Params.Stroop.FOI=[4 7];
Params.Stroop.ROI={'FCz'};
Params.Stroop.Freq=2:1:20;
Params.Stroop.width=5;
Params.Stroop.Baseline=[-1 -0.5];
Params.Stroop.Contrast='db';

    case 'misinformation_theta'

Params.Misinformation.FalseLeft=100;
Params.Misinformation.FalseRight=200;
Params.Misinformation.TrueRight=300;
Params.Misinformation.TrueLeft=400;
Params.Misinformation.Share = [100 200, 300, 400, 500, 600, 700];
Params.Misinformation.FalseFeedback = 1;
Params.Misinformation.TrueFeedback = 2;

Params.Misinformation.FOI=5:0.5:8;
Params.Misinformation.ROI={'FCz', 'Fz', 'Cz'};
Params.Misinformation.Freq=2:0.25:20;
Params.Misinformation.width=4;
Params.Misinformation.gwidth = 3;
Params.Misinformation.Baseline=[-0.800 -0.400];
Params.Misinformation.BaselineLate=[3 3.5];
Params.Misinformation.Contrast='db';


end

% PLOT Settings

% Shared setup for the three NI_03 plotting scripts.
% Keep this file in the same folder as the plotting scripts.
% Edit thresholdm and the filenames below to match the saved data.

code = 'experiment';
analysis = 'misinformation_theta';
thresholdm = 1;
Morlet = 4;

[Path, Params] = NI_00_Setup_analysis(code, analysis);
try
    ft_defaults;
catch
    addpath(Path.fieldtrip);
    ft_defaults;
end

% Count participants for THIS threshold (not the last threshold in a loop).
T = readtable(fullfile(Path.ERP, 'trial_counts_summary.xlsx'));
[~, desiredIDs_bothConditions] = filter_participants_by_trials_nuanced(T, thresholdm);
N = numel(desiredIDs_bothConditions);
fprintf('Threshold %d | N both conditions = %d\n', thresholdm, N);

% These are the special filenames used in the original script for threshold 1.
% For other thresholds, use the regular filenames shown below.
if thresholdm == 1
    filename_true = '8040misinformation_share_true_5_8threshold1_width4_Morlet_db_baselineine';
    filename_fake = '8040misinformation_share_fake_5_8threshold1_width4_Morlet_db_baselineine';
else
    filename_true = sprintf('misinformation_share_true_threshold%d_width%d_Morlet', thresholdm, Morlet);
    filename_fake = sprintf('misinformation_share_fake_threshold%d_width%d_Morlet', thresholdm, Morlet);
end

load(fullfile(Path.TF_Bolo, filename_true), 'misinformation_share_true');
load(fullfile(Path.TF_Bolo, filename_fake), 'misinformation_share_fake');

cfg = [];
cfg.layout = fullfile(Path.tools, 'Misinformation_layout_elec_neighbours.mat');
layout = ft_prepare_layout(cfg);

diffTF = misinformation_share_true;
diffTF.powspctrm = misinformation_share_fake.powspctrm - misinformation_share_true.powspctrm;

% N is a label only; check that these MAT files use the same participant set.
