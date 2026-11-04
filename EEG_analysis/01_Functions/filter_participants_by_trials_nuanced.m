function [desiredIDs_atLeastOneCondition, desiredIDs_bothConditions, summary_table] = filter_participants_by_trials_nuanced(T, threshold)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Chinchella Nicola, MRG Group 2025
% Filters participants by minimum trial count 
%
% This function filters participants based on trial count threshold and 
% returns participant IDs suitable for input to select_subject_multiple()
%
% Input:
% T : table with columns: Subject_ID, Share_Fake, Share_True
% threshold: Numeric value for minimum trials in at least one condition
%
% Output:
% desiredIDs_atLeastOneCondition: Cell array of Subject_IDs meeting the
% criteria of at least the threshold trials in one conditions (share / no
% share) 
%
% desiredIDs_bothConditions = Cell array of Subject_IDs meeting the
% criteria of at least the threshold trials in both conditions (share / no
% share) 
%
% summary_table = Table with original data plus 'Both_conditions_XX' column 
%                where 1 = both conditions meet threshold
%                      0 = One condition meets threshold 
%                      NaN = no condition meets threshold 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
code='experiment';
analysis='misinformation_theta';

[Path]=NI_00_Setup_analysis(code,analysis);

% Prepare new column name for this threshold
col_name = sprintf('Both_conditions_%d', threshold);

% Calculate logical vectors for trial threshold
has_fake = T.Share_Fake >= threshold;
has_true = T.Share_True >= threshold;

% Initialize new column with NaN
new_col = NaN(height(T), 1);

either_conditions = has_fake | has_true;
both_conditions = has_fake & has_true;

% Assign 1 for both conditions met, 0 for only one, NaN for none
new_col(both_conditions) = 1;
new_col(either_conditions & ~both_conditions) = 0;

% Add or update this column in T
T.(col_name) = new_col;

% Always overwrite everyhing 
summary_table = T;

% Save it 
output_path = Path.ERP;
csv_filename = 'participants_filtered_by_trials.csv';
full_csv_path = fullfile(output_path, csv_filename);
writetable(summary_table, full_csv_path); % Overwrite!! 

desiredIDs_atLeastOneCondition = T.Subject_ID(either_conditions);
desiredIDs_bothConditions = T.Subject_ID(both_conditions);

end