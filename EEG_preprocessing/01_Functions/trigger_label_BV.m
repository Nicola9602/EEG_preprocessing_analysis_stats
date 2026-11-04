function trig_label=trigger_label_BV(trig_num)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Mireia Torralba, MRG group 2017
%
% Use this file to convert numerical values to BrainVision labels
% Inputs
% trig_num: integer, trigger number
%
% Outputs
% trig_label: string, trigger marker as it is written by BrainVision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k=1:length(trig_num)
if trig_num(k)<10
    trig_label{1,k}=['S  ' num2str(trig_num(k))];
else 
    if trig_num(k)<100
        trig_label{1,k}=['S ' num2str(trig_num(k))];
    else
        trig_label{1,k}=['S' num2str(trig_num(k))];
    end
end

end