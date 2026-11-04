%Mireia Torralba Cuello MRG Group 2024
%This script contains the parameters for performing the preprocessing and
%analysis of the misinformation task
function [Path,Params,Triggers]=MI_00_Setup(code)

%These are the paths you have to set up


% Main local root folder
root = 'YOUR_PROJECT_PATH';


Path.fieldtrip = 'YOUR_FIELDTRIP_PATH';
Path.eeglab = 'YOUR_EEGLAB_PATH';


%%%

% Functions and tools
Path.functions = fullfile(pwd, '01_Functions');
Path.tools = fullfile(root, '01_Tools');
Path.figure = fullfile(root, '03_Preprocessing', '03_Plots');
Path.figure_analysis = fullfile(root, '04_Analysis', '02_Plots');

switch code
    case 'pilot'
        folder='Pilot';
    case 'experiment'
        folder='Experiment';
end

Path.log = fullfile(root, '02_Data', '01_Log_files', folder);
Path.raw_eeg = fullfile(root, '02_Data', '02_Raw_data', folder);
Path.preprocessed = fullfile(root, '02_Data', '03_Preprocessed', folder);
Path.segmented = fullfile(root, '02_Data', '04_Segmented', folder);
Path.ERP = fullfile(root, '02_Data', '05_ERP', folder);

% Group-level / grand-average TF outputs
Path.TF = fullfile(root, '02_Data', '06_TF', folder, 'Grandaverages_TF');

% Single-subject TF outputs
Path.TF_SingSubj = fullfile(root, '02_Data', '06_TF', folder, 'SingleSubject_TF');

Path.Plots = fullfile(root, '04_Analysis', '02_Plots', 'TF_Figures');
Path.Plots_all_subj = fullfile(root, '04_Analysis', '02_Plots', 'TF_Figures', 'TF_clean_all_subjects');
Path.Corr_Plots_TF = fullfile(root, '04_Analysis', '02_Plots', 'TF_Figures');
Path.TF_results = fullfile(root, '04_Analysis', '03_Outputs', folder, 'TF_results');
Path.TF_results_SingleSubject_3Channels = fullfile(root, '04_Analysis', '03_Outputs', folder, 'TF_results', 'SingleSubject_3Channels');

Path.interim = fullfile(root, '03_Preprocessing', '02_Temporary_files', folder);
Path.interim_local = Path.interim;

Path.interim_troubleshooting = fullfile(root, '03_Preprocessing', '02_Temporary_files_troubleshooting');
Path.log_troubleshooting = fullfile(root, '02_Data', '01_Log_files_troubleshooting');
Path.figure_troubleshooting = fullfile(root, '03_Preprocessing', '03_Plots_troubleshooting');
Path.preprocessed_troubleshooting = fullfile(root, '02_Data', '03_Preprocessed_troubleshooting');


addpath(Path.functions);
addpath(Path.tools);

switch code
    case 'pilot'
Params.experiment_name='MisinformationPilot_';
Params.log_name='MisinformationPilot_log_';
    case 'experiment'
        %Define here the names of the files for the experiment
        %error('You need to input experiment and log name first!')
        Params.experiment_name='Misinformation_';
Params.log_name='Misinformation_log_';

end


Params.eeg='.eeg';
Params.header='.vhdr';
Params.events='.vmrk';
Params.elecfile=fullfile(Path.tools,'Misinformation_electrodes.ced');
Params.layout=fullfile(Path.tools,'Misinformation_layout_elec_neighbours.mat');

%Thresholds for discarding artifacts
Params.ICA.Brain=[nan nan];
Params.ICA.Muscle=[nan nan];
Params.ICA.Eye=[0.9 1];
Params.ICA.Heart=[nan nan];
Params.ICA.Line_Noise=[nan nan];
Params.ICA.Channel_Noise=[nan nan];
Params.ICA.Other=[nan nan];

Params.ICA_filt_freq=1; %In Hz
Params.ICA_filt_order=1650;


Params.FlatEEG=100; %In seconds (how many seconds we accept without data)
Params.Corr=0.8;    %Correlation with neighboring channels
Params.LineNoise=4; %In STD

Params.x0=100;
Params.y0=100;
Params.Size=600;
Params.Label_size=40;

Params.Reject_threshold=300; %Microvolts, the maximum value for EEG accepted into ICA preprocessing
Params.Artf_timespan=2; %In miliseconds, how much data we are including in the rejection.
Params.External={'HEOG' 'VEOG' 'M2'}; %External electrodes

Triggers.Stroop.taskStartCode = 90;
Triggers.Stroop.blockStartCode = [91 92];
Triggers.Stroop.congruentCode = 8;
Triggers.Stroop.incongruentCode = 9;
Triggers.Stroop.correctRespCode = 40;
Triggers.Stroop.incorrectRespCode = 50;
Triggers.Stroop.timeOutRespCode = 60;
Triggers.Stroop.fixationCode = 97;
Triggers.Stroop.breakCode = 70;
Triggers.Stroop.blockEndCode = 98;
Triggers.Stroop.taskEndCode = 99;
Triggers.Stroop.Response_stroop=200; %May not need it
% MISINFORMATION CODES:

% Codes for triggers
% 80 = task start (Misinformation)
% 81 = block 1, 82 = block 2, 83 = block 3 (of the Misinformation task)
% 87 = fixation
% 10 = false right, 11 = true right, 20 = false left, 21 = true left
% (images)
% 1 = response key 1, 2 = response key 2, 3 = response key 3, 4 = response
% key 4, 5 = response key 5, 6 = response key 6, 7 = response key 7
% (responses)
% 100 = false, 101 = true (feedback)
% 88 = block end
% 89 = task end
% 70 = break

Triggers.Rating.taskStartCodeM = 80;
Triggers.Rating.blockStartCodeM = [81 82 83];
Triggers.Rating.fixationCodeM = 87;
Triggers.Rating.falseLeft = 11;
Triggers.Rating.falseRight = 12;
Triggers.Rating.trueRight = 13;
Triggers.Rating.trueLeft = 14;
Triggers.Rating.RespCode1 = 1:7;
Triggers.Rating.NoRespCode = 199;
Triggers.Rating.FalseFeedback = 100;
Triggers.Rating.TrueFeedback = 101;
Triggers.Rating.breakCode = 70;
Triggers.Rating.blockEndCodeM = 88;
Triggers.Rating.taskEndCodeM = 89;

end
