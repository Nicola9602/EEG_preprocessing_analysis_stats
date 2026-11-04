% Mireia Torralba MRG Group 2024
% Use this script to segment the data: extract from the continous recording
% the segments of data of interest aligned to events of interest

%Initialize paths and parameters that you will use
code='experiment';


[Path,Params,Triggers]=MI_00_Setup(code);

%Initialize fieldtrip (you can comment these lines if you already called
%fieldtrip at least once in your matlab session)
try
    ft_defaults;
    
catch
    addpath(Path.fieldtrip);
    ft_defaults;
end


%Right now, only Stroop segmentation is coded, we have to decide the epochs
%of the missinformation task
%Select the subjects to segment

subject=select_subject(Path.raw_eeg,'multiple');

for sj=1:length(subject)
    try 
        load(fullfile(Path.log,[Params.log_name subject{sj} '.mat']),'Part_info');

% === FIX HARDCODED PATHS ===
    % Extract just the filenames from the old paths
    [~, marker_name, marker_ext] = fileparts(Part_info.marker_file);
    [~, header_name, header_ext] = fileparts(Part_info.header_file);
    
    % Reconstruct paths using current Path.raw_eeg
    Part_info.marker_file = fullfile(Path.raw_eeg, subject{sj}, [marker_name marker_ext]);
    Part_info.header_file = fullfile(Path.raw_eeg, subject{sj}, [header_name header_ext]);
    
    % Verify the files exist
    if ~exist(Part_info.marker_file, 'file')
        error('Marker file not found: %s', Part_info.marker_file);
    end
    if ~exist(Part_info.header_file, 'file')
        error('Header file not found: %s', Part_info.header_file);
    end
    % === END PATH FIX ===
    

load(fullfile(Path.preprocessed,[Params.experiment_name subject{sj} '_preprocessed.mat']),'data');


%Obtain stroop trials
cfg=[];
cfg.marker=Part_info.marker_file;
cfg.header=Part_info.header_file;
cfg.trialfun='ft_trialfun_stroop';
cfg.Fixation=trigger_label_BV(Triggers.Stroop.fixationCode);
cfg.Stim_onset=trigger_label_BV([Triggers.Stroop.congruentCode Triggers.Stroop.incongruentCode]);
cfg.Response=trigger_label_BV([Triggers.Stroop.correctRespCode Triggers.Stroop.incorrectRespCode Triggers.Stroop.timeOutRespCode]);
cfg.Add_time=2.5; %This is to avoid NaN when calculating TF;
cfg=ft_definetrial(cfg);

%Prepare data to store in the excel, this happens after misinformation
%segmentation 
n_stroop_trials = size(cfg.trl, 1);
n_congruent_correct = sum(cfg.trl(:, 4) == 10 & cfg.trl(:, 5) == 10);
n_incongruent_correct = sum(cfg.trl(:, 4) == 20 & cfg.trl(:, 5) == 10);
n_congruent_incorrect = sum(cfg.trl(:, 4) == 10 & cfg.trl(:, 5) == 20);
n_incongruent_incorrect = sum(cfg.trl(:, 4) == 20 & cfg.trl(:, 5) == 20);
n_missed_response = sum(cfg.trl(:, 5) == 30);

stroop=ft_redefinetrial(cfg,data);
stroop=rmfield(stroop,'cfg');

%STROOP: The trial structure is aligned to the onset of the word (T=0 is the onset
%of the word)
%Trial info contains the following information:
%Colon 1: Trial type 10 Congruent 20 Incongruent
%Colon 2: Response 10 Correct 20 Incorrect 30 Timeout
%Colon 3: Response time (seconds)
%Colon 4: Fixation to Stim onset (seconds)
save(fullfile(Path.segmented,[Params.experiment_name subject{sj} '_segmented_stroop.mat']),'stroop');

%Obtain rating trials (to do)


cfg = [];
cfg.marker = Part_info.marker_file;
cfg.header = Part_info.header_file;
cfg.trialfun = 'ft_trialfun_rating';
cfg.subject_id = subject{sj}; % This is just for the warning in the ft_trialfun_rating so that we know which subject raises it
cfg.Fixation = trigger_label_BV(Triggers.Rating.fixationCodeM);
cfg.Stim_onset = trigger_label_BV([Triggers.Rating.falseLeft Triggers.Rating.falseRight Triggers.Rating.trueRight Triggers.Rating.trueLeft]);
cfg.Response = trigger_label_BV([Triggers.Rating.RespCode1 Triggers.Rating.NoRespCode]);
cfg.Feedback = trigger_label_BV([Triggers.Rating.FalseFeedback Triggers.Rating.TrueFeedback]);
% New: markers that can close a trial after feedback 
cfg.BlockEnd = trigger_label_BV(Triggers.Rating.blockEndCodeM);
cfg.TaskEnd  = trigger_label_BV(Triggers.Rating.taskEndCodeM);
cfg.Add_time = 2.5;
cfg = ft_definetrial(cfg);

