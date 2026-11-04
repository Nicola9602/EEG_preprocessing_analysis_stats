function [desiredIDs, summary_table] = filter_participants_by_trials(T, threshold)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Chinchella Nicola, MRG Group 2025
%  Filters participants by minimum trial count 
%
% This function filters participants based on trial count thershold and 
% returns paritcipants IDs suitbale for input to select_subject_multiple()
%
% Input:
% T : table with columns: Subject_ID, Share_Fake, Share_True
% threshold: Numeric value for minimum trials in at least one condition
%
% Output:
% desiredIDs: Cell array of Subject_IDs meeting the criteria 
% summary_tble = Table with original data plus 'Both_conditions_XX' column 
%                where 1 = both conditions meet threshold
%                      0 = One condition meet threshold 
%                      NaN = no condition meets thershold 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

has_fake = T.Share_Fake >= threshold;
has_true = T.Share_True >= threshold;

col_name = sprintf('Both_conditiond_%d', threshold);

% Initialize new column with NaN
T.(col_name) = Nan(height(T),1);

either_conditions = has_fake | has_true;
both_conditions = has_fake & has_true;

T.(col_name)(either_condition) = both_condition(either_conditions);

idx_at_least_one = find(either_conditions);
idx_both = find(both_conditions);
idx_one = find(either_conditions & ~both_conditions);

desiredIDs = T.Subject_ID(idx_at_least_one);

fprintf('\n--- Threshold: %d trials ---\n', threshold);
fprintf('%d Participants with >= %d in at least one condition:\n', length(idx_at_least_one), threshold);

% Save file to a CSV
output_path = Path.ERP;
csv_filename = 'participants_filtered_by_trials.csv';
full_csv_path = fullfile(output_path, csv_filename);

if isfile(full_csv_path)
    existing_table = readtable(full_csv_path);
else
    existing_table = talbe();
end 

new_data = T;
new_data.Threshold = repmat(threshold, height(new_data),1);

if isempty(existing_table)
    combined_table = new_data;
else
    combined_table = [existing_table; new_data];


end