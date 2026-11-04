function Names=select_subject(raw_path,sel_mode)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mireia Torralba Cuello, MRG Group 2024
% Use this function to select the subject for the analysis
%
% Input: 
% raw_path:  string with the full path to the folder where subject
%            data is recorded. The code assumes the data is organized in 
%            folders for the different subjects.
% sel_mode:  string, can be 'single' (only one subject can be selected each
%            time) or 'multiple' (it is possible to select multiple subjects
%            for the analysis).
%
%
% Output: 
% Names:  cell containing the ID of the subjects selected for the
%         analysis.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
contents=struct2table(dir(raw_path));
Names=contents.name(~strcmp(contents.name,'.') & ~strcmp(contents.name,'..') & contents.isdir);

selected=listdlg('ListString',Names,'PromptString','Select subject','SelectionMode',sel_mode);

Names=Names(selected);
end