% Get the amount of buffer overflow I calculated in the other function 
buffer_overflow_count = cfg.trl(1, end);
% Remove the buffer overflow column from trl before using it
cfg.trl = cfg.trl(:, 1:end-1);

% save the number of trials that are valid after segmentation
n_trials = size(cfg.trl, 1); % Gets the size of the first column of the generated table

% find how many TL/TR/FL/FR are there 
n_falseLeft = sum(cfg.trl(:, 4) == 100);
n_falseRight = sum(cfg.trl(:, 4) == 200);
n_trueRight = sum(cfg.trl(:, 4) == 300);
n_trueLeft = sum(cfg.trl(:, 4) == 400);

% find how many share vs no_share 
n_share = sum(cfg.trl(:, 5) > 100);
n_no_share = sum(cfg.trl(:, 5) == 100);

misinformation = ft_redefinetrial(cfg, data);
misinformation = rmfield(misinformation, 'cfg');

save(fullfile(Path.segmented,[Params.experiment_name subject{sj} '_segmented_misinformation.mat']),'misinformation');



% Read the excel file where to store the amount of trials 
excel_file = fullfile(Path.segmented, 'Count_segmented_trials.xlsx');
if isfile(excel_file)
    T = readtable(excel_file);
    
    % Check if subject already exists
    subject_idx = find(strcmp(T.Subject, subject{sj}));
    
    if ~isempty(subject_idx)
        % Overwrite existing subject
        T(subject_idx, :) = {subject{sj}, n_trials, n_falseLeft, n_falseRight, n_trueRight, ...
            n_trueLeft, n_share, n_no_share, buffer_overflow_count, ...
            n_stroop_trials, n_congruent_correct, n_incongruent_correct, ...
            n_congruent_incorrect, n_incongruent_incorrect, n_missed_response};
    else
        % Append new subject
        T = [T; {subject{sj}, n_trials, n_falseLeft, n_falseRight, n_trueRight, ...
            n_trueLeft, n_share, n_no_share, buffer_overflow_count, ...
            n_stroop_trials, n_congruent_correct, n_incongruent_correct, ...
            n_congruent_incorrect, n_incongruent_incorrect, n_missed_response}];
    end
else
     T = table({subject{sj}}, n_trials, n_falseLeft, n_falseRight, n_trueRight, ...
         n_trueLeft, n_share, n_no_share, buffer_overflow_count, ...
         n_stroop_trials, n_congruent_correct, n_incongruent_correct, ...
         n_congruent_incorrect, n_incongruent_incorrect, n_missed_response, ...
        'VariableNames', {'Subject', 'N_Valid_Trials', 'N_FalseLeft', ...
        'N_FalseRight', 'N_TrueRight', 'N_TrueLeft', 'N_Share', 'N_No_Share', ...
        'Buffer_Overflows', 'N_Stroop', 'Stroop_Cong_Corr', 'Stroop_Incong_Corr', ...
        'Stroop_Cong_Incorr', 'Stroop_Incong_Incorr', 'Stroop_Missed'});
end
writetable(T, excel_file);

catch ME
    warning('Could not process subject %s: %s', subject{sj}, ME.message);
    % Prepare NaN row for all outcome variables, adjust the number of NaNs accordingly
    nan_row = [{subject{sj}}, num2cell(nan(1, 14))];
    excel_file = fullfile(Path.segmented, 'Count_segmented_trials.xlsx');
    if isfile(excel_file)
        T = readtable(excel_file);
        subject_idx = find(strcmp(T.Subject, subject{sj}));
        nan_tbl = cell2table(nan_row, 'VariableNames', T.Properties.VariableNames);
        if ~isempty(subject_idx)
            T(subject_idx, :) = nan_tbl;
        else
            T = [T; nan_tbl];
        end
    else
        T = cell2table(nan_row, 'VariableNames', {'Subject', 'N_Valid_Trials', 'N_FalseLeft', ...
            'N_FalseRight', 'N_TrueRight', 'N_TrueLeft', 'N_Share', 'N_No_Share', ...
            'Buffer_Overflows', 'N_Stroop', 'Stroop_Cong_Corr', 'Stroop_Incong_Corr', ...
            'Stroop_Cong_Incorr', 'Stroop_Incong_Incorr', 'Stroop_Missed'});
    end
    writetable(T, excel_file);
    continue
end


%MISINFORMAITON: The trial structure is aligned to the
% onset of the feedback (T=0 is the onset
%of the feedback)
%Trial info contains the following information:
%Column 1: Trial type, 100 FalseLeft, 200 FalseRight, 300 TrueRight, 400 TrueLeft
%Column 2: Response 100 = 1, 200 = 2, 300 = 3 etc till 700, No resp = NaN
%Column 3: Feedback 1 = False, 2 = True
%Column 5: Response time (seconds)
%Column 4: Fixation to Stim onset (seconds)

end
