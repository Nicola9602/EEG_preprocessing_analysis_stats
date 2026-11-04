function Names=select_subject_multiple(raw_path,desiredIDs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Chinchella Nicola, MRG Group 2025
% Use this function to select multiple subjects for the analysis
%
% Input: 
% raw_path:  string with the full path to the folder where subject
%            data is recorded. The code assumes the data is organized in 
%            folders for the different subjects.
% desiredIDs: can be a numeric array, string array, or cellstr 
%             is the list of subjects to select for the analysis.
%
%
% Output: 
% Names:  cell containing the IDs of the subjects selected for the
%         analysis.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
contents=struct2table(dir(raw_path)); 

% Remove special directory entries such as '.' and '..'
% Contents.isdir is a logical array markign entries that are directories 
NamesAll = contents.name(~strcmp(contents.name, '.') & ~strcmp(contents.name, '..') & contents.isdir);

% Normalize desiredIDs to cell str

if isnumeric(desiredIDs)
    desiredStr = cellstr(num2str(desiredIDs(:)));
elseif isstring(desiredIDs)
    desiredStr = ceelstr(desiredIDs(:));
elseif iscell(desiredIDs)
    desiredStr = cellstr(desiredIDs(:));
else
    error('desiredIDs must be numeric, string array, or cell array of char.');
end

% Find the names that are both in the list provided and in the pool of
% participants

Names = intersect(NamesAll, desiredStr, 'stable');

% Report if missing 

missing = setdiff(desiredStr, Names, 'stable');
if ~isempty(missing)
    warning('These requested IDs were not found: %s', strjoin(missing, ', '));

end
